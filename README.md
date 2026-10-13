
# Azure Container Platform

A hands-on Cloud/DevOps portfolio project focused on containerizing a Python API and deploying it to Microsoft Azure using Infrastructure as Code and CI/CD.

## Current Implementation

- FastAPI application with `/` and `/health` endpoints
- Automated API tests using pytest
- Docker containerization with Python 3.12
- Non-root container execution
- Local HTTP health checks

## Technology Stack

- Python / FastAPI / Uvicorn
- Docker
- Git
- pytest

## Run Locally

Create and activate a Python virtual environment:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements-dev.txt
```

Run the API:

```bash
uvicorn app.main:app --host 127.0.0.1 --port 8080
```

Run tests:

```bash
python -m pytest -v
```

## Run with Docker

Build the image:

```bash
docker build -t azure-container-api:0.2 .
```

Run the container:

```bash
docker run -d --rm \
  --name azure-container-api \
  -p 127.0.0.1:8081:8080 \
  azure-container-api:0.2
```

Verify the API:

```bash
curl http://127.0.0.1:8081/health
```

Expected response:

```json
{"status":"healthy"}
```

Stop the container:

```bash
docker stop azure-container-api
```

## Planned Improvements

- GitHub Actions CI/CD pipeline
- GitHub Container Registry integration
- Azure Container Apps deployment
- Terraform infrastructure provisioning
- Monitoring and security improvements
