"""Shared pagination primitives — dependency, helper and generic response.

Every paginated endpoint and service in the API should go through this module
instead of recomputing `offset`/`count`/`slice` inline. The goals are:

1. A single `PaginationParams` FastAPI dependency so routes stop hand-rolling
   `page: int = Query(...)` / `limit: int = Query(...)` on every endpoint.
2. A single `paginate()` helper that accepts a SQLAlchemy query and a
   per-row serializer, and returns a `PageResult` dataclass with the three
   numbers every caller needs (items, total, total_pages).
3. A generic `Page[T]` Pydantic response so we can standardise the wire
   format across features (currently we have `max`, `page/limit`, nothing).
"""

from __future__ import annotations

from collections.abc import Callable, Sequence
from dataclasses import dataclass
from math import ceil
from typing import Any

from fastapi import Query
from pydantic import BaseModel, Field
from sqlalchemy.orm import Query as SAQuery


class PaginationParams:
    """FastAPI dependency — standard `page` / `limit` query parameters.

    Usage:
        @router.get("/things")
        def list_things(
            pagination: PaginationParams = Depends(PaginationParams),
            ...
        ):
            return paginate(query, pagination, ThingResponse.model_validate)
    """

    def __init__(
        self,
        page: int = Query(1, ge=1, description="Page number (1-indexed)"),
        limit: int = Query(20, ge=1, le=100, description="Items per page (1-100)"),
    ) -> None:
        self.page = page
        self.limit = limit

    @property
    def offset(self) -> int:
        return (self.page - 1) * self.limit

    @classmethod
    def of(cls, page: int, limit: int) -> PaginationParams:
        """Construct outside FastAPI (services, tests, jobs).

        The dependency form above is only usable as a `Depends(PaginationParams)`;
        this factory bypasses the `Query` defaults so callers that already have
        the two numbers can still go through `paginate()`.
        """
        instance = cls.__new__(cls)
        instance.page = page
        instance.limit = limit
        return instance


@dataclass(slots=True)
class PageResult[T]:
    """Result of a paginate() call — flat tuple-like dataclass.

    Services that already return `tuple[items, total, total_pages]` can use
    `result.as_tuple()` as a drop-in replacement during migration.
    """

    items: list[T]
    total: int
    page: int
    limit: int
    total_pages: int

    def as_tuple(self) -> tuple[list[T], int, int]:
        """Legacy shape — (items, total, total_pages)."""
        return self.items, self.total, self.total_pages


def paginate[T](
    query: SAQuery[Any],
    params: PaginationParams,
    serializer: Callable[[Any], T] | None = None,
) -> PageResult[T]:
    """Run a standard (count → offset → limit → serialize) pipeline.

    Args:
        query: A SQLAlchemy query (can be a tuple query for joins).
        params: The incoming pagination parameters.
        serializer: Optional per-row mapper. When omitted, raw rows are returned.

    Returns:
        A `PageResult` containing the serialized items and pagination metadata.
    """
    total = query.count()
    rows: Sequence[Any] = query.offset(params.offset).limit(params.limit).all()
    items = list(rows) if serializer is None else [serializer(row) for row in rows]
    total_pages = ceil(total / params.limit) if params.limit > 0 else 0
    return PageResult(
        items=items,
        total=total,
        page=params.page,
        limit=params.limit,
        total_pages=total_pages,
    )


class Page[T](BaseModel):
    """Generic paginated response body — camelCase on the wire."""

    items: list[T]
    total: int
    page: int
    limit: int
    total_pages: int = Field(alias="totalPages")

    model_config = {"populate_by_name": True}

    @classmethod
    def from_result(cls, result: PageResult[T]) -> Page[T]:
        return cls(
            items=result.items,
            total=result.total,
            page=result.page,
            limit=result.limit,
            total_pages=result.total_pages,
        )
