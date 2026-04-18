"""Shared Pydantic base classes enforcing the BagTrip API case convention.

Context: the mobile client (Dart `json_serializable` with
`field_rename: snake`) writes snake_case keys on every request body. The
API returns camelCase to match existing Flutter models that declare fields
like `validationStatus`. A historical mix of `Field(alias="foo_bar")` on
every column was error-prone — one forgotten alias silently dropped the
field on mobile-sourced PATCH bodies (SMP-316 activity-validation bug).

Policy:

- **Request DTOs** accept both `myField` and `my_field` on the wire; they
  serialize as `myField` when re-emitted.
- **Response DTOs** read from ORM objects (snake_case Python attributes)
  and emit camelCase on the wire.

Usage:

    class FooUpdateRequest(BagtripRequestModel):
        my_field: str | None = None  # wire: accepts myField | my_field

    class FooResponse(BagtripResponseModel):
        my_field: str                 # wire: emits "myField"

Existing schemas are free to keep their explicit `Field(alias=...)` for
transition purposes — an explicit alias wins over the generator.
"""

from __future__ import annotations

from pydantic import AliasChoices, AliasGenerator, BaseModel, ConfigDict
from pydantic.alias_generators import to_camel, to_snake


def _request_validation_alias(field_name: str) -> AliasChoices:
    """Accept either the Python field name or its snake_case form."""
    snake = to_snake(field_name)
    if snake == field_name:
        return AliasChoices(field_name)
    return AliasChoices(field_name, snake)


_request_alias_gen = AliasGenerator(
    validation_alias=_request_validation_alias,
    serialization_alias=to_camel,
)


class BagtripRequestModel(BaseModel):
    """Base for POST / PATCH request DTOs.

    Accepts snake_case and camelCase on input; serializes camelCase.
    Python field names may be written in either casing — the alias
    generator handles the mapping either way.
    """

    model_config = ConfigDict(
        populate_by_name=True,
        alias_generator=_request_alias_gen,
    )


_response_alias_gen = AliasGenerator(
    # Read from ORM: SQLAlchemy columns are snake_case.
    validation_alias=to_snake,
    # Emit camelCase to match the Flutter models.
    serialization_alias=to_camel,
)


class BagtripResponseModel(BaseModel):
    """Base for response DTOs.

    Reads snake_case attributes from ORM instances (`from_attributes=True`)
    and emits camelCase on the JSON wire.
    """

    model_config = ConfigDict(
        from_attributes=True,
        populate_by_name=True,
        alias_generator=_response_alias_gen,
    )
