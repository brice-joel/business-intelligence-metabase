# Documentation Technique — Plateforme BI E-Commerce

Ce document centralise l'architecture, le dictionnaire de données, les flux ETL et les décisions techniques du projet. Il est mis à jour progressivement au fil des phases décrites dans [ROADMAP.md](./ROADMAP.md).

---

## 1. Architecture & Services Docker

L'infrastructure repose sur [docker-compose.yml](./docker-compose.yml) sur un réseau bridge dédié (`bi-net`). Les identifiants sensibles sont injectés via `.env` (non versionné, basé sur [.env.example](./.env.example)).

| Service | Conteneur | Image | Rôle | Volume(s) persistant(s) |
| :--- | :--- | :--- | :--- | :--- |
| PostgreSQL | `postgres-dw` | `postgres:16-alpine` | Héberge `ecommerce_oltp`, `dwh` et `metabase_app` | `pg-data` |
| Apache Hop Web | `hop-web` | `apache/hop-web:2.20.0` | Interface web ETL et exécution du projet `bi-learn` | `hop-config`, `hop-audit`, `./hop-projects`, `./hop-jdbc` |
| Metabase | `metabase` | `metabase/metabase:v0.64.6` | Serveur BI, couche sémantique, dashboards & serveur MCP | Stockage applicatif dans `metabase_app` |

### Intégration IA / MCP
- Metabase expose son serveur MCP natif sur `/api/metabase-mcp`.
- La configuration globale Antigravity pointe vers cet endpoint afin de permettre l'exploration des bases et métadonnées directement depuis l'IDE.
- Le skill local `metabase-bi` fournit le contexte de la stack BI aux sessions de travail.

---

## 2. Bases de données & Dictionnaire de données

### 2.1 Base source OLTP (`ecommerce_oltp`)
Schéma applicatif géré par migrations Laravel dans `../ecommerce-oltp/database/migrations/`.

| Table | Description | Clé primaire | Colonne incrémentale | Volumétrie cible |
| :--- | :--- | :--- | :--- | :--- |
| `users` | Clients (pays, ville, segment `standard`/`vip`/`b2b`, canal d'acquisition) | `id` | `updated_at` | 100k – 500k |
| `categories` | Hiérarchie catégories / sous-catégories (`parent_id`) | `id` | `updated_at` | ~40 |
| `products` | Catalogue produits (`sku`, `cost_price`, `list_price`, `status`) | `id` | `updated_at` | ~500 |
| `orders` | Commandes clients (`order_number`, `status`, montants, `ordered_at`) | `id` | `updated_at` | 100k ➔ 2M+ |
| `order_items` | Lignes de commande (`quantity`, `unit_price`, `unit_cost`, `line_total`) | `id` | `updated_at` | 250k ➔ 5M+ |
| `payments` | Paiements associés aux commandes (`payment_method`, `status`, `paid_at`) | `id` | `updated_at` | 100k ➔ 2M+ |
| `shipments` | Expéditions (`carrier`, `status`, `shipped_at`, `delivered_at`) | `id` | `updated_at` | ~90k ➔ 1.8M+ |
| `returns` | Retours & remboursements (`reason`, `refund_amount`, `returned_at`) | `id` | `updated_at` | ~7k ➔ 150k+ |

### 2.2 Data Warehouse (`dwh`)
Le Data Warehouse est organisé en 3 schémas :
- **`raw`** : réplication brute des tables sources + horodatage d'ingestion (`_ingested_at`).
- **`staging`** : données nettoyées, normalisées et dédupliquées.
- **`mart`** : modèle dimensionnel en étoile (faits et dimensions) consommé par Metabase.

#### Tables `mart` (Star Schema)
Définies dans [03_mart_star_schema.sql](./sql/dwh/03_mart_star_schema.sql).

| Table | Type (Fait / Dimension) | Grain / Clé | Description |
| :--- | :--- | :--- | :--- |
| `mart.dim_date` | Dimension | `date_key` (`YYYYMMDD`) | Calendrier pré-généré de 2015 à 2027 (trimestre, semaine, week-end) |
| `mart.dim_customer` | Dimension | `customer_sk` (`customer_id`) | Clients nettoyés (pays, ville, segment, canal d'acquisition) |
| `mart.dim_product` | Dimension (SCD2) | `product_sk` (`product_id`) | Catalogue avec hiérarchie catégorie/sous-catégorie et suivi historique |
| `mart.dim_payment_method` | Dimension | `payment_method_sk` | Référentiel des moyens de paiement |
| `mart.fact_orders` | Fait | `order_id` (1 commande) | Montants, remises, livraison (`delivery_days`), retours/remboursements |
| `mart.fact_order_items` | Fait | `order_item_id` (1 article) | Quantités, CA brut/net, coût d'achat (`cogs_amount`) et marge brute |

---

## 3. Catalogue ETL Apache Hop (`hop-projects/bi-learn`)

> *À compléter lors de la Phase 3.*

### 3.1 Pipelines (`.hpl`)
| Fichier | Couche source ➔ cible | Stratégie (Full / Incrémental / Upsert) | Notes |
| :--- | :--- | :--- | :--- |
| *(À créer)* | | | |

### 3.2 Workflows (`.hwf`)
| Fichier | Fréquence / Déclenchement | Rôle |
| :--- | :--- | :--- |
| *(À créer)* | | |

---

## 4. Couche Sémantique & KPIs Metabase

> *À compléter lors de la Phase 5.*

| Indicateur (KPI) | Définition métier | Formule / Règle SQL | Dashboard associé |
| :--- | :--- | :--- | :--- |
| *(À définir)* | | | |

---

## 5. Journal des décisions d'architecture (ADR)

| Date | Décision | Contexte & Justification |
| :--- | :--- | :--- |
| 2026-11-18 | **Séparation en 2 dépôts (OLTP Laravel vs Plateforme BI)** | Reproduction fidèle d'un environnement d'entreprise : découplage total entre l'application transactionnelle et la chaîne analytique. |
| 2026-11-18 | **Architecture Médaillon (`raw` / `staging` / `mart`) + Kimball** | Traçabilité des données brutes, isolation des règles de nettoyage, et modèle en étoile optimisé pour Metabase. |
| 2026-11-18 | **Port hôte PostgreSQL `5433` et Hop Web `8081`** | Évite les conflits avec des services déjà actifs sur les ports `5432` et `8080` de la machine hôte, tout en gardant les ports standards sur le réseau interne Docker. |
| 2026-11-18 | **Externalisation des secrets via `.env` + script `01-init.sh`** | Bonnes pratiques DevSecOps avant publication sur GitHub : aucun mot de passe en clair dans `docker-compose.yml` ni dans les scripts d'initialisation. |
