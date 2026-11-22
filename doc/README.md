# Documentation interne AMAI

Notes de reverse-engineering du fonctionnement d'AMAI, écrites au fil des
investigations pour ne pas avoir à refaire le travail de lecture du code à
chaque fois.

Tous les numéros de ligne renvoient aux **sources** (`.eai`, `.ai`, `.txt` des
dossiers de version), jamais au dossier généré `Scripts/`.

## Sommaire

| Fichier | Contenu |
| --- | --- |
| [01-vue-ensemble.md](01-vue-ensemble.md) | Architecture : où vit quoi, les grandes boucles de l'IA |
| [02-production-unites.md](02-production-unites.md) | Choix de stratégie, tables de build, file de production, contre-unités adaptatives |
| [03-economie-paysans-expansions.md](03-economie-paysans-expansions.md) | Nombre de paysans, mines, fermes, upkeep, plafond de population |
| [04-decision-attaque.md](04-decision-attaque.md) | Quand l'IA attaque, qui elle choisit, pourquoi elle reste chez elle |
| [05-diagnostic-difficulte.md](05-diagnostic-difficulte.md) | Analyse « l'IA est devenue plus facile » : causes identifiées et leviers de réglage |
| [06-conception-ia-ffa.md](06-conception-ia-ffa.md) | Conception d'une IA spécialisée FFA : recherche, diagnostic, valeurs de tables proposées |

## Rappels de build

```powershell
.\AMAI-Build.bat
```

```powershell
.\AMAI-Deploy.bat "<carte.w3x ou dossier>" 1
```

Voir [AMAI-NOTES-FR.md](../AMAI-NOTES-FR.md) pour l'installation locale.
