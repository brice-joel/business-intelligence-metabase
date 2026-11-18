-- Phase 2.1 : Création des schémas Médaillon et des tables RAW (Bronze)
-- Base cible : dwh

CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS mart;

-- Table technique de suivi des extractions incrémentales (Watermark)
CREATE TABLE IF NOT EXISTS raw.etl_watermarks (
    table_name        VARCHAR(100) PRIMARY KEY,
    last_extracted_at TIMESTAMP NOT NULL DEFAULT '1970-01-01 00:00:00',
    rows_extracted    BIGINT NOT NULL DEFAULT 0,
    updated_at        TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Tables RAW : miroir des tables OLTP sans FK bloquantes + _ingested_at

CREATE TABLE IF NOT EXISTS raw.users (
    id                  BIGINT PRIMARY KEY,
    name                VARCHAR(255),
    email               VARCHAR(255),
    country_code        VARCHAR(10),
    city                VARCHAR(100),
    segment             VARCHAR(30),
    acquisition_channel VARCHAR(50),
    created_at          TIMESTAMP,
    updated_at          TIMESTAMP,
    _ingested_at        TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS raw.categories (
    id           BIGINT PRIMARY KEY,
    parent_id    BIGINT,
    name         VARCHAR(120),
    slug         VARCHAR(140),
    created_at   TIMESTAMP,
    updated_at   TIMESTAMP,
    _ingested_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS raw.products (
    id           BIGINT PRIMARY KEY,
    category_id  BIGINT,
    sku          VARCHAR(64),
    name         VARCHAR(200),
    cost_price   NUMERIC(10, 2),
    list_price   NUMERIC(10, 2),
    status       VARCHAR(20),
    created_at   TIMESTAMP,
    updated_at   TIMESTAMP,
    _ingested_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS raw.orders (
    id               BIGINT PRIMARY KEY,
    user_id          BIGINT,
    order_number     VARCHAR(40),
    status           VARCHAR(20),
    currency         VARCHAR(3),
    subtotal_amount  NUMERIC(12, 2),
    discount_amount  NUMERIC(12, 2),
    shipping_amount  NUMERIC(10, 2),
    total_amount     NUMERIC(12, 2),
    shipping_country VARCHAR(10),
    shipping_city    VARCHAR(100),
    ordered_at       TIMESTAMP,
    created_at       TIMESTAMP,
    updated_at       TIMESTAMP,
    _ingested_at     TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS raw.order_items (
    id              BIGINT PRIMARY KEY,
    order_id        BIGINT,
    product_id      BIGINT,
    quantity        INTEGER,
    unit_price      NUMERIC(10, 2),
    unit_cost       NUMERIC(10, 2),
    discount_amount NUMERIC(10, 2),
    line_total      NUMERIC(12, 2),
    created_at      TIMESTAMP,
    updated_at      TIMESTAMP,
    _ingested_at    TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS raw.payments (
    id             BIGINT PRIMARY KEY,
    order_id       BIGINT,
    payment_method VARCHAR(30),
    status         VARCHAR(20),
    amount         NUMERIC(12, 2),
    paid_at        TIMESTAMP,
    created_at     TIMESTAMP,
    updated_at     TIMESTAMP,
    _ingested_at   TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS raw.shipments (
    id           BIGINT PRIMARY KEY,
    order_id     BIGINT,
    carrier      VARCHAR(50),
    status       VARCHAR(20),
    shipped_at   TIMESTAMP,
    delivered_at TIMESTAMP,
    created_at   TIMESTAMP,
    updated_at   TIMESTAMP,
    _ingested_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS raw.returns (
    id            BIGINT PRIMARY KEY,
    order_id      BIGINT,
    order_item_id BIGINT,
    reason        VARCHAR(100),
    refund_amount NUMERIC(12, 2),
    status        VARCHAR(20),
    returned_at   TIMESTAMP,
    created_at    TIMESTAMP,
    updated_at    TIMESTAMP,
    _ingested_at  TIMESTAMP NOT NULL DEFAULT NOW()
);
