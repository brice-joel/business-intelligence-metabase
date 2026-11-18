# Règles du projet BI

- **Langue & pédagogie** : Répondre en français, de manière claire et structurée, en expliquant le *pourquoi* des choix BI (OLTP vs OLAP, Kimball, qualité des données, performance).
- **Sécurité (DevSecOps)** : Ne jamais écrire de mots de passe, tokens ou clés réelles dans `docker-compose.yml`, les scripts SQL/Python, les pipelines Hop ou la documentation Markdown. Toujours utiliser `.env` (non commité) et `.env.example`.
- **Documentation vivante** : Après toute modification significative (infrastructure Docker, création/modification de tables SQL, pipelines/workflows Apache Hop, métriques/dashboards Metabase, scripts d'automatisation ou validation d'une étape), appliquer le skill `bi-docs-sync` (`.agents/skills/bi-docs-sync/SKILL.md`) pour maintenir `ROADMAP.md`, `DOC.md` et `README.md` à jour.
- **Exactitude** : Ne marquer une case comme terminée (`[x]`) dans `ROADMAP.md` qu'après vérification réelle.
