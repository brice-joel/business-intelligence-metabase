---
name: bi-docs-sync
description: >-
  Procédure de mise à jour automatique de DOC.md, ROADMAP.md et README.md après
  toute modification significative du projet BI (architecture Docker, schémas SQL,
  base OLTP, pipelines Apache Hop, dashboards Metabase ou avancement d'étape).
---

# Synchronisation automatique de la documentation BI

Utilise ce skill chaque fois qu'une étape de la roadmap progresse ou qu'un composant technique est ajouté/modifié.

## Fichiers maintenus
1. `ROADMAP.md` — Suivi des phases et cases à cocher (`[ ]` ➔ `[x]`).
2. `DOC.md` — Référentiel technique (services, tables OLTP/DWH, pipelines Hop, KPIs Metabase, ADR).
3. `README.md` — Vitrine GitHub (architecture, démarrage rapide, structure du dépôt).

## Règles de mise à jour

1. **Ne jamais exposer de secrets** :
   - N'écris jamais de mots de passe réels, tokens ou clés API dans `DOC.md`, `ROADMAP.md` ou `README.md`.
   - Référence uniquement les noms de variables d'environnement (ex. `${POSTGRES_PORT}`, `${DW_DB_NAME}`).
2. **Mettre à jour `ROADMAP.md`** :
   - Coche `[x]` uniquement les tâches réellement implémentées et vérifiées.
   - Si une nouvelle sous-tâche importante apparaît (ex. un script Python de seeding ou un nouvel index), ajoute-la proprement dans la phase correspondante.
3. **Mettre à jour `DOC.md`** :
   - **Nouveau schéma / table SQL** : ajouter ou mettre à jour le tableau dans la section *2. Bases de données & Dictionnaire de données*.
   - **Nouveau pipeline `.hpl` ou workflow `.hwf`** : documenter son nom, sa source/cible et sa stratégie (full, incrémental, upsert) dans la section *3. Catalogue ETL Apache Hop*.
   - **Nouveau KPI / dashboard Metabase** : documenter sa définition métier et sa règle de calcul dans la section *4. Couche Sémantique & KPIs Metabase*.
   - **Choix technique structurant** : ajouter une ligne datée dans la section *5. Journal des décisions d'architecture (ADR)*.
4. **Mettre à jour `README.md`** :
   - Actualiser l'arborescence ou les instructions de démarrage uniquement si de nouveaux dossiers majeurs, services ou commandes d'exécution sont ajoutés.

## Validation avant de clore la tâche
- Vérifie que les liens Markdown relatifs (`./DOC.md`, `./ROADMAP.md`, `./sql/...`) pointent vers des fichiers existants.
- Vérifie qu'aucun secret de `.env` n'a été copié dans la documentation.
