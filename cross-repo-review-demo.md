# Decomposed Cross-Repo Review Demo

## Overview

This document showcases Propel's decomposed cross-repo code review capability using the [ecommerce-polyrepo](https://github.com/propel-gtm/ecommerce-polyrepo) test environment. The polyrepo contains multiple microservices (`be-api-gin`, `svc-listing-spring`, `svc-user-django`, `svc-inventory-rails`, etc.) that communicate via shared contracts.

## Test PR

**PR:** [feat!: V2 API with breaking contract changes](https://github.com/propel-gtm/ecommerce-polyrepo-be-api-gin/pull/2)
**Repo:** `propel-gtm/ecommerce-polyrepo-be-api-gin`

The PR introduces intentional V2 breaking API contract changes affecting three downstream services:

| Domain | Affected Service | Example Breaking Change |
|--------|-----------------|------------------------|
| Product | `svc-listing-spring` | `price` changed from `float64` to `PriceInfo{amount, currency, display_value}` |
| Order | `svc-user-django` | `total_amount` changed from `float64` to `OrderTotals{subtotal, tax, shipping, grand_total}` |
| Inventory | `svc-inventory-rails` | `available` changed from `bool` to `stock_status` string enum |

## Decomposed Review Passes

Propel ran **two separate review passes**, each with distinct focus areas and severity levels. Each pass produced targeted comments rather than a single monolithic review.

### Pass 1 — Risk: Medium | Status: Changes Suggested

| Priority | Category | File | Line | Focus |
|----------|----------|------|------|-------|
| Important | Logic | `pkg/grpc/client.go` | 199 | Float-to-cents truncation bug |
| Recommended | Maintainability | `internal/handlers/product.go` | 84 | Cross-repo contract staleness |

### Pass 2 — Risk: Low | Status: Minor Suggestions

| Priority | Category | File | Line | Focus |
|----------|----------|------|------|-------|
| Advisory | Maintainability | `pkg/grpc/client.go` | 341 | Pattern consistency in money formatting |
| Advisory | Unused Code | `internal/models/models.go` | 106 | Dead code detection |

## Highlight: Cross-Repo Contract Awareness

The standout comment demonstrating cross-repo intelligence is on [`internal/handlers/product.go` line 84](https://github.com/propel-gtm/ecommerce-polyrepo-be-api-gin/pull/2#discussion_r2756292458):

> **[Maintainability] [Deep Thinking Mode: Code Structure]** This logic relies on the deprecated `inventory.Available` boolean field. According to the V2 contract changes described in the PR summary, the inventory domain has moved to a `stock_status` string enum. This handler should be updated to interpret the new `StockLevel` structure and map the status enum to the product's availability.

### Why this matters

This comment connects knowledge across service boundaries:

1. **Detected** that the API gateway handler still uses `inventory.Available` (a boolean)
2. **Understood** from the PR context that the inventory domain (`svc-inventory-rails`) has migrated to a `stock_status` string enum
3. **Recommended** updating the handler to consume the new `StockLevel` structure

This is exactly the kind of cross-service contract mismatch that causes production incidents in polyrepo architectures — and the decomposed review caught it automatically.

## Other Notable Comments

### Float Precision Bug (Important)

On [`pkg/grpc/client.go` line 199](https://github.com/propel-gtm/ecommerce-polyrepo-be-api-gin/pull/2#discussion_r2756292457):

The review caught that `int64(req.Price * 100)` truncates due to float precision, and `DisplayValue` uses `string(rune(int(req.Price)))` which produces a single Unicode character instead of a formatted dollar amount. The fix suggestion uses `math.Round` for proper cents conversion:

```go
amountCents := int64(math.Round(req.Price * 100))
price := models.PriceInfo{
    Amount:       amountCents,
    Currency:     "USD",
    DisplayValue: fmt.Sprintf("$%.2f", float64(amountCents)/100),
}
```

### Pattern Consistency (Advisory)

On [`pkg/grpc/client.go` line 341](https://github.com/propel-gtm/ecommerce-polyrepo-be-api-gin/pull/2#discussion_r2760393050):

Found the same rune/cents bug repeated across order line totals, subtotals, and grand totals. Recommended a consistent formatting helper to avoid the pattern of `"$" + string(rune(lineTotalCents/100))` which produces values like `$\^]` instead of `$29.99`.

### Dead Code Detection (Advisory)

On [`internal/models/models.go` line 106](https://github.com/propel-gtm/ecommerce-polyrepo-be-api-gin/pull/2#discussion_r2760393058):

Flagged that the `StockLevel` struct is defined but never referenced in any modified file, suggesting removal until code actually consumes it.

## Review Architecture

The decomposed review demonstrates several architectural properties:

- **Multi-pass analysis**: Separate passes focus on different concern types (logic bugs vs. maintainability vs. dead code) rather than trying to catch everything in one pass
- **Severity stratification**: Each pass produces its own risk assessment, allowing developers to triage efficiently
- **Deep Thinking Mode**: Specialized analysis modes (Code Structure, Pattern Consistency, Dead Code) are applied per-comment, enabling deeper reasoning on specific concern types
- **Cross-repo context**: The review system understands contract relationships between services in the polyrepo and flags mismatches across service boundaries

---

## Cross-Repo Breaking Change Test PRs

The following 10 PRs intentionally introduce cross-repo contract-breaking changes across the polyrepo. Each PR targets a different service and breaks contracts that downstream (or upstream) services depend on. A cross-repo-aware reviewer should flag the issues described in the "Expected Review Comment" column.

| # | PR | Repo | Breaking Change Introduced | Affected Services | Expected Review Comment |
|---|-----|------|---------------------------|-------------------|------------------------|
| 1 | [feat!: migrate product pricing from float64 to PriceInfo struct](https://github.com/propel-gtm/ecommerce-polyrepo-be-api-gin/pull/3) | `be-api-gin` | `Product.Price` changed from `float64` to `PriceInfo{amount, currency, display_value}` struct; same for `OrderItem.UnitPrice`, `TotalPrice`, and `Order.TotalAmount` | `fe-nextjs`, `svc-listing-spring` | Frontend calls `product.price.toFixed(2)` which will throw at runtime since `price` is now an object, not a number. The listing service returns `BigDecimal` prices that no longer map to the gateway's `PriceInfo` struct. |
| 2 | [feat!: V2 product status with moderation lifecycle states](https://github.com/propel-gtm/ecommerce-polyrepo-svc-listing-spring/pull/1) | `svc-listing-spring` | `ProductStatus.OUT_OF_STOCK` renamed to `SOLD_OUT`; added `PENDING_REVIEW`, `REJECTED`, `SUSPENDED` | `be-api-gin`, `fe-nextjs`, `proto-schemas` | The API gateway and frontend have no handling for `SOLD_OUT`, `PENDING_REVIEW`, `REJECTED`, or `SUSPENDED` statuses. The proto-schemas `ListingStatus` enum is now out of sync with the Java implementation. Products in `PENDING_REVIEW` state could leak into API responses with no consumer understanding the status. |
| 3 | [feat!: migrate user ID from UUID to auto-incrementing BigInteger](https://github.com/propel-gtm/ecommerce-polyrepo-svc-user-django/pull/1) | `svc-user-django` | `User.id` changed from `UUIDField` to `BigAutoField` — IDs are now integers instead of UUID strings | `be-api-gin`, `svc-listing-spring`, `svc-inventory-rails`, `proto-schemas` | The API gateway `User.ID` is typed as `string` and expects UUID format. `Order.UserID` and `Product.SellerID` store UUID strings that will mismatch with integer IDs from the user service. The proto-schemas define `User.id` as `string` — integer serialization will produce `"123"` instead of `"550e8400-e29b..."`, breaking any UUID validation or parsing downstream. |
| 4 | [feat!: support fractional inventory quantities for weight-based products](https://github.com/propel-gtm/ecommerce-polyrepo-svc-inventory-rails/pull/1) | `svc-inventory-rails` | `quantity_on_hand` and `quantity_reserved` changed from integer to float; API responses return floats | `be-api-gin`, `proto-schemas`, `svc-listing-spring` | The gateway `Inventory.Quantity` is `int32` — receiving `42.5` will truncate to `42`, silently losing fractional stock. The proto-schemas `StockLevel.quantity` is `int64`, incompatible with float values. The listing service `Product.quantity` is `Integer`, creating a type mismatch when reconciling inventory data. |
| 5 | [feat!: replace boolean inStock with stockStatus enum and rename imageUrl](https://github.com/propel-gtm/ecommerce-polyrepo-fe-nextjs/pull/1) | `fe-nextjs` | `Product.inStock` (boolean) replaced with `Product.stockStatus` (string enum); `imageUrl` renamed to `thumbnailUrl` | `be-api-gin`, `svc-listing-spring`, `svc-inventory-rails` | The API gateway sets `product.InStock = product.Available` and returns `imageUrl` — the frontend now expects `stockStatus` and `thumbnailUrl`, neither of which the gateway provides. The frontend will render all products as out-of-stock since `stockStatus` will be `undefined`. |
| 6 | [feat!: rename Money.units to amount and migrate pagination to offset-based](https://github.com/propel-gtm/ecommerce-polyrepo-proto-schemas/pull/2) | `proto-schemas` | `Money.units` renamed to `Money.amount`; cursor-based `page_token` pagination replaced with `offset`-based | All services | All generated gRPC code referencing `.units` (Go), `.getUnits()` (Java), `.units` (Python/Ruby) will fail to compile. Every service implementing cursor-based pagination with `page_token` must rewrite to offset-based. Wire compatibility is preserved (field number 2 unchanged) but all code-level references break. |
| 7 | [feat!: V2 user API response with structured phone and display_name](https://github.com/propel-gtm/ecommerce-polyrepo-svc-user-django/pull/2) | `svc-user-django` | `phone_number` string replaced with structured `phone{country_code, national_number, e164}` object; `username` removed from response; `display_name` added | `be-api-gin`, `fe-nextjs`, `svc-listing-spring` | The gateway `User` struct has a flat `Name string` field — the user service no longer returns `username` and instead returns `display_name`. Phone data is now a nested object instead of a string, breaking any code that reads `user.phone_number` directly. Seller info lookups in the listing service may depend on `username`. |
| 8 | [feat!: remove product quantity field and scope SKU uniqueness per-seller](https://github.com/propel-gtm/ecommerce-polyrepo-svc-listing-spring/pull/2) | `svc-listing-spring` | `Product.quantity` field removed entirely (delegated to inventory); SKU uniqueness changed from global to per-seller | `be-api-gin`, `svc-inventory-rails`, `proto-schemas` | The gateway expects `Product.Stock` (int32) from the listing service — the field no longer exists. The inventory service tracks stock by SKU assuming global uniqueness, but the same SKU can now belong to different sellers, causing ambiguous inventory lookups. The `PATCH /products/{id}/quantity` endpoint was removed with no deprecation period. |
| 9 | [feat!: enforce global SKU uniqueness and rename location to warehouse_id](https://github.com/propel-gtm/ecommerce-polyrepo-svc-inventory-rails/pull/2) | `svc-inventory-rails` | SKU uniqueness changed from per-location to global; `location` field renamed to `warehouse_id` across all APIs | `be-api-gin`, `svc-listing-spring`, `proto-schemas` | The gateway and all API consumers pass `location` as a parameter — the inventory service now expects `warehouse_id`, causing 400/404 errors. This directly contradicts PR #8 which makes SKU per-seller in listings while this PR makes SKU globally unique in inventory — creating an irreconcilable SKU ownership conflict between the two services. |
| 10 | [feat!: V2 order model with structured status, payment, and address changes](https://github.com/propel-gtm/ecommerce-polyrepo-be-api-gin/pull/4) | `be-api-gin` | `Order.Status` changed from string to `OrderStatusInfo{current, previous, reason}` struct; `Address.country` renamed to `country_code`; `PaymentInfo` required on order creation | `fe-nextjs`, `svc-user-django`, `svc-inventory-rails` | Frontend reads `order.status` as a string for display — it now receives a nested object, breaking all status comparisons and rendering. `Address.country` renamed to `country_code` breaks all existing address forms and serialization. The new required `payment` field on order creation is a backwards-incompatible API change — existing clients will get 400 errors. |

### Cross-PR Conflict: SKU Uniqueness Paradox (PRs #8 + #9)

PRs #8 and #9 create a deliberate **cross-repo contradiction**: PR #8 relaxes SKU uniqueness in the listing service (from global to per-seller), while PR #9 tightens it in the inventory service (from per-location to global). If both are merged, the same SKU could exist for two different sellers in listings, but only one inventory record can exist for that SKU globally — making it impossible to track stock for both sellers' products.

A cross-repo-aware reviewer should flag this as a **critical architectural conflict** that cannot be resolved by fixing either PR in isolation.
