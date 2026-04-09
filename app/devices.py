"""
Device simulators for IoT field equipment.

Each device generates realistic telemetry with configurable anomaly injection.
"""

import math
import random
import uuid
from dataclasses import dataclass, field
from datetime import datetime, timezone
from enum import Enum
from typing import Any


class DeviceType(Enum):
    TEMPERATURE = "temperature_sensor"
    PRESSURE = "pressure_sensor"
    VIBRATION = "vibration_sensor"
    HUMIDITY = "humidity_sensor"


class DeviceStatus(Enum):
    ONLINE = "online"
    DEGRADED = "degraded"
    OFFLINE = "offline"


# Realistic ranges and units for each sensor type
DEVICE_PROFILES = {
    DeviceType.TEMPERATURE: {
        "unit": "°C",
        "normal_min": 18.0,
        "normal_max": 85.0,
        "anomaly_spike_range": (95.0, 150.0),
        "drift_rate": 0.3,
        "precision": 2,
        "locations": ["Furnace A", "Assembly Line 1", "Cooling Tower", "Warehouse B",
                       "Paint Booth", "Compressor Room", "Server Room", "Loading Dock"],
    },
    DeviceType.PRESSURE: {
        "unit": "PSI",
        "normal_min": 30.0,
        "normal_max": 120.0,
        "anomaly_spike_range": (130.0, 200.0),
        "drift_rate": 0.5,
        "precision": 1,
        "locations": ["Hydraulic Press 1", "Boiler Room", "Steam Line A", "Pneumatic Line 3",
                       "Coolant Loop", "Gas Supply", "Clean Room", "Test Chamber"],
    },
    DeviceType.VIBRATION: {
        "unit": "mm/s",
        "normal_min": 0.5,
        "normal_max": 10.0,
        "anomaly_spike_range": (15.0, 45.0),
        "drift_rate": 0.2,
        "precision": 3,
        "locations": ["Motor A", "Pump Station 2", "Conveyor Belt 1", "Turbine Hall",
                       "Compressor C", "Fan Unit 5", "Drill Press", "Centrifuge Lab"],
    },
    DeviceType.HUMIDITY: {
        "unit": "%RH",
        "normal_min": 30.0,
        "normal_max": 70.0,
        "anomaly_spike_range": (80.0, 99.0),
        "drift_rate": 0.4,
        "precision": 1,
        "locations": ["Clean Room A", "Storage Vault", "Paper Mill Floor", "Electronics Lab",
                       "Paint Booth", "Greenhouse Wing", "Archive Room", "QC Chamber"],
    },
}


@dataclass
class Device:
    device_id: str
    device_type: DeviceType
    location: str
    firmware_version: str
    status: DeviceStatus = DeviceStatus.ONLINE
    _baseline: float = field(default=0.0, repr=False)
    _drift_offset: float = field(default=0.0, repr=False)
    _tick: int = field(default=0, repr=False)
    _failure_countdown: int = field(default=0, repr=False)

    def __post_init__(self):
        profile = DEVICE_PROFILES[self.device_type]
        self._baseline = random.uniform(profile["normal_min"], profile["normal_max"])

    def generate_reading(self, anomaly_probability: float) -> dict[str, Any]:
        """Generate a single telemetry reading, possibly with an anomaly."""
        self._tick += 1
        profile = DEVICE_PROFILES[self.device_type]
        anomaly_type = None

        # Handle ongoing sensor failure
        if self._failure_countdown > 0:
            self._failure_countdown -= 1
            if self._failure_countdown == 0:
                self.status = DeviceStatus.ONLINE
            return self._build_event(
                value=None,
                anomaly_type="sensor_failure",
                profile=profile,
            )

        # Check for anomaly
        roll = random.random()
        if roll < anomaly_probability:
            anomaly_type = random.choice(["spike", "drift", "sensor_failure"])

        if anomaly_type == "sensor_failure":
            self.status = DeviceStatus.OFFLINE
            self._failure_countdown = random.randint(2, 6)
            return self._build_event(value=None, anomaly_type="sensor_failure", profile=profile)

        if anomaly_type == "drift":
            self.status = DeviceStatus.DEGRADED
            self._drift_offset += random.uniform(-profile["drift_rate"], profile["drift_rate"] * 3)

        # Normal reading with natural variation + optional drift
        noise = random.gauss(0, (profile["normal_max"] - profile["normal_min"]) * 0.02)
        # Add a slow sine wave to simulate cyclic behavior (e.g., day/night)
        cycle = math.sin(self._tick * 0.05) * (profile["normal_max"] - profile["normal_min"]) * 0.05
        value = self._baseline + noise + cycle + self._drift_offset
        value = round(max(0, value), profile["precision"])

        if anomaly_type == "spike":
            spike_min, spike_max = profile["anomaly_spike_range"]
            value = round(random.uniform(spike_min, spike_max), profile["precision"])
            self.status = DeviceStatus.DEGRADED

        # Gradually recover from degraded to online
        if self.status == DeviceStatus.DEGRADED and anomaly_type is None:
            if random.random() > 0.7:
                self.status = DeviceStatus.ONLINE
                self._drift_offset *= 0.5  # partially reset drift

        return self._build_event(value=value, anomaly_type=anomaly_type, profile=profile)

    def _build_event(self, value: float | None, anomaly_type: str | None,
                     profile: dict) -> dict[str, Any]:
        return {
            "event_id": str(uuid.uuid4()),
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "company": self.device_id.split("-")[0],
            "device_id": self.device_id,
            "device_type": self.device_type.value,
            "location": self.location,
            "firmware_version": self.firmware_version,
            "status": self.status.value,
            "value": value,
            "unit": profile["unit"],
            "anomaly": anomaly_type,
        }


def create_device_fleet(device_count: int, company_prefix: str = "MBI") -> list[Device]:
    """Create a fleet of devices distributed across types and locations."""
    device_types = list(DeviceType)
    devices: list[Device] = []

    for i in range(device_count):
        dtype = device_types[i % len(device_types)]
        profile = DEVICE_PROFILES[dtype]
        location = profile["locations"][i % len(profile["locations"])]
        firmware = f"{random.randint(1, 4)}.{random.randint(0, 9)}.{random.randint(0, 99)}"

        devices.append(Device(
            device_id=f"{company_prefix}-{dtype.value[:4].upper()}-{i:04d}",
            device_type=dtype,
            location=location,
            firmware_version=firmware,
        ))

    return devices
