"""
bapX Auto Backend - FastAPI Server

End-to-end AI automation platform with:
- Multi-agent orchestration (from Suna AI)
- GraphRAG with lifetime memory
- BYOK for 100+ AI models
- WebContainers + Docker sandbox
- Pay-per-GB storage billing
"""

from dotenv import load_dotenv
load_dotenv()

from fastapi import FastAPI, Request, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from datetime import datetime, timezone
import asyncio
import sys

from core.services.redis import redis_service
from core.services.supabase import DBConnection
from core.utils.logger import logger
from core.utils.config import config

# Import routers
from core.agents.api import router as agents_router
from core.threads.api import router as threads_router
from core.sandbox.api import router as sandbox_router
from core.ai_gateway.api import router as ai_gateway_router
from core.graphrag.api import router as graphrag_router
from core.storage.api import router as storage_router
from core.auth.api import router as auth_router
from core.billing.api import router as billing_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup and shutdown events"""
    # Startup
    logger.info("🚀 bapX Auto Backend starting...")
    
    try:
        await DBConnection().initialize()
        await redis_service.initialize()
        logger.info("✅ Database and Redis connected")
    except Exception as e:
        logger.error(f"❌ Failed to initialize services: {e}")
        raise
    
    logger.info(f"✅ bapX Auto Backend ready on port {config.PORT}")
    
    yield
    
    # Shutdown
    logger.info("👋 bapX Auto Backend shutting down...")
    await redis_service.close()


app = FastAPI(
    title="bapX Auto API",
    description="End-to-end AI automation platform",
    version="1.0.0",
    lifespan=lifespan
)

# CORS - Allow all origins for PWA
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure per-environment in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Health check
@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "version": "1.0.0"
    }


# Include routers
app.include_router(auth_router, prefix="/api/v1", tags=["Auth"])
app.include_router(agents_router, prefix="/api/v1", tags=["Agents"])
app.include_router(threads_router, prefix="/api/v1", tags=["Threads"])
app.include_router(sandbox_router, prefix="/api/v1", tags=["Sandbox"])
app.include_router(ai_gateway_router, prefix="/api/v1", tags=["AI Gateway"])
app.include_router(graphrag_router, prefix="/api/v1", tags=["GraphRAG"])
app.include_router(storage_router, prefix="/api/v1", tags=["Storage"])
app.include_router(billing_router, prefix="/api/v1", tags=["Billing"])


@app.get("/")
async def root():
    return {
        "name": "bapX Auto API",
        "version": "1.0.0",
        "docs": "/docs",
        "health": "/health"
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "api:app",
        host="0.0.0.0",
        port=config.PORT,
        reload=config.ENV_MODE == "development"
    )
