-- Phase 2.2 : Couche STAGING (Silver) — Données nettoyées, typées et normalisées
-- Base cible : dwh

CREATE TABLE IF NOT EXISTS staging.stg_customers (
    customer_id         BIGINT PRIMARY KEY,
    full_name           VARCHAR(255) NOT NULL,
    email               VARCHAR(255) NOT NULL,
    country_code        VARCHAR(2) NOT NULL,
    city                VARCHAR(100) NOT NULL,
    segment             VARCHAR(30) NOT NULL,
    acquisition_channel VARCHAR(50) NOT NULL,
    signup_at           TIMESTAMP NOT NULL,
    updated_at          TIMESTAMP NOT NULL,
    _staged_at          TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS staging.stg_products (
    product_id       BIGINT PRIMARY KEY,
    sku              VARCHAR(64) NOT NULL,
    product_name     VARCHAR(200) NOT NULL,
    category_name    VARCHAR(120) NOT NULL,
    subcategory_name VARCHAR(120) NOT NULL,
    cost_price       NUMERIC(10, 2) NOT NULL,
    list_price       NUMERIC(10, 2) NOT NULL,
    status           VARCHAR(20) NOT NULL,
    updated_at       TIMESTAMP NOT NULL,
    _staged_at       TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS staging.stg_orders (
    order_id         BIGINT PRIMARY KEY,
    order_number     VARCHAR(40) NOT NULL,
    customer_id      BIGINT NOT NULL,
    order_status     VARCHAR(20) NOT NULL,
    currency         VARCHAR(3) NOT NULL,
    subtotal_amount  NUMERIC(12, 2) NOT NULL,
    discount_amount  NUMERIC(12, 2) NOT NULL,
    shipping_amount  NUMERIC(10, 2) NOT NULL,
    total_amount     NUMERIC(12, 2) NOT NULL,
    shipping_country VARCHAR(2) NOT NULL,
    shipping_city    VARCHAR(100) NOT NULL,
    payment_method   VARCHAR(30) NOT NULL,
    payment_status   VARCHAR(20) NOT NULL,
    carrier          VARCHAR(50),
    delivery_days    NUMERIC(6, 2),
    refund_amount    NUMERIC(12, 2) NOT NULL DEFAULT 0,
    is_returned      BOOLEAN NOT NULL DEFAULT FALSE,
    ordered_at       TIMESTAMP NOT NULL,
    updated_at       TIMESTAMP NOT NULL,
    _staged_at       TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS staging.stg_order_items (
    order_item_id       BIGINT PRIMARY KEY,
    order_id            BIGINT NOT NULL,
    order_number        VARCHAR(40) NOT NULL,
    customer_id         BIGINT NOT NULL,
    product_id          BIGINT NOT NULL,
    order_status        VARCHAR(20) NOT NULL,
    payment_method      VARCHAR(30) NOT NULL,
    quantity            INTEGER NOT NULL,
    unit_price          NUMERIC(10, 2) NOT NULL,
    unit_cost           NUMERIC(10, 2) NOT NULL,
    discount_amount     NUMERIC(10, 2) NOT NULL,
    gross_amount        NUMERIC(12, 2) NOT NULL,
    net_amount          NUMERIC(12, 2) NOT NULL,
    cogs_amount         NUMERIC(12, 2) NOT NULL,
    gross_margin_amount NUMERIC(12, 2) NOT NULL,
    ordered_at          TIMESTAMP NOT NULL,
    updated_at          TIMESTAMP NOT NULL,
    _staged_at          TIMESTAMP NOT NULL DEFAULT NOW()
);
