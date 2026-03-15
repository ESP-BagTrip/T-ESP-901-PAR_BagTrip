"""Schémas Pydantic pour les trips."""

from datetime import date, datetime
from uuid import UUID

from pydantic import BaseModel, Field

from src.enums import TripOrigin, TripStatus


class TripCreateRequest(BaseModel):
    """Requête de création de trip."""

    title: str | None = None
    originIata: str | None = None
    destinationIata: str | None = None
    startDate: date | None = None
    endDate: date | None = None
    description: str | None = None
    destinationName: str | None = None
    nbTravelers: int | None = None
    coverImageUrl: str | None = None
    budgetTotal: float | None = None
    origin: TripOrigin | None = None


class TripUpdateRequest(BaseModel):
    """Requête de mise à jour de trip."""

    title: str | None = None
    originIata: str | None = None
    destinationIata: str | None = None
    startDate: date | None = None
    endDate: date | None = None
    description: str | None = None
    destinationName: str | None = None
    nbTravelers: int | None = None
    coverImageUrl: str | None = None
    budgetTotal: float | None = None


class TripResponse(BaseModel):
    """Réponse trip."""

    id: UUID
    title: str | None = None
    originIata: str | None = Field(default=None, alias="origin_iata")
    destinationIata: str | None = Field(default=None, alias="destination_iata")
    startDate: date | None = Field(default=None, alias="start_date")
    endDate: date | None = Field(default=None, alias="end_date")
    status: str | None = None
    description: str | None = None
    destinationName: str | None = Field(default=None, alias="destination_name")
    nbTravelers: int | None = Field(default=None, alias="nb_travelers")
    coverImageUrl: str | None = Field(default=None, alias="cover_image_url")
    budgetTotal: float | None = Field(default=None, alias="budget_total")
    origin: str | None = None
    archivedAt: datetime | None = Field(default=None, alias="archived_at")
    createdAt: datetime = Field(alias="created_at")
    updatedAt: datetime = Field(alias="updated_at")
    role: str | None = None

    class Config:
        from_attributes = True
        populate_by_name = True


class TripListResponse(BaseModel):
    """Réponse liste de trips selon PLAN.md."""

    items: list[TripResponse]


class TripPaginatedResponse(BaseModel):
    """Réponse paginée de trips."""

    items: list[TripResponse]
    total: int
    page: int
    limit: int
    totalPages: int = Field(alias="total_pages")

    class Config:
        populate_by_name = True


class TripDetailResponse(BaseModel):
    """Réponse détaillée d'un trip avec agrégations."""

    trip: TripResponse
    flightOrder: dict | None = None


class TripStatusUpdateRequest(BaseModel):
    """Requête de mise à jour du statut d'un trip."""

    status: TripStatus


class TripHomeStats(BaseModel):
    """Statistiques pour la page d'accueil d'un trip."""

    baggageCount: int = 0
    totalExpenses: float = 0.0
    nbTravelers: int = 1
    daysUntilTrip: int | None = None
    tripDuration: int | None = None


class TripFeatureTile(BaseModel):
    """Tuile de fonctionnalité pour la page d'accueil d'un trip."""

    id: str
    label: str
    icon: str
    route: str
    enabled: bool = False


class TripSectionSummary(BaseModel):
    """Résumé d'une section pour la page d'accueil d'un trip."""

    sectionId: str
    count: int = 0
    previewItems: list[str] = []


class TripHomeResponse(BaseModel):
    """Réponse pour la page d'accueil d'un trip."""

    trip: TripResponse
    stats: TripHomeStats
    features: list[TripFeatureTile]
    sections: list[TripSectionSummary] = []


class TripGroupedResponse(BaseModel):
    """Réponse des trips groupés par statut."""

    ongoing: list[TripResponse] = []
    planned: list[TripResponse] = []
    completed: list[TripResponse] = []
