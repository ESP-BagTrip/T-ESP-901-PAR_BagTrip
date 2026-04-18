"""Shared Pydantic base classes enforcing the BagTrip API case convention.

The mobile client (Dart `json_serializable` with `field_rename: snake`)
always writes snake_case keys on PATCH / POST bodies. The API exposes
camelCase in responses (historical convention) but new code should accept
**both** cases on input to avoid silently dropping fields — that class of
bug cost us the activity validation regression investigated during SMP-316.

Usage:
    class FooUpdateRequest(BagtripRequestModel):
        my_field: str | None = None        # accepts "my_field" or "myField"

    class FooResponse(BagtripResponseModel):
        my_field: str                      # serializes as "my_field" (alias);
                                           # clients that still want camelCase
                                           # can `.model_dump(by_alias=False)`.
"""

from __future__ import annotations

from pydantic import BaseModel, ConfigDict
from pydantic.alias_generators import to_camel


class BagtripRequestModel(BaseModel):
    """Base for POST / PATCH request DTOs.

    - `populate_by_name=True`: clients can send either `myField` or `my_field`.
    - `alias_generator=to_camel`: default alias is camelCase so existing
      Flutter callers that still send camelCase keep working unchanged.

    Inherit this on every new request schema instead of `BaseModel`.
    """

    model_config = ConfigDict(
        populate_by_name=True,
        alias_generator=to_camel,
    )


class BagtripResponseModel(BaseModel):
    """Base for response DTOs.

    - `from_attributes=True`: lets ``model_validate(sqlalchemy_instance)``
      read attributes directly.
    - `populate_by_name=True`: convenience for tests that build the model
      from a kwargs dict rather than an ORM object.
    """

    model_config = ConfigDict(
        from_attributes=True,
        populate_by_name=True,
    )
