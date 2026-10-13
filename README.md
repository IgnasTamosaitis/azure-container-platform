# Azure Container Platform

A hands-on Cloud Engineering and DevOps portfolio project demonstrating containerized application deployment to Microsoft Azure using Terraform, Docker, GitHub Actions, and secure workload identity federation.

**Project status:** Implemented and successfully tested end-to-end.

## Architecture

```text
Developer
    |
    | Git push / Pull Request
    v
GitHub Repository
    |
    v
GitHub Actions
    |
    +-- CI: Python tests + Docker build
    |
    +-- Publish: Docker image -> GHCR
    |
    +-- Deploy: GitHub OIDC -> Microsoft Entra ID
                                  |
                                  v
                         Azure Container Apps
                                  |
                                  v
                           FastAPI HTTPS API

Terraform
    |
    +-- Azure Resource Group
    +-- Container Apps Environment (Consumption)
    +-- Container App configuration
    |
    +-- Remote state: Azure Blob Storage
```

## Implemented Features

- FastAPI REST application with `/` and `/health` endpoints
- Automated API tests using pytest
- Docker containerization with Python 3.12
- Non-root container execution (UID 10001)
- GitHub Actions CI/CD pipeline
- Automated Docker image publishing to GitHub Container Registry (GHCR)
- Automated deployment to Azure Container Apps
- Passwordless Azure authentication using GitHub OIDC and Microsoft Entra ID
- Terraform Infrastructure as Code using AzureRM
- Remote Terraform state in Azure Blob Storage
- State locking, Blob versioning, and soft-delete protection
- Commit SHA-based Docker image tagging
- HTTPS ingress and autoscaling configuration

## Technology Stack

| Area | Technologies |
|---|---|
| Cloud | Microsoft Azure, Azure Container Apps |
| Infrastructure as Code | Terraform, AzureRM |
| Containers | Docker, GHCR |
| CI/CD | GitHub Actions |
| Identity & Security | Microsoft Entra ID, OIDC, Azure RBAC |
| Application | Python, FastAPI, Uvicorn |
| Testing | pytest |
| Development | Git, Linux, Ubuntu WSL2 |

## Running Locally

Create a Python virtual environment and install dependencies:

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements-dev.txt
```

Run the application:

```bash
uvicorn app.main:app --host 127.0.0.1 --port 8080
```

Run tests:

```bash
python -m pytest -v
```

Available endpoints:

- `/` – application response
- `/health` – application health check
- `/docs` – interactive Swagger API documentation

## Running with Docker

Build the image:

```bash
docker build -t azure-container-api:local .
```

Start a container:

```bash
docker run -d --rm \
  --name azure-container-api \
  -p 127.0.0.1:8081:8080 \
  azure-container-api:local
```

Check the API:

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

Docker commands may require `sudo` depending on local Docker Engine permissions.

## Infrastructure with Terraform

Infrastructure configuration is located in the `terraform/` directory.

The project provisions:

- Azure Resource Group
- Azure Container Apps Environment using the Consumption workload profile
- Azure Container App running the published GHCR image

Application configuration:

- Region: North Europe
- CPU: 0.25 vCPU
- Memory: 0.5 GiB
- Minimum replicas: 0
- Maximum replicas: 1
- HTTPS ingress enabled

Terraform state is stored in a separately provisioned Azure Blob Storage backend, authenticated using Microsoft Entra ID.

The remote backend and required Azure RBAC permissions must be configured before initializing Terraform.

After authenticating through Azure CLI:

```bash
export ARM_SUBSCRIPTION_ID="$(az account show --query id -o tsv | tr -d '\r\n')"

cd terraform
terraform init
terraform fmt -check
terraform validate
terraform plan
```

Apply infrastructure changes only after reviewing the plan:

```bash
terraform apply
```

## CI/CD Pipeline

The GitHub Actions workflow is defined in `.github/workflows/ci.yml`.

**CI – Push and Pull Requests**

1. Check out the source code.
2. Configure Python 3.12.
3. Install dependencies.
4. Execute automated tests.
5. Build the Docker image.

**Container Publishing – Main Branch**

1. Authenticate to GHCR using `GITHUB_TOKEN`.
2. Build and publish the Docker image.
3. Tag the image using both `latest` and the Git commit SHA.

**Continuous Deployment – Main Branch**

1. Authenticate to Azure through GitHub OIDC.
2. Deploy the commit-specific Docker image to Azure Container Apps.
3. Verify the configured image.
4. Check the application's `/health` endpoint.

Publishing and deployment depend on successful completion of the preceding stages.

Terraform manages infrastructure configuration, while GitHub Actions manages the deployed application image. The Terraform lifecycle configuration prevents image updates from creating unnecessary drift.

## Security Considerations

- Application containers run as a non-root user.
- GitHub Actions uses short-lived OIDC authentication instead of stored Azure Client Secrets.
- Azure deployment permissions are restricted to the application Resource Group.
- Terraform state access uses Microsoft Entra ID and Azure RBAC.
- Azure Blob Storage public access and Shared Key access are disabled.
- Terraform state is protected through Blob versioning and soft-delete retention.
- HTTPS is enabled for the publicly accessible API.
- Local environment files and Terraform state files are excluded from version control.

## Verification

The CI/CD implementation was tested by changing the FastAPI application response, committing the change, and pushing it to GitHub.

GitHub Actions successfully tested, published, and deployed the new version.

The public Azure endpoint returned:

```json
{"message":"Hello from Azure Container Platform v2"}
```

A subsequent `terraform plan` reported no infrastructure changes.

## Cost and Cleanup

The Container App uses Consumption billing with scale-to-zero enabled. This reduces idle compute consumption but does not guarantee zero Azure costs.

To remove the Terraform-managed application infrastructure:

```bash
cd terraform
terraform plan -destroy
terraform destroy
```

**Important:** Destroying the application infrastructure disables the live endpoint. The separately provisioned Terraform state Storage Account is not removed by this command and must be managed separately.

Automated deployment should be disabled before removing the target Azure resources.

## Future Improvements

- Application Insights and Azure monitoring
- Automated security and dependency scanning
- Infrastructure validation in pull requests
- Deployment approvals and environment protection
- Automated rollback and more extensive integration testing
