import os
from dotenv import load_dotenv

load_dotenv()


class Config:
    IOT_HUB_HOSTNAME: str = os.getenv("IOT_HUB_HOSTNAME", "")
    DEVICE_COUNT: int = int(os.getenv("DEVICE_COUNT", "10"))
    SEND_INTERVAL_SECONDS: float = float(os.getenv("SEND_INTERVAL_SECONDS", "5"))
    ANOMALY_PROBABILITY: float = float(os.getenv("ANOMALY_PROBABILITY", "0.05"))
    LOG_LEVEL: str = os.getenv("LOG_LEVEL", "INFO")
