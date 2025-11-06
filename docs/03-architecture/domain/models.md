# Domain Models

This document describes the current domain models and their relationships in the Grenoble Roller application.

## Overview

The application currently implements an e-commerce system with user authentication and role-based access control. Event management features are planned for Phase 2.

## Core Models

### User

Authentication and user profile management using Devise.

**Attributes:**
- `email` (string, unique, required)
- `encrypted_password` (string, required)
- `first_name` (string)
- `last_name` (string)
- `bio` (text)
- `phone` (string, limit: 10)
- `avatar_url` (string)
- `email_verified` (boolean, default: false)
- `role_id` (integer, foreign key, required)

**Relationships:**
- `belongs_to :role`
- `has_many :orders`

**Indexes:**
- `email` (unique)
- `reset_password_token` (unique, for Devise)

### Role

7-level permission system for access control.

**Attributes:**
- `code` (string, limit: 50, unique, required)
- `name` (string)
- `description` (text)
- `level` (integer, limit: 2, required)

**Roles (by level):**
1. `USER` (10) - Basic user
2. `REGISTERED` (20) - Registered member
3. `INITIATION` (30) - Initiation level
4. `ORGANIZER` (40) - Can create events (future)
5. `MODERATOR` (50) - Can moderate content (future)
6. `ADMIN` (60) - Full administrative access
7. `SUPERADMIN` (70) - Highest level access

**Relationships:**
- `has_many :users`

**Indexes:**
- `code` (unique)

## E-commerce Models

### ProductCategory

Product categorization.

**Attributes:**
- `name` (string, limit: 100, required)
- `slug` (string, limit: 120, unique, required)

**Relationships:**
- `has_many :products`

**Current Categories:**
- Rollers
- Protections
- Accessoires

### Product

Main product entity.

**Attributes:**
- `name` (string, limit: 140, required)
- `slug` (string, limit: 160, unique, required)
- `description` (text)
- `price_cents` (integer, required)
- `currency` (string, limit: 3, default: "EUR")
- `stock_qty` (integer, default: 0)
- `is_active` (boolean, default: true)
- `image_url` (string, limit: 255)
- `category_id` (bigint, foreign key, required)

**Relationships:**
- `belongs_to :category` (ProductCategory)
- `has_many :variants` (ProductVariant)

**Indexes:**
- `slug` (unique)
- `is_active, slug` (composite)

### ProductVariant

Product variations (size, color, etc.).

**Attributes:**
- `sku` (string, limit: 80, unique, required)
- `price_cents` (integer, required)
- `currency` (string, limit: 3, default: "EUR")
- `stock_qty` (integer, default: 0)
- `is_active` (boolean, default: true)
- `product_id` (bigint, foreign key, required)

**Relationships:**
- `belongs_to :product`
- `has_many :variant_option_values`
- `has_many :option_values, through: :variant_option_values`
- `has_many :order_items`

**Indexes:**
- `sku` (unique)
- `product_id`

### OptionType

Type of product option (e.g., "size", "color").

**Attributes:**
- `name` (string, limit: 50, unique, required)
- `presentation` (string, limit: 100)

**Relationships:**
- `has_many :option_values`

**Current Types:**
- `size` - Product sizes
- `color` - Product colors

### OptionValue

Specific option values (e.g., "S", "M", "L" for size).

**Attributes:**
- `value` (string, limit: 50, required)
- `presentation` (string, limit: 100)
- `option_type_id` (bigint, foreign key, required)

**Relationships:**
- `belongs_to :option_type`
- `has_many :variant_option_values`
- `has_many :variants, through: :variant_option_values`

### VariantOptionValue

Join table linking variants to their option values.

**Attributes:**
- `variant_id` (bigint, foreign key, required)
- `option_value_id` (bigint, foreign key, required)

**Relationships:**
- `belongs_to :variant` (ProductVariant)
- `belongs_to :option_value`

**Indexes:**
- `variant_id, option_value_id` (unique composite)

## Order Management Models

### Order

Customer order.

**Attributes:**
- `status` (string, default: "pending", required)
  - Values: `pending`, `paid`, `shipped`, `cancelled`
- `total_cents` (integer, default: 0, required)
- `currency` (string, limit: 3, default: "EUR", required)
- `user_id` (bigint, foreign key, required)
- `payment_id` (bigint, foreign key, optional)

**Relationships:**
- `belongs_to :user`
- `belongs_to :payment` (optional)
- `has_many :order_items`

**Indexes:**
- `user_id`
- `payment_id`

### OrderItem

Individual items in an order.

**Attributes:**
- `quantity` (integer, default: 1, required)
- `unit_price_cents` (integer, required)
- `order_id` (bigint, foreign key, required)
- `variant_id` (integer, foreign key, required)

**Relationships:**
- `belongs_to :order`
- `belongs_to :variant` (ProductVariant)

**Indexes:**
- `order_id`
- `variant_id`

### Payment

Payment record (multi-provider ready).

**Attributes:**
- `provider` (string, limit: 20, required)
  - Values: `stripe`, `paypal`, `mollie`, `helloasso`, `free`
- `provider_payment_id` (string) - External payment ID
- `amount_cents` (integer, default: 0, required)
- `currency` (string, limit: 3, default: "EUR", required)
- `status` (string, limit: 20, default: "succeeded", required)
  - Values: `succeeded`, `pending`, `failed`

**Relationships:**
- `has_one :order`

## Entity Relationship Diagram

```
User ──┬──> Role
       │
       └──> Order ──┬──> Payment
                    │
                    └──> OrderItem ──> ProductVariant ──┬──> Product ──> ProductCategory
                                                         │
                                                         └──> VariantOptionValue ──> OptionValue ──> OptionType
```

## Future Models (Phase 2)

The following models are planned for event management:

- `Event` - Rollerblading events/outings
- `Route` - Predefined routes with GPX data
- `EventRegistration` - User registrations for events
- `EventOrganizer` - Verified organizer assignments

## Database Migrations

All migrations are located in `db/migrate/`. Current schema version: `2025_11_06_121500`.

To view the complete schema:

```bash
cat db/schema.rb
```

## Seed Data

The `db/seeds.rb` file creates:
- 7 roles (USER to SUPERADMIN)
- 1 admin user
- 1 superadmin user (Florian)
- 5 test client users
- 5 payments (various providers and statuses)
- 5 orders
- 3 product categories
- Multiple products with variants and options
- 11 order items

Run seeds:

```bash
docker exec grenoble-roller-dev bin/rails db:seed
```

