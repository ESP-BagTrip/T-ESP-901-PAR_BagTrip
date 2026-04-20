"""Schémas Pydantic pour les trips."""

from datetime import date, datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, model_validator

from src.api.common.base_schema import BagtripRequestModel
from src.enums import DateMode, TrackingStatus, TripOrigin, TripStatus


class TripCreateRequest(BagtripRequestModel):
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
    dateMode: DateMode = DateMode.EXACT

    @model_validator(mode="after")
    def validate_trip(self) -> "TripCreateRequest":
        # Destination requise
        if not self.destinationName and not self.destinationIata:
            raise ValueError("At least destinationName or destinationIata is required")
        # Ordre des dates
        if self.startDate and self.endDate and self.startDate > self.endDate:
            raise ValueError("startDate must be before or equal to endDate")
        # Date future
        if self.startDate and self.startDate < date.today():
            raise ValueError("startDate must be today or in the future")
        return self


class TripUpdateRequest(BagtripRequestModel):
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
    dateMode: DateMode | None = None


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
    destinationTimezone: str | None = Field(default=None, alias="destination_timezone")
    nbTravelers: int | None = Field(default=None, alias="nb_travelers")
    coverImageUrl: str | None = Field(default=None, alias="cover_image_url")
    budgetTotal: float | None = Field(default=None, alias="budget_total")
    origin: str | None = None
    dateMode: str = Field(default="EXACT", alias="date_mode")
    flightsTracking: str = Field(default="TRACKED", alias="flights_tracking")
    accommodationsTracking: str = Field(default="TRACKED", alias="accommodations_tracking")
    archivedAt: datetime | None = Field(default=None, alias="archived_at")
    createdAt: datetime = Field(alias="created_at")
    updatedAt: datetime = Field(alias="updated_at")
    role: str | None = None
    completionPercentage: int = Field(default=0, alias="completion_percentage")

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)


class TripTrackingUpdateRequest(BagtripRequestModel):
    """Requête de mise à jour des flags de tracking d'un trip.

    Au moins un des deux champs doit être présent. Utilisé par l'utilisateur
    pour dire "je ne veux pas que BagTrip gère mes vols/hébergements".
    """

    flightsTracking: TrackingStatus | None = None
    accommodationsTracking: TrackingStatus | None = None

    @model_validator(mode="after")
    def at_least_one(self) -> "TripTrackingUpdateRequest":
        if self.flightsTracking is None and self.accommodationsTracking is None:
            raise ValueError(
                "At least one of flightsTracking or accommodationsTracking is required"
            )
        return self


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

    model_config = ConfigDict(populate_by_name=True)


class TripDetailResponse(BaseModel):
    """Réponse détaillée d'un trip avec agrégations."""

    trip: TripResponse
    flightOrder: dict | None = None


class TripStatusUpdateRequest(BagtripRequestModel):
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


class WeatherResponse(BaseModel):
    """Réponse météo pour un trip."""

    avg_temp_c: float
    min_temp_c: float
    max_temp_c: float
    description: str
    rain_probability: int = 0
    source: str = "unknown"
