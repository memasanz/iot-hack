# Fabric Hackathon Guide

This guide walks you through connecting **Microsoft Fabric** to the IoT Hub deployed by the [IoT Simulator Setup](IOT_SIMULATOR_SETUP.md) and building real-time analytics on the streaming telemetry data.

## Prerequisites

- IoT Simulator deployed and sending data (see [IoT Simulator Setup](IOT_SIMULATOR_SETUP.md))
- A [Microsoft Fabric](https://www.microsoft.com/microsoft-fabric) workspace with at least **Contributor** access
- IoT Hub connection string (from the `iothubowner` shared access policy)

## Step 1 — Add IoT Hub as a Source in Fabric Real-Time Hub

Follow the official guide to connect your IoT Hub to Fabric:

📖 [Add Azure IoT Hub as source in Real-Time Hub](https://learn.microsoft.com/en-us/fabric/real-time-hub/add-source-azure-iot-hub)

Key values you'll need:

| Setting | Value |
|---|---|
| **IoT Hub name** | `<prefix>-iothub` |
| **Shared access policy** | `iothubowner` |
| **Consumer group** | `team1` (or `team2`, etc.) |

> **Tip:** Each team should use a different consumer group so they can read independently without affecting each other.

## Step 2 — Explore the Data

*TODO: Add instructions for creating an Eventhouse, KQL queries, dashboards, etc.*

## References

- [Microsoft Fabric documentation](https://learn.microsoft.com/en-us/fabric/)
- [Real-Time Hub documentation](https://learn.microsoft.com/en-us/fabric/real-time-hub/)
- [Azure IoT Hub documentation](https://learn.microsoft.com/en-us/azure/iot-hub/)
