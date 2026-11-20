from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.database import init_db
from app.routes.auto_scan import router as auto_scan_router
from app.routes.prepared_transactions import router as prepared_router
import os
from dotenv import load_dotenv

load_dotenv()

app = FastAPI(
    title="SmartLedger Auto-Scan Backend",
    description="Automated background ingestion, receipt scanning, and transaction preparation powered by Google Gemini AI for iPhone.",
    version="1.0.0"
)

# Configure CORS for local development & iOS simulator/device access
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("startup")
def on_startup():
    init_db()

@app.get("/")
def root():
    return {
        "service": "SmartLedger Auto-Scan Backend",
        "status": "online",
        "gemini_model": os.getenv("GEMINI_MODEL", "gemini-2.5-flash"),
        "docs_url": "/docs"
    }

@app.get("/health")
def health_check():
    return {"status": "healthy"}

# Include routers
app.include_router(auto_scan_router)
app.include_router(prepared_router)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
