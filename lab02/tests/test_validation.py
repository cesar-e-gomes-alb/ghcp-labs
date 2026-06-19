"""
Part 2 — Fixtures & Parametrize (15 min)
=========================================
Goal: Use pytest fixtures (factory pattern) and @pytest.mark.parametrize
to test validate_order() with clean, data-driven tests.

validate_order() has 8+ conditions. Use parametrize to hit them all
without writing 8 separate test functions.

Hints (try on your own first!):
  - Fixture factory: the fixture returns a *function*, not an object
  - Boundary tests: discount=0 and discount=100 are valid (empty error list)
  - Use @pytest.mark.parametrize("order_kwargs,expected_errors", [...])
"""

import pytest
from order_processor import Order, OrderItem, validate_order


# ── Part A: Fixture factory ──────────────────────────────────────────
# TODO: Move this into conftest.py so it's shared across all test files.

@pytest.fixture
def make_order():
    """
    Factory fixture — returns a *function* that creates an Order.
    Usage in tests:  order = make_order(discount_pct=110)
    """
    def _factory(**overrides):
        defaults = dict(
            order_id="ORD-001",
            customer_email="test@example.com",
            items=[OrderItem("PROD-1", "Widget", 2, 10.00)],
            discount_pct=0.0,
        )
        defaults.update(overrides)
        return Order(**defaults)
    return _factory


# ── Part B: Parametrized validation tests ────────────────────────────

class TestValidateOrder:

    def test_valid_order_has_no_errors(self, make_order):
        order = make_order()
        errors = validate_order(order)
        assert errors == []

    @pytest.mark.parametrize("order_kwargs,expected_error", [
        ({"order_id": ""},              "order_id is required"),
        ({"order_id": "   "},           "order_id is required"),
        ({"customer_email": "no-at"},   "customer_email is invalid"),
        ({"customer_email": ""},        "customer_email is invalid"),
        ({"items": []},                 "at least one item"),
        ({"discount_pct": -5},          "between 0 and 100"),
        ({"discount_pct": 101},         "between 0 and 100"),
    ])
    def test_single_validation_error(self, make_order, order_kwargs, expected_error):
        order = make_order(**order_kwargs)
        errors = validate_order(order)
        assert any(expected_error in e for e in errors), f"Expected '{expected_error}' in {errors}"

    @pytest.mark.parametrize("discount", [0, 100])
    def test_boundary_discounts_are_valid(self, make_order, discount):
        order = make_order(discount_pct=discount)
        errors = validate_order(order)
        assert not any("discount" in e for e in errors)

    @pytest.mark.parametrize("quantity,price,expected_error", [
        (0,  10.00, "quantity must be positive"),
        (-1, 10.00, "quantity must be positive"),
        (1,  -5.00, "unit_price cannot be negative"),
    ])
    def test_item_level_validation(self, make_order, quantity, price, expected_error):
        bad_item = OrderItem("BAD-1", "Bad Item", quantity, price)
        order = make_order(items=[bad_item])
        errors = validate_order(order)
        assert any(expected_error in e for e in errors)

    def test_multiple_errors_at_once(self, make_order):
        order = make_order(order_id="", customer_email="bad", items=[])
        errors = validate_order(order)
        assert len(errors) >= 3
