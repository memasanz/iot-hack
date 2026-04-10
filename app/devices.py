"""
Device simulators for IoT field equipment.

Each device generates realistic telemetry with configurable anomaly injection.
Devices are assigned US-based GPS coordinates — some are static (fixed sites)
and some are mobile (vehicles / drones that drift each tick).
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


# US-based GPS coordinates for static industrial sites
STATIC_LOCATIONS = [
    {"name": "Houston Refinery",       "lat": 29.7604,  "lon": -95.3698},
    {"name": "Chicago Plant",          "lat": 41.8781,  "lon": -87.6298},
    {"name": "Detroit Assembly",       "lat": 42.3314,  "lon": -83.0458},
    {"name": "Pittsburgh Steel Works", "lat": 40.4406,  "lon": -79.9959},
    {"name": "Seattle Tech Campus",    "lat": 47.6062,  "lon": -122.3321},
    {"name": "Denver Mining Ops",      "lat": 39.7392,  "lon": -104.9903},
    {"name": "Phoenix Electronics",    "lat": 33.4484,  "lon": -112.0740},
    {"name": "Atlanta Logistics Hub",  "lat": 33.7490,  "lon": -84.3880},
    {"name": "Dallas Data Center",     "lat": 32.7767,  "lon": -96.7970},
    {"name": "Portland Warehouse",     "lat": 45.5152,  "lon": -122.6784},
    {"name": "Miami Port Facility",    "lat": 25.7617,  "lon": -80.1918},
    {"name": "Boston Lab Complex",     "lat": 42.3601,  "lon": -71.0589},
]

# Starting points for mobile devices (US highway corridors)
MOBILE_ORIGINS = [
    {"name": "I-10 West Corridor",  "lat": 30.2672, "lon": -97.7431},   # Austin, TX
    {"name": "I-95 North Route",    "lat": 39.2904, "lon": -76.6122},   # Baltimore, MD
    {"name": "I-80 East Corridor",  "lat": 40.7608, "lon": -111.8910},  # Salt Lake City, UT
    {"name": "I-5 South Route",     "lat": 45.5152, "lon": -122.6784},  # Portland, OR
    {"name": "I-70 Midwest Route",  "lat": 38.6270, "lon": -90.1994},   # St. Louis, MO
    {"name": "I-75 South Route",    "lat": 39.1031, "lon": -84.5120},   # Cincinnati, OH
]


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
    latitude: float = 0.0
    longitude: float = 0.0
    mobile: bool = False
    status: DeviceStatus = DeviceStatus.ONLINE
    _baseline: float = field(default=0.0, repr=False)
    _drift_offset: float = field(default=0.0, repr=False)
    _tick: int = field(default=0, repr=False)
    _failure_countdown: int = field(default=0, repr=False)
    _heading: float = field(default=0.0, repr=False)

    def __post_init__(self):
        profile = DEVICE_PROFILES[self.device_type]
        self._baseline = random.uniform(profile["normal_min"], profile["normal_max"])
        if self.mobile:
            self._heading = random.uniform(0, 2 * math.pi)

    def _update_position(self):
        """Drift mobile devices along a heading with slight random turns."""
        if not self.mobile:
            return
        # ~0.001° per tick ≈ 100m movement per reading
        speed = random.uniform(0.0005, 0.002)
        # Gradual heading changes
        self._heading += random.gauss(0, 0.15)
        self.latitude += math.cos(self._heading) * speed
        self.longitude += math.sin(self._heading) * speed
        # Keep within continental US bounds
        self.latitude = max(24.5, min(49.0, self.latitude))
        self.longitude = max(-125.0, min(-66.9, self.longitude))

    def generate_reading(self, anomaly_probability: float) -> dict[str, Any]:
        """Generate a single telemetry reading, possibly with an anomaly."""
        self._tick += 1
        self._update_position()
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
            "latitude": round(self.latitude, 6),
            "longitude": round(self.longitude, 6),
            "firmware_version": self.firmware_version,
            "status": self.status.value,
            "value": value,
            "unit": profile["unit"],
            "anomaly": anomaly_type,
        }


def create_device_fleet(device_count: int, company_prefix: str = "MBI") -> list[Device]:
    """Create a fleet of devices distributed across types and locations.

    ~70% of devices are assigned to static US industrial sites,
    ~30% are mobile and drift along US highway corridors.
    """
    device_types = list(DeviceType)
    devices: list[Device] = []

    for i in range(device_count):
        dtype = device_types[i % len(device_types)]
        profile = DEVICE_PROFILES[dtype]
        location = profile["locations"][i % len(profile["locations"])]
        firmware = f"{random.randint(1, 4)}.{random.randint(0, 9)}.{random.randint(0, 99)}"

        is_mobile = (i % 10) >= 7  # 70/30 split
        if is_mobile:
            origin = MOBILE_ORIGINS[i % len(MOBILE_ORIGINS)]
            lat = origin["lat"] + random.uniform(-0.05, 0.05)
            lon = origin["lon"] + random.uniform(-0.05, 0.05)
            location = origin["name"]
        else:
            site = STATIC_LOCATIONS[i % len(STATIC_LOCATIONS)]
            lat = site["lat"] + random.uniform(-0.01, 0.01)
            lon = site["lon"] + random.uniform(-0.01, 0.01)
            location = site["name"]

        devices.append(Device(
            device_id=f"{company_prefix}-{dtype.value[:4].upper()}-{i:04d}",
            device_type=dtype,
            location=location,
            firmware_version=firmware,
            latitude=lat,
            longitude=lon,
            mobile=is_mobile,
        ))

    return devices
