# IoT & Fabric Hackathon

A hackathon starter kit that deploys an **IoT telemetry simulator** to Azure and connects it to **Microsoft Fabric** for real-time analytics.

The simulator generates synthetic industrial sensor data (temperature, pressure, vibration, humidity) and streams it to **Azure IoT Hub**. Participants then build real-time dashboards and analytics pipelines in Fabric.

## Architecture

```
┌─────────────────────┐     IoT Hub Device SDK       ┌──────────────────┐
│  Container App      │ ──────────────────────────►   │  Azure IoT Hub   │
│  (IoT Simulator)    │   D2C messages per device     │                  │
│                     │                               │  Built-in EH     │
│  • Temperature      │                               │  endpoint        │
│  • Pressure         │                               └────────┬─────────┘
│  • Vibration        │                                        │
│  • Humidity         │                          Consumer groups (team1, team2, ...)
│                     │                                        │
│  Managed Identity   │                               ┌────────▼─────────┐
│  • Register devices │                               │  Microsoft       │
│  • IoT Hub Data     │                               │  Fabric          │
│    Contributor      │                               └──────────────────┘
└─────────────────────┘
        ▲  Image pull
┌───────┴─────────────┐
│  Azure Container    │
│  Registry (ACR)     │
└─────────────────────┘
```

## Guides

| Guide | Description |
|---|---|
| **[IoT Simulator Setup](docs/IOT_SIMULATOR_SETUP.md)** | Deploy the IoT telemetry simulator to Azure — infrastructure, configuration, and monitoring |
| **[Fabric Hackathon](docs/FABRIC_HACKATHON.md)** | Connect Fabric to the IoT Hub and build real-time analytics on the streaming data |

## Quick Start

### 1. Deploy the simulator

See the full [IoT Simulator Setup](docs/IOT_SIMULATOR_SETUP.md) guide for details.

```powershell
# Step 1 — Deploy resources (requires Contributor)
.\infra\deploy.ps1 -ResourceGroup "mbi-iot-rg" -Location "eastus" -Prefix "mmxiot"

# Step 2 — Assign roles (requires Owner or User Access Administrator)
.\infra\deploy-roles.ps1 -ResourceGroup "mbi-iot-rg" -Prefix "mmxiot"
```

### 2. Connect Fabric

See the [Fabric Hackathon](docs/FABRIC_HACKATHON.md) guide for step-by-step instructions.

## References

- [Azure IoT Hub documentation](https://learn.microsoft.com/en-us/azure/iot-hub/)
- [Microsoft Fabric documentation](https://learn.microsoft.com/en-us/fabric/)
- [Add Azure IoT Hub as source in Fabric Real-Time Hub](https://learn.microsoft.com/en-us/fabric/real-time-hub/add-source-azure-iot-hub)
- [Azure IoT Explorer](https://github.com/Azure/azure-iot-explorer)
