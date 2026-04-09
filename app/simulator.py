"""
Simulation engine — runs the telemetry loop in a background thread
with thread-safe start/stop control.
"""

import logging
import threading
import time
from dataclasses import dataclass, field
from datetime import datetime, timezone

from app.config import Config
from app.devices import Device, create_device_fleet
from app.sender import IoTHubDeviceSender

logger = logging.getLogger(__name__)


@dataclass
class SimulationStats:
    started_at: str | None = None
    stopped_at: str | None = None
    cycle_count: int = 0
    events_sent: int = 0
    anomaly_count: int = 0


class SimulationEngine:
    def __init__(self, config: Config):
        self.config = config
        self.devices: list[Device] = []
        self.sender: IoTHubDeviceSender | None = None
        self.dry_run: bool = not config.IOT_HUB_HOSTNAME
        self.stats = SimulationStats()

        self._running = False
        self._thread: threading.Thread | None = None
        self._stop_event = threading.Event()
        self._lock = threading.Lock()

    @property
    def is_running(self) -> bool:
        return self._running

    def start(self) -> bool:
        """Start the simulation. Returns False if already running."""
        with self._lock:
            if self._running:
                return False

            self.devices = create_device_fleet(self.config.DEVICE_COUNT)
            logger.info("Created %d simulated devices", len(self.devices))

            if self.dry_run:
                logger.warning("DRY RUN mode — no IOT_HUB_HOSTNAME set")
            else:
                self.sender = IoTHubDeviceSender(
                    iot_hub_hostname=self.config.IOT_HUB_HOSTNAME,
                )
                self.sender.connect()

                # Register and connect each simulated device
                for device in self.devices:
                    conn_str = self.sender.register_device(device.device_id)
                    self.sender.connect_device(device.device_id, conn_str)
                logger.info("All %d devices registered and connected", len(self.devices))

            self.stats = SimulationStats(
                started_at=datetime.now(timezone.utc).isoformat()
            )
            self._stop_event.clear()
            self._running = True

            self._thread = threading.Thread(target=self._run_loop, daemon=True)
            self._thread.start()
            logger.info("Simulation started")
            return True

    def stop(self) -> bool:
        """Stop the simulation. Returns False if not running."""
        with self._lock:
            if not self._running:
                return False
            self._stop_event.set()

        if self._thread:
            self._thread.join(timeout=15)

        with self._lock:
            self._running = False
            self.stats.stopped_at = datetime.now(timezone.utc).isoformat()
            if self.sender:
                self.sender.close()
                self.sender = None

        logger.info("Simulation stopped after %d cycles", self.stats.cycle_count)
        return True

    def get_status(self) -> dict:
        device_statuses = {}
        for d in self.devices:
            status = d.status.value
            device_statuses[status] = device_statuses.get(status, 0) + 1

        return {
            "running": self._running,
            "dry_run": self.dry_run,
            "device_count": len(self.devices),
            "device_statuses": device_statuses,
            "send_interval_seconds": self.config.SEND_INTERVAL_SECONDS,
            "anomaly_probability": self.config.ANOMALY_PROBABILITY,
            "stats": {
                "started_at": self.stats.started_at,
                "stopped_at": self.stats.stopped_at,
                "cycle_count": self.stats.cycle_count,
                "events_sent": self.stats.events_sent,
                "anomaly_count": self.stats.anomaly_count,
            },
        }

    def _run_loop(self):
        while not self._stop_event.is_set():
            self.stats.cycle_count += 1
            events = []
            for device in self.devices:
                reading = device.generate_reading(self.config.ANOMALY_PROBABILITY)
                events.append(reading)

            anomalies = [e for e in events if e["anomaly"]]
            self.stats.anomaly_count += len(anomalies)

            if self.dry_run:
                for e in events:
                    logger.info("DRY RUN | %s | %s | %s=%s %s | anomaly=%s",
                                e["device_id"], e["location"],
                                e["device_type"], e["value"], e["unit"],
                                e["anomaly"])
                self.stats.events_sent += len(events)
            else:
                sent = 0
                for e in events:
                    try:
                        if self.sender.send_message(e["device_id"], e):
                            sent += 1
                    except Exception:
                        logger.exception("Error sending message for %s in cycle %d",
                                         e["device_id"], self.stats.cycle_count)
                self.stats.events_sent += sent
                logger.info("Cycle %d: sent %d events", self.stats.cycle_count, sent)

            for a in anomalies:
                logger.warning("⚠ ANOMALY [%s] on %s @ %s: value=%s %s",
                               a["anomaly"], a["device_id"], a["location"],
                               a["value"], a["unit"])

            self._stop_event.wait(timeout=self.config.SEND_INTERVAL_SECONDS)
