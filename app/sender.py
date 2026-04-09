"""
IoT Hub sender for streaming telemetry from simulated devices.

Uses the IoT Hub REST API (with managed identity) to register devices,
then the IoT device SDK to send D2C messages.
"""

import json
import logging
import requests
from azure.iot.device import IoTHubDeviceClient, Message
from azure.identity import DefaultAzureCredential

logger = logging.getLogger(__name__)

IOT_HUB_API_VERSION = "2021-04-12"


class IoTHubDeviceSender:
    """Manages device registrations and sends telemetry as individual devices."""

    def __init__(self, iot_hub_hostname: str):
        self._hostname = iot_hub_hostname
        self._credential = None
        self._device_clients: dict[str, IoTHubDeviceClient] = {}

    def connect(self):
        """Authenticate to IoT Hub service API using managed identity."""
        logger.info("Connecting to IoT Hub: %s", self._hostname)
        self._credential = DefaultAzureCredential()
        logger.info("Connected to IoT Hub service API via managed identity")

    def _get_auth_header(self) -> dict:
        """Get Bearer token for IoT Hub REST API."""
        token = self._credential.get_token("https://iothubs.azure.net/.default")
        return {"Authorization": f"Bearer {token.token}"}

    def register_device(self, device_id: str) -> str:
        """Register a device in IoT Hub via REST API. Returns device connection string."""
        url = (
            f"https://{self._hostname}/devices/{device_id}"
            f"?api-version={IOT_HUB_API_VERSION}"
        )
        headers = {**self._get_auth_header(), "Content-Type": "application/json"}

        # Try to get existing device first
        resp = requests.get(url, headers=headers)
        if resp.status_code == 404:
            # Create the device with symmetric key auth
            body = {
                "deviceId": device_id,
                "status": "enabled",
                "authentication": {
                    "type": "sas",
                    "symmetricKey": {"primaryKey": None, "secondaryKey": None},
                },
            }
            resp = requests.put(url, headers=headers, json=body)
            resp.raise_for_status()
            logger.info("Registered device: %s", device_id)
        else:
            resp.raise_for_status()
            logger.debug("Device %s already registered", device_id)

        device = resp.json()
        primary_key = device["authentication"]["symmetricKey"]["primaryKey"]
        conn_str = (
            f"HostName={self._hostname};"
            f"DeviceId={device_id};"
            f"SharedAccessKey={primary_key}"
        )
        return conn_str

    def connect_device(self, device_id: str, connection_string: str):
        """Create a device client connection."""
        client = IoTHubDeviceClient.create_from_connection_string(connection_string)
        client.connect()
        self._device_clients[device_id] = client
        logger.debug("Device %s connected", device_id)

    def send_message(self, device_id: str, event: dict) -> bool:
        """Send a single telemetry message from a device."""
        client = self._device_clients.get(device_id)
        if not client:
            logger.warning("No client for device %s", device_id)
            return False

        msg = Message(json.dumps(event))
        msg.content_type = "application/json"
        msg.content_encoding = "utf-8"
        client.send_message(msg)
        return True

    def close(self):
        """Disconnect all device clients."""
        for device_id, client in self._device_clients.items():
            try:
                client.disconnect()
            except Exception:
                logger.debug("Error disconnecting device %s", device_id)
        self._device_clients.clear()
        logger.info("All device connections closed")
