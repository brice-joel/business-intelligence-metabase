-- Phase 2.3 : Couche MART (Gold) — Modèle en étoile de Kimball
-- Base cible : dwh

-- 1. Dimension Temps (clé entière YYYYMMDD)
CREATE TABLE IF NOT EXISTS mart.dim_date (
    date_key      INTEGER PRIMARY KEY,
    full_date     DATE NOT NULL UNIQUE,
    year_num      SMALLINT NOT NULL,
    quarter_num   SMALLINT NOT NULL,
    month_num     SMALLINT NOT NULL,
    month_name    VARCHAR(15) NOT NULL,
    week_num      SMALLINT NOT NULL,
    day_of_month  SMALLINT NOT NULL,
    day_of_week   SMALLINT NOT NULL,
    day_name      VARCHAR(15) NOT NULL,
    is_weekend    BOOLEAN NOT NULL,
    year_month    VARCHAR(7) NOT NULL,
    year_quarter  VARCHAR(7) NOT NULL
);

-- Peuplement idempotent de dim_date sur 2015-01-01 -> 2027-12-31
INSERT INTO mart.dim_date (
    date_key, full_date, year_num, quarter_num, month_num, month_name,
    week_num, day_of_month, day_of_week, day_name, is_weekend, year_month, year_quarter
)
SELECT
    TO_CHAR(d, 'YYYYMMDD')::INTEGER AS date_key,
    d::DATE AS full_date,
    EXTRACT(YEAR FROM d)::SMALLINT AS year_num,
    EXTRACT(QUARTER FROM d)::SMALLINT AS quarter_num,
    EXTRACT(MONTH FROM d)::SMALLINT AS month_num,
    TRIM(TO_CHAR(d, 'TMMonth')) AS month_name,
    EXTRACT(WEEK FROM d)::SMALLINT AS week_num,
    EXTRACT(DAY FROM d)::SMALLINT AS day_of_month,
    EXTRACT(ISODOW FROM d)::SMALLINT AS day_of_week,
    TRIM(TO_CHAR(d, 'TMDay')) AS day_name,
    EXTRACT(ISODOW FROM d) IN (6, 7) AS is_weekend,
    TO_CHAR(d, 'YYYY-MM') AS year_month,
    EXTRACT(YEAR FROM d)::TEXT || '-Q' || EXTRACT(QUARTER FROM d)::TEXT AS year_quarter
FROM generate_series('2015-01-01'::DATE, '2027-12-31'::DATE, '1 day'::INTERVAL) AS d
ON CONFLICT (date_key) DO NOTHING;

-- 2. Dimension Clients
CREATE TABLE IF NOT EXISTS mart.dim_customer (
    customer_sk         BIGSERIAL PRIMARY KEY,
    customer_id         BIGINT NOT NULL UNIQUE,
    full_name           VARCHAR(255) NOT NULL,
    email               VARCHAR(255) NOT NULL,
    country_code        VARCHAR(2) NOT NULL,
    city                VARCHAR(100) NOT NULL,
    segment             VARCHAR(30) NOT NULL,
    acquisition_channel VARCHAR(50) NOT NULL,
    signup_date         DATE NOT NULL,
    updated_at          TIMESTAMP NOT NULL
);

-- 3. Dimension Produits (prête pour SCD Type 2 : effective_from / effective_to / is_current)
CREATE TABLE IF NOT EXISTS mart.dim_product (
    product_sk       BIGSERIAL PRIMARY KEY,
    product_id       BIGINT NOT NULL,
    sku              VARCHAR(64) NOT NULL,
    product_name     VARCHAR(200) NOT NULL,
    category_name    VARCHAR(120) NOT NULL,
    subcategory_name VARCHAR(120) NOT NULL,
    cost_price       NUMERIC(10, 2) NOT NULL,
    list_price       NUMERIC(10, 2) NOT NULL,
    status           VARCHAR(20) NOT NULL,
    effective_from   TIMESTAMP NOT NULL DEFAULT '2015-01-01 00:00:00',
    effective_to     TIMESTAMP NOT NULL DEFAULT '9999-12-31 23:59:59',
    is_current       BOOLEAN NOT NULL DEFAULT TRUE
);
CREATE INDEX IF NOT EXISTS idx_dim_product_id_current ON mart.dim_product (product_id, is_current);

