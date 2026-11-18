# Roadmap d'apprentissage & d'implémentation BI

Objectif : maîtriser la chaîne BI de bout en bout (**OLTP ➔ ETL ➔ Data Warehouse ➔ BI/Restitution**) dans des conditions proches de la production (**10 ans d'historique, millions de lignes**), tout en respectant les bonnes pratiques d'entreprise (DevSecOps, modélisation de Kimball, versionnement Git).

---

## Phase 0 — Socle d'infrastructure & DevSecOps
> **Objectif :** Disposer d'un environnement reproductible, sécurisé et prêt pour le travail collaboratif.

- [x] Déployer PostgreSQL, Apache Hop Web et Metabase via `docker-compose.yml`
- [x] Configurer la connexion MCP entre Metabase et Antigravity
- [x] Externaliser les variables sensibles dans `.env` / `.env.example` et configurer `.gitignore`
- [x] Initialiser la documentation (`README.md`, `DOC.md`, `ROADMAP.md`) et le skill de synchronisation documentaire
- [x] Vérifier la création des 3 bases dans PostgreSQL (`ecommerce_oltp`, `dwh`, `metabase_app`)

**Notions acquises :** Isolation réseau Docker, *healthchecks*, séparation des secrets (`.env`), séparation OLTP / DWH / App DB.

---

## Phase 1 — Base Source OLTP E-Commerce (Workspace Laravel séparé)
> **Objectif :** Simuler une vraie base de production e-commerce sur **10 ans** avec un volume réaliste et massif (plusieurs millions de lignes).

- [x] Créer le projet Laravel dans un dépôt/workspace frère (`../ecommerce-oltp`) et le connecter à `ecommerce_oltp` (`127.0.0.1:5433`)
- [x] Concevoir le schéma relationnel OLTP complet via migrations Laravel :
  - `users` (clients, dates d'inscription, pays/ville, segment)
  - `categories` (hiérarchie catégorie / sous-catégorie)
  - `products` (SKU, coût d'achat, prix catalogue, marge, statut)
  - `orders` (statuts `completed`, `cancelled`, `refunded`, `pending`, remises, frais de port, `created_at`, `updated_at`)
  - `order_items` (quantité, prix unitaire facturé au moment de l'achat, coût unitaire)
  - `payments` (méthode de paiement, statut, montant, date de transaction)
  - `shipments` / `returns` (transporteur, délais de livraison, retours et motifs)
- [ ] Créer des Seeders réalistes sur **10 ans** :
  - Croissance progressive du volume d'année en année
  - Saisonnalité (pics en novembre/décembre, soldes)
  - Comportements clients réalistes (clients récurrents, taux d'annulation/retour)
  - Imperfections volontaires réalistes (casse mixte, espaces superflus, quelques champs optionnels `NULL`) pour exercer le nettoyage ETL
- [ ] Mettre en place un **script d'exécution massif** (chunked bulk insert / orchestrateur Python ou Artisan) pour générer **1M+ à plusieurs millions de lignes** sans saturer la RAM
- [ ] Valider les volumes générés et la cohérence temporelle sur 10 ans

**Notions apprises :** Modélisation OLTP (3NF), génération de données réalistes à grande échelle, performances d'insertion PostgreSQL.

---

## Phase 2 — Architecture & Modélisation du Data Warehouse (`dwh`)
> **Objectif :** Concevoir la base analytique OLAP selon l'architecture **Médaillon** et le modèle en étoile de **Kimball**.

- [ ] Créer les 3 schémas dans `dwh` via scripts SQL versionnés (`sql/dwh/`) :
  - `raw` *(Bronze)* : miroir brut des extractions OLTP + métadonnées d'ingestion (`_ingested_at`)
  - `staging` *(Silver)* : données nettoyées, typées, dédupliquées, règles métier appliquées
  - `mart` *(Gold)* : modèle en étoile prêt pour la BI
- [ ] Créer la table **`mart.dim_date`** couvrant les 10+ années (année, trimestre, mois, semaine, jour férié/week-end, saison)
- [ ] Concevoir les dimensions (`dim_customer`, `dim_product`, `dim_payment_method`, `dim_geography`) avec clés de substitution (*surrogate keys*)
- [ ] Concevoir les tables de faits (`fact_order_items`, `fact_orders`, `fact_returns`) avec granularité claire (*grain*)
- [ ] Gérer au moins une **SCD (Slowly Changing Dimension)** (ex. suivi des changements de prix ou de catégorie produit dans le temps)

**Notions apprises :** OLTP vs OLAP, granularité d'une table de faits, clés naturelles vs *surrogate keys*, Star Schema, SCD Type 1 & Type 2.

---

## Phase 3 — Pipelines ETL & Orchestration (Apache Hop)
> **Objectif :** Construire des flux robustes, idempotents et paramétrés dans Apache Hop (`http://localhost:8081`).

- [ ] Configurer les connexions PostgreSQL dans Hop en utilisant uniquement les variables d'environnement (`${OLTP_DB_HOST}`, `${DW_DB_NAME}`, etc.)
- [ ] **Pipeline 1 (`OLTP ➔ raw`)** : extraction initiale (*full load*) puis **chargement incrémental** basé sur `updated_at` (table de watermark / suivi d'exécution)
- [ ] **Pipeline 2 (`raw ➔ staging`)** : nettoyage des chaînes, normalisation des emails/pays, gestion des valeurs nulles, déduplication et calcul des colonnes dérivées (marge unitaire, délai de livraison)
- [ ] **Pipeline 3 (`staging ➔ mart`)** : alimentation des dimensions (*Dimension Lookup / Update*) puis des tables de faits
- [ ] **Workflow d'orchestration (`.hwf`)** : enchaîner les pipelines dans le bon ordre, gérer les erreurs et journaliser les exécutions
- [ ] Tester l'**idempotence** (relancer 2 fois le workflow sans créer de doublons)

**Notions apprises :** Pipelines vs Workflows, extraction incrémentale (CDC/Watermark), *upsert*, idempotence, gestion des logs et erreurs ETL.

---

## Phase 4 — Passage à l'échelle, Performance & Qualité des Données
> **Objectif :** Optimiser le DWH et l'ETL pour supporter plusieurs millions de lignes et garantir la fiabilité des chiffres.

- [ ] Monter le volume de `ecommerce_oltp` à **plusieurs millions de lignes** et mesurer les temps d'exécution ETL
- [ ] Optimiser Apache Hop (taille des lots *Commit size*, pagination/streaming SQL, mémoire JVM)
- [ ] Optimiser PostgreSQL sur `mart` :
  - Index adaptés (B-Tree sur clés étrangères, BRIN sur dates de faits)
  - Analyse de plans d'exécution (`EXPLAIN ANALYZE`)
  - Partitionnement annuel de `fact_order_items` / `fact_orders` ou vues matérialisées pour les agrégats lourds
- [ ] Implémenter des **tests de qualité & réconciliation** (comparaison des totaux OLTP vs `mart`, détection de lignes orphelines, montants aberrants)

**Notions apprises :** Tuning PostgreSQL analytique, partitionnement, indexation, contrôle qualité (*Data Quality*), réconciliation financière.

---

## Phase 5 — Couche Sémantique & Dashboards (Metabase)
> **Objectif :** Transformer les données du `mart` en indicateurs métier fiables et tableaux de bord actionnables.

- [ ] Configurer la gouvernance dans Metabase : masquer `raw` et `staging`, n'exposer que `mart`, configurer les types sémantiques (devises, dates, FK)
- [ ] Définir des **Modèles & Métriques** réutilisables (CA Brut, CA Net hors retours/annulations, Marge Brute, Panier Moyen AOV, LTV, Taux de retour)
- [ ] Construire **3 dashboards orientés métier** :
  1. **Direction / Exécutif** : CA, marge, croissance YoY sur 10 ans, saisonnalité, top pays/catégories
  2. **Catalogue & Produits** : top/flop produits, marges par catégorie, impact des remises, taux de retour
  3. **Clients & Rétention** : nouveaux vs récurrents, analyse de cohortes, fréquence d'achat, LTV
- [ ] Ajouter des filtres interactifs (période, catégorie, pays, statut) et vérifier la fluidité sous forte volumétrie

**Notions apprises :** Couche sémantique, calcul de KPIs sans biais, analyse de cohortes, storytelling visuel BI.

---

## Phase 6 — Packaging Portfolio & Préparation Freelance
> **Objectif :** Rendre le projet présentable à un client ou recruteur en 5 minutes.

- [ ] Finaliser `README.md` et `DOC.md` avec captures d'écran (pipelines Hop, schémas, dashboards Metabase) et benchmarks de performance
- [ ] Rédiger un guide de démo reproductible (`scripts/` + `docker compose up -d`)
- [ ] Préparer la fiche "Étude de cas" (Problématique ➔ Architecture ➔ Défis techniques sur 10 ans / millions de lignes ➔ Résultats)
