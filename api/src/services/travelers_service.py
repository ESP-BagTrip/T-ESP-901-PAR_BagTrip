"""Service pour la gestion des travelers."""

from uuid import UUID

from sqlalchemy.orm import Session

from src.models.traveler import TripTraveler
from src.utils.errors import AppError


class TravelersService:
    """Service pour les opérations CRUD sur les travelers."""

    @staticmethod
    def create_traveler(
        db: Session,
        trip_id: UUID,
        amadeus_traveler_ref: str | None,
        traveler_type: str,
        first_name: str,
        last_name: str,
        date_of_birth: str | None = None,
        gender: str | None = None,
        documents: dict | None = None,
        contacts: dict | None = None,
        raw: dict | None = None,
    ) -> TripTraveler:
        """Créer un nouveau traveler (accès vérifié par la dependency)."""
        traveler = TripTraveler(
            trip_id=trip_id,
            amadeus_traveler_ref=amadeus_traveler_ref,
            traveler_type=traveler_type,
            first_name=first_name,
            last_name=last_name,
            date_of_birth=date_of_birth,
            gender=gender,
            documents=documents,
            contacts=contacts,
            raw=raw,
        )
        db.add(traveler)
        db.commit()
        db.refresh(traveler)
        return traveler

    @staticmethod
    def get_travelers_by_trip(db: Session, trip_id: UUID) -> list[TripTraveler]:
        """Récupérer tous les travelers d'un trip (accès vérifié par la dependency)."""
        return db.query(TripTraveler).filter(TripTraveler.trip_id == trip_id).all()

    @staticmethod
    def get_traveler_by_id(db: Session, traveler_id: UUID, trip_id: UUID) -> TripTraveler | None:
        """Récupérer un traveler par ID."""
        return (
            db.query(TripTraveler)
            .filter(TripTraveler.id == traveler_id, TripTraveler.trip_id == trip_id)
            .first()
        )

    @staticmethod
    def update_traveler(
        db: Session,
        traveler_id: UUID,
        trip_id: UUID,
        amadeus_traveler_ref: str | None = None,
        traveler_type: str | None = None,
        first_name: str | None = None,
        last_name: str | None = None,
        date_of_birth: str | None = None,
        gender: str | None = None,
        documents: dict | None = None,
        contacts: dict | None = None,
        raw: dict | None = None,
    ) -> TripTraveler:
        """Mettre à jour un traveler (accès vérifié par la dependency)."""
        traveler = TravelersService.get_traveler_by_id(db, traveler_id, trip_id)
        if not traveler:
            raise AppError("TRAVELER_NOT_FOUND", 404, "Traveler not found")

        if amadeus_traveler_ref is not None:
            traveler.amadeus_traveler_ref = amadeus_traveler_ref
        if traveler_type is not None:
            traveler.traveler_type = traveler_type
        if first_name is not None:
            traveler.first_name = first_name
        if last_name is not None:
            traveler.last_name = last_name
        if date_of_birth is not None:
            traveler.date_of_birth = date_of_birth
        if gender is not None:
            traveler.gender = gender
        if documents is not None:
            traveler.documents = documents
        if contacts is not None:
            traveler.contacts = contacts
        if raw is not None:
            traveler.raw = raw

        db.commit()
        db.refresh(traveler)
        return traveler

    @staticmethod
    def delete_traveler(db: Session, traveler_id: UUID, trip_id: UUID) -> None:
        """Supprimer un traveler (accès vérifié par la dependency)."""
        traveler = TravelersService.get_traveler_by_id(db, traveler_id, trip_id)
        if not traveler:
            raise AppError("TRAVELER_NOT_FOUND", 404, "Traveler not found")

        db.delete(traveler)
        db.commit()

    @staticmethod
    def traveler_to_amadeus_payload(traveler: TripTraveler) -> dict:
        """
        Mapper un TripTraveler vers le payload Amadeus.
        Stocke le payload complet dans traveler.raw.
        """
        # Construire le contact avec phones requis
        contacts_data = traveler.contacts or {}
        email_address = contacts_data.get("emailAddress")
        phone_number = contacts_data.get("phoneNumber", "")

        # Extraire le country code et le numéro du téléphone
        # Amadeus attend countryCallingCode SANS le "+" (ex: "33" pas "+33")
        country_calling_code = "33"  # Default to France (sans le +)
        number = phone_number

        if phone_number.startswith("+"):
            # Extraire le country code (1 à 3 chiffres)
            # Format: +33612345678 -> countryCode="33", number="612345678"
            # Format: +15550199 -> countryCode="1", number="5550199"
            
            # Stratégie : Essayer de trouver un séparateur non numérique
            separator_found = False
            for i in range(1, min(5, len(phone_number))):
                if not phone_number[i].isdigit():
                    country_calling_code = phone_number[1:i]
                    number = phone_number[i:]
                    separator_found = True
                    break
            
            if not separator_found:
                # Pas de séparateur, on devine.
                # Priorité aux codes pays connus ou heuristique simple.
                # Pour l'instant, on prend 1 chiffre si c'est '1' (USA/Canada), sinon on tente 2 ou 3.
                if len(phone_number) > 1 and phone_number[1] == '1':
                     country_calling_code = "1"
                     number = phone_number[2:]
                elif len(phone_number) > 3:
                     # Par défaut, on suppose 2 chiffres (ex: 33, 44, 49...) sauf si 3 chiffres semble mieux ?
                     # C'est ambigu sans lookup table. On garde le comportement précédent "33" par défaut si c'est un format français déguisé ?
                     # Non, si c'est "+...", c'est international.
                     # Essayons de prendre 2 chiffres par défaut.
                     country_calling_code = phone_number[1:3]
                     number = phone_number[3:]
                else:
                     # Trop court ?
                     country_calling_code = phone_number[1:]
                     number = ""
        elif phone_number.startswith("00"):
            # Format international avec 00: 0033612345678 -> countryCode="33", number="612345678"
            if len(phone_number) > 4:
                country_calling_code = phone_number[2:4]
                number = phone_number[4:]
            else:
                country_calling_code = "33"
                number = phone_number[2:]
        elif phone_number and phone_number[0] == "0":
            # Format français: 0612345678 -> countryCode="33", number="612345678"
            country_calling_code = "33"
            number = phone_number[1:] if len(phone_number) > 1 else phone_number

        contact = {
            "emailAddress": email_address,
            "phones": [
                {
                    "deviceType": "MOBILE",
                    "countryCallingCode": country_calling_code,  # Sans le "+"
                    "number": number,
                }
            ]
            if phone_number
            else [],
        }

        # Construire les documents avec validityCountry requis
        documents_data = traveler.documents or []
        documents = []
        for doc in (
            documents_data
            if isinstance(documents_data, list)
            else [documents_data]
            if documents_data
            else []
        ):
            if isinstance(doc, dict):
                # Ajouter validityCountry si manquant (utiliser issuanceCountry ou nationality comme fallback)
                if "validityCountry" not in doc:
                    doc["validityCountry"] = (
                        doc.get("issuanceCountry") or doc.get("nationality") or "FR"
                    )
                documents.append(doc)

        payload = {
            "id": traveler.amadeus_traveler_ref or str(traveler.id),
            "dateOfBirth": traveler.date_of_birth.isoformat() if traveler.date_of_birth else None,
            "name": {
                "firstName": traveler.first_name,
                "lastName": traveler.last_name,
            },
            "gender": traveler.gender,
            "contact": contact,
            "documents": documents if documents else None,
        }

        # Stocker le payload dans raw
        traveler.raw = payload
        return payload
