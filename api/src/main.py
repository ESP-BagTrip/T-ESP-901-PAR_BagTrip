"""Point d'entrée FastAPI."""

from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from src.api.auth.routes import router as auth_router
from src.api.travel.routes import router as travel_router
from src.config.database import Base, engine
from src.config.env import settings
from src.utils.errors import AppError, create_http_exception
from src.utils.logger import logger


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Gestion du cycle de vie de l'application."""
    # Créer les tables au démarrage
    Base.metadata.create_all(bind=engine)
    logger.info("Database tables created")
    yield
    # Nettoyage à l'arrêt (si nécessaire)
    logger.info("Application shutting down")


app = FastAPI(
    title="BagTrip API",
    description="API Python pour BagTrip avec intégration Amadeus",
    version="1.0.0",
    lifespan=lifespan,
)

# Configuration CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # À restreindre en production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Inclusion des routes
app.include_router(auth_router, prefix="/api")
app.include_router(travel_router, prefix="/api")


# Gestion globale des erreurs
@app.exception_handler(AppError)
async def app_error_handler(request: Request, exc: AppError):
    """Gestionnaire d'erreurs pour AppError."""
    return create_http_exception(exc)


@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    """Gestionnaire d'erreurs général."""
    logger.error("Unhandled exception", {"error": str(exc), "path": request.url.path})
    return JSONResponse(
        status_code=500,
        content={"error": "Internal server error", "detail": str(exc)},
    )


@app.get("/")
async def root():
    """Route racine."""
    return {"message": "BagTrip API", "version": "1.0.0"}


@app.get("/health")
async def health():
    """Route de santé."""
    return {"status": "ok"}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "src.main:app",
        host="0.0.0.0",
        port=settings.PORT,
        reload=settings.NODE_ENV == "development",
    )
