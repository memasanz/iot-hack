FROM python:3.12-slim

LABEL maintainer="Demo"
LABEL description="IoT Telemetry Simulator for Fabric Eventhouse"

WORKDIR /opt/mbi-iot

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app/ ./app/

ENV PYTHONUNBUFFERED=1

EXPOSE 8000

ENTRYPOINT ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
