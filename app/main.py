"""
Photo Proofing Portal - FastAPI Application
"""
from fastapi import FastAPI
from fastapi.responses import JSONResponse

app = FastAPI(
    title="Photo Proofing Portal",
    description="A photo proofing and approval system",
    version="1.0.0",
)


@app.get("/")
async def root():
    """Root endpoint"""
    return {"message": "Photo Proofing Portal API", "status": "running"}


@app.get("/health")
async def health_check():
    """Health check endpoint for Docker healthcheck"""
    return JSONResponse(
        content={"status": "healthy", "service": "photo-proofing-portal"},
        status_code=200
    )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)