from fastapi import FastAPI

app = FastAPI(title="Azure Container Platform API")


@app.get("/")
def home():
	return {"message": "Hello from Azure Container Platform v2"}


@app.get("/health")
def health():
	return {"status": "healthy"}
