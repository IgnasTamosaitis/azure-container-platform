# Pin the base image to a digest for reproducible builds (Dependabot keeps it current):
#   docker buildx imagetools inspect python:3.12-slim --format '{{json .Manifest.Digest}}'
# then change the line below to: FROM python:3.12-slim@sha256:<digest>
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

COPY requirements.txt .

# requirements.txt is a hash-locked file: pip refuses any package whose hash does not match
RUN pip install --no-cache-dir --require-hashes -r requirements.txt

COPY app ./app

RUN useradd --system --create-home --uid 10001 appuser

USER 10001

EXPOSE 8080

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8080"]
