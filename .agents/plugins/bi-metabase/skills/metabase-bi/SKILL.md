---
name: metabase-bi
description: Guide et contexte de la stack BI locale (PostgreSQL Data Warehouse, Apache Hop Web, Metabase et serveur MCP Metabase). À activer pour travailler sur les pipelines Hop, la base dwh ou les analyses Metabase.
---

# Stack BI Locale & Metabase MCP

Ce projet contient un environnement BI complet orchestré par `docker-compose.yml` :

- **PostgreSQL (`postgres-dw`)** :
  - Port hôte : `5433` (interne Docker : `5432`)
  - Base Data Warehouse : `dwh` (utilisateur `admin` / mot de passe `admin`, ou `postgres` / `postgres`)
  - Base interne Metabase : `metabase_app`
- **Apache Hop Web (`hop-web`)** : `http://localhost:8081` (`admin` / `admin`), projet `bi-learn` dans `./hop-projects/bi-learn`
- **Metabase (`metabase`)** : `http://localhost:3000`

## Connexion MCP à Metabase

Le serveur MCP officiel intégré à Metabase (`v0.64.6`) est configuré sur :
`http://localhost:3000/api/metabase-mcp`

### Prérequis côté Metabase
1. Dans Metabase, vérifier que le serveur MCP est activé dans **Paramètres → Admin → AI → MCP → Settings**.
2. Lors de la première connexion MCP, suivre le flux OAuth dans le navigateur pour autoriser Antigravity avec ton compte Metabase.
3. Si la base `dwh` n'est pas encore ajoutée dans Metabase, l'ajouter via **Admin → Bases de données** avec `host: postgres-dw`, `port: 5432`, `db: dwh`, `user: admin`, `password: admin`.
