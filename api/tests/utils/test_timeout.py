"""Tests for async_generator_with_timeout utility."""

import asyncio

import pytest

from src.utils.timeout import async_generator_with_timeout


async def _gen_items(items, delay=0):
    """Async generator that yields items with an optional delay."""
    for item in items:
        if delay:
            await asyncio.sleep(delay)
        yield item


async def _slow_gen(count, delay):
    """Async generator that yields count items, each after delay seconds."""
    for i in range(count):
        await asyncio.sleep(delay)
        yield i


async def _collect(agen):
    """Collect all items from an async generator."""
    return [item async for item in agen]


class TestAsyncGeneratorWithTimeout:
    @pytest.mark.asyncio
    async def test_completes_within_timeout(self):
        """Generator that finishes in time yields all items."""
        items = [1, 2, 3]
        result = await _collect(
            async_generator_with_timeout(_gen_items(items), total_timeout_seconds=5.0)
        )
        assert result == [1, 2, 3]

    @pytest.mark.asyncio
    async def test_empty_generator(self):
        """Empty generator returns nothing."""
        result = await _collect(
            async_generator_with_timeout(_gen_items([]), total_timeout_seconds=5.0)
        )
        assert result == []

    @pytest.mark.asyncio
    async def test_timeout_raises(self):
        """Generator that exceeds timeout raises TimeoutError."""
        with pytest.raises(asyncio.TimeoutError):
            await _collect(
                async_generator_with_timeout(
                    _slow_gen(100, delay=0.5),
                    total_timeout_seconds=0.2,
                )
            )

    @pytest.mark.asyncio
    async def test_partial_items_before_timeout(self):
        """Items yielded before timeout are accessible; TimeoutError raised after."""
        items = []
        with pytest.raises(asyncio.TimeoutError):
            async for item in async_generator_with_timeout(
                _slow_gen(10, delay=0.1),
                total_timeout_seconds=0.35,
            ):
                items.append(item)

        # Should have collected some items before timeout
        assert len(items) >= 1
        assert len(items) < 10

    @pytest.mark.asyncio
    async def test_single_slow_item_timeout(self):
        """A single item that takes too long triggers timeout."""

        async def one_slow_item():
            await asyncio.sleep(10)
            yield "never"

        with pytest.raises(asyncio.TimeoutError):
            await _collect(async_generator_with_timeout(one_slow_item(), total_timeout_seconds=0.1))

    @pytest.mark.asyncio
    async def test_preserves_item_types(self):
        """Yielded items maintain their types through the wrapper."""

        async def mixed_gen():
            yield 42
            yield "hello"
            yield {"key": "value"}

        result = await _collect(
            async_generator_with_timeout(mixed_gen(), total_timeout_seconds=5.0)
        )
        assert result == [42, "hello", {"key": "value"}]

    @pytest.mark.asyncio
    async def test_generator_exception_propagates(self):
        """Exceptions from the inner generator propagate through."""

        async def failing_gen():
            yield 1
            raise ValueError("inner error")

        with pytest.raises(ValueError, match="inner error"):
            await _collect(async_generator_with_timeout(failing_gen(), total_timeout_seconds=5.0))
