"""
IoT Telemetry Simulator

FastAPI application that manages a simulated fleet of industrial field devices
and streams telemetry to Azure IoT Hub using the IoT device SDK.
"""

import logging
import signal
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.responses import JSONResponse

from app.config import Config
from app.simulator import SimulationEngine

config = Config()

logging.basicConfig(
    level=getattr(logging, config.LOG_LEVEL.upper(), logging.INFO),
    format="%(asctime)s | %(levelname)-7s | %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger(__name__)

engine = SimulationEngine(config)


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("=" * 60)
    logger.info("  IoT Telemetry Simulator")
    logger.info("=" * 60)
    logger.info("  Devices       : %d", config.DEVICE_COUNT)
    logger.info("  Interval      : %.1fs", config.SEND_INTERVAL_SECONDS)
    logger.info("  Anomaly prob  : %.1f%%", config.ANOMALY_PROBABILITY * 100)
    logger.info("  Dry run       : %s", not config.IOT_HUB_HOSTNAME)
    logger.info("=" * 60)

    # Auto-start the simulation on startup
    engine.start()
    yield

    # Shutdown
    engine.stop()
    logger.info("Application shutdown complete")


app = FastAPI(
    title="IoT Telemetry Simulator",
    description="Generates and streams synthetic IoT telemetry via Azure IoT Hub",
    version="1.0.0",
    lifespan=lifespan,
)


@app.get("/health")
async def health():
    """Health check endpoint."""
    return {"status": "healthy", "simulation_running": engine.is_running}


@app.get("/status")
async def status():
    """Detailed simulation status including device counts, cycle stats, and anomalies."""
    return engine.get_status()


@app.post("/start")
async def start_simulation():
    """Start the telemetry simulation."""
    started = engine.start()
    if started:
        return {"message": "Simulation started", **engine.get_status()}
    return JSONResponse(
        status_code=409,
        content={"message": "Simulation is already running", **engine.get_status()},
    )


@app.post("/stop")
async def stop_simulation():
    """Stop the telemetry simulation."""
    stopped = engine.stop()
    if stopped:
        return {"message": "Simulation stopped", **engine.get_status()}
    return JSONResponse(
        status_code=409,
        content={"message": "Simulation is not running", **engine.get_status()},
    )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000)