-- 4. Dimension Méthode de paiement
CREATE TABLE IF NOT EXISTS mart.dim_payment_method (
    payment_method_sk    SERIAL PRIMARY KEY,
    payment_method_code  VARCHAR(30) NOT NULL UNIQUE,
    payment_method_label VARCHAR(60) NOT NULL
);

INSERT INTO mart.dim_payment_method (payment_method_code, payment_method_label) VALUES
    ('card', 'Carte Bancaire'),
    ('paypal', 'PayPal'),
    ('apple_pay', 'Apple Pay'),
    ('bank_transfer', 'Virement Bancaire'),
    ('unknown', 'Inconnu')
ON CONFLICT (payment_method_code) DO NOTHING;

-- 5. Table de Faits : Commandes (Grain = 1 commande)
CREATE TABLE IF NOT EXISTS mart.fact_orders (
    order_id          BIGINT PRIMARY KEY,
    order_number      VARCHAR(40) NOT NULL,
    date_key          INTEGER NOT NULL REFERENCES mart.dim_date(date_key),
    customer_sk       BIGINT NOT NULL REFERENCES mart.dim_customer(customer_sk),
    payment_method_sk INTEGER NOT NULL REFERENCES mart.dim_payment_method(payment_method_sk),
    order_status      VARCHAR(20) NOT NULL,
    payment_status    VARCHAR(20) NOT NULL,
    shipping_country  VARCHAR(2) NOT NULL,
    shipping_city     VARCHAR(100) NOT NULL,
    carrier           VARCHAR(50),
    delivery_days     NUMERIC(6, 2),
    subtotal_amount   NUMERIC(12, 2) NOT NULL,
    discount_amount   NUMERIC(12, 2) NOT NULL,
    shipping_amount   NUMERIC(10, 2) NOT NULL,
    total_amount      NUMERIC(12, 2) NOT NULL,
    refund_amount     NUMERIC(12, 2) NOT NULL DEFAULT 0,
    is_returned       BOOLEAN NOT NULL DEFAULT FALSE,
    ordered_at        TIMESTAMP NOT NULL
);

-- 6. Table de Faits : Lignes de commande (Grain = 1 article dans une commande)
CREATE TABLE IF NOT EXISTS mart.fact_order_items (
    order_item_id       BIGINT PRIMARY KEY,
    order_id            BIGINT NOT NULL,
    order_number        VARCHAR(40) NOT NULL,
    date_key            INTEGER NOT NULL REFERENCES mart.dim_date(date_key),
    customer_sk         BIGINT NOT NULL REFERENCES mart.dim_customer(customer_sk),
    product_sk          BIGINT NOT NULL REFERENCES mart.dim_product(product_sk),
    payment_method_sk   INTEGER NOT NULL REFERENCES mart.dim_payment_method(payment_method_sk),
    order_status        VARCHAR(20) NOT NULL,
    quantity            INTEGER NOT NULL,
    unit_price          NUMERIC(10, 2) NOT NULL,
    unit_cost           NUMERIC(10, 2) NOT NULL,
    discount_amount     NUMERIC(10, 2) NOT NULL,
    gross_amount        NUMERIC(12, 2) NOT NULL,
    net_amount          NUMERIC(12, 2) NOT NULL,
    cogs_amount         NUMERIC(12, 2) NOT NULL,
    gross_margin_amount NUMERIC(12, 2) NOT NULL,
    ordered_at          TIMESTAMP NOT NULL
);
