"""
Part 3 — Async Testing with AsyncMock (15 min)
================================================
Goal: Test the async notify_customer() function using AsyncMock
and pytest-asyncio.

Key concepts:
  - AsyncMock (from unittest.mock, Python 3.8+)
  - Mocking httpx.AsyncClient responses
  - assert_awaited_once_with() instead of assert_called_once_with()

Hints (try on your own first!):
  - Mock the client: mock_client = AsyncMock(spec=httpx.AsyncClient)
  - Mock the response: mock_response = MagicMock(); mock_response.status_code = 200
  - Set mock_client.post.return_value = mock_response
  - Use @pytest.mark.asyncio on each test
"""

import pytest
import httpx
from unittest.mock import AsyncMock, MagicMock, patch
from order_processor import Order, OrderItem, notify_customer, NOTIFICATION_URL


def make_test_order():
    return Order(
        order_id="ORD-001",
        customer_email="test@example.com",
        items=[OrderItem("PROD-1", "Widget", 1, 10.00)],
    )


class TestNotifyCustomer:

    @pytest.mark.asyncio
    async def test_successful_notification(self):
        mock_client = AsyncMock(spec=httpx.AsyncClient)
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_client.post.return_value = mock_response

        order = make_test_order()
        result = await notify_customer(order, "Your order is confirmed!", client=mock_client)

        assert result is True
        mock_client.post.assert_awaited_once_with(
            f"{NOTIFICATION_URL}/send",
            json={"to": "test@example.com", "body": "Your order is confirmed!", "ref": "ORD-001"},
        )

    @pytest.mark.asyncio
    async def test_failed_notification_non_200(self):
        mock_client = AsyncMock(spec=httpx.AsyncClient)
        mock_response = MagicMock()
        mock_response.status_code = 500
        mock_client.post.return_value = mock_response

        order = make_test_order()
        result = await notify_customer(order, "Hello", client=mock_client)

        assert result is False

    @pytest.mark.asyncio
    async def test_network_error_returns_false(self):
        mock_client = AsyncMock(spec=httpx.AsyncClient)
        mock_client.post.side_effect = httpx.ConnectError("connection failed")

        order = make_test_order()
        result = await notify_customer(order, "Hello", client=mock_client)

        assert result is False
