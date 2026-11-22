# 01 — Vue d'ensemble de l'architecture

## Où vit quoi

| Rôle | Fichier |
| --- | --- |
| Moteur AMAI (tout le cerveau) | `common.eai` (~600 Ko, le gros du travail) |
| Boucles par race, boucle d'attaque | `races.eai` |
| Logique « Commander » côté carte | `Blizzard.eai` |
| Comportements périodiques isolés | `Jobs/*.eai` (HARASS, ARMY_TRACK, TOWER_RUSH, HARVEST_CHECK…) |
| Réglages globaux par version | `REFORGED/GlobalSettings.txt`, `TFT/…`, `ROC/…` |
| Personnalités | `REFORGED/Profiles.txt` |
| Réglages par race | `REFORGED/<Race>/Settings.txt` |
| Table des stratégies | `REFORGED/<Race>/Strategy.txt` |
| Ordres de construction | `REFORGED/<Race>/BuildSequence.ai` |
| Seuils d'upkeep | `REFORGED/Upkeep.txt` |
| Agressivité selon race ennemie | `REFORGED/<Race>/RaceAggression.txt` |
| Agressivité selon population | `REFORGED/AddedAggression.txt` |
| Données d'unités (contre-quoi, siège, tour…) | `REFORGED/StandardUnits.txt` |
| Sortie compilée (ne pas éditer) | `Scripts/REFORGED/*.ai`, `Blizzard.j` |

Les `#INCLUDETABLE <$VER$\Fichier.txt>` dans les `.eai` sont expansés par
`ejass.pl` au build : les `.txt` ne sont pas lus à l'exécution, ils sont
**compilés en dur** dans les `.ai`. Changer un `.txt` impose donc de relancer
`AMAI-Build.bat`.

## Les boucles principales

AMAI n'a droit qu'à un nombre fixe de threads JASS. Tout tourne donc dans
quelques boucles qui se réveillent périodiquement, plus une file de « jobs »
priorisée dans le temps (`Jobs/`, ordonnancée par la *Time Priority Queue* de
`common.eai`).

### 1. Boucle de construction — `OneBuildLoopAM` (`common.eai:14038`)

À chaque passe :

1. `FarmBuilder()` — fermes / burrows / puits de lune / ziggourats
2. `PeonBuilder()` — paysans et bûcherons
3. `ExpansionBuilder()` — nouvelles mines
4. `HeroReviver()` — résurrection des héros
5. calcul de `total_gold`, `total_wood`, `total_food` disponibles
6. parcours de la **file de build** triée par priorité, chaque entrée passe par
   `StartUnitAM` / `StartUpgradeAM`
7. `BuildAdaptiveReinforcements()` — renforts avec la population restante
8. incrémentation de la priorité des éléments non construits (`prio_t_inc`)

La file de build est remplie par la stratégie courante (voir
[02-production-unites.md](02-production-unites.md)).

### 2. Boucle d'attaque — `races.eai:607`

```
boucle:
    HealArmy()                                  // soigne l'armée
    creeping_only = AwaitMeleeHeroesAM()        // attend qu'un héros soit dispo
    attendre GetOwnStrength() >= minimum_attack_strength
    setup_force(false)                          // forme le groupe d'attaque
    universal_attack_sequence()                 // décide et exécute l'attaque
```

`universal_attack_sequence` (`common.eai:16212`) appelle
`SingleMeleeAttackAM` (`common.eai:15600`) qui est **l'arbre de décision
complet** : commandes du Commander, tower rush, expansion, cible alliée,
mega-target, cible joueur, sinon creep. Détail en
[04-decision-attaque.md](04-decision-attaque.md).

### 3. Jobs périodiques

Chaque fichier de `Jobs/` est un comportement indépendant réveillé par la file
de temps. Les plus importants pour le ressenti en jeu :

- `ARMY_TRACK.eai` — suit les armées ennemies, calcule les menaces sur les villes
- `HARASS.eai` — petits groupes de harcèlement (paysans, expansions)
- `RETREAT_CONTROL.eai` — décide de fuir un combat
- `SEND_HOME.eai` — renvoie les unités blessées à la base
- `MICRO_UNITS.eai`, `MICRO_HERO.eai`, `FOCUSFIRE_CONTROL.eai` — micro en combat
- `TOWER_RUSH.eai` / `TOWER_RUSH_CHECK.eai` — tower rush d'ouverture
- `HARVEST_CHECK.eai` — réaffectation des récolteurs

## Échelle de « force » (strength)

Toute la logique d'attaque et de fuite repose sur une unité de mesure unique.

- Unité normale : `(population + niveau) / 2` arrondi
  (`GetUnitStrengthEx`, `common.eai:5968`)
  → un grunt ≈ 3, un tauren ≈ 5, un archer ≈ 2
- Creep : son niveau seul
- Héros : `2 + 0,5 × (niveau − 1) + bonus de compétences`
  (`GetHeroStrength`, `common.eai:5925`), le bonus des sorts à mana étant
  multiplié par la fraction de mana disponible
- Tour : `(0 + niveau) / 2`, soit ~2 par tour
- **Une unité en soin (`unit_healing`) compte pour 0.**

Une armée de 75 points de population vaut donc grossièrement 50 à 75 de force.
Ordre de grandeur à garder en tête : les seuils du code (60, 100, etc.) sont
dans cette échelle, pas en population.

`GetOwnStrength` (`common.eai:6342`) exclut paysans, héros (comptés à part),
bâtiments et unités en soin.

`GetUnexactPlayerStrength` (`common.eai:6052`) est l'estimation que l'IA fait
d'un adversaire : exacte en **Insane**, bruitée de `± uncertainty/50` en Normal
et Easy (`uncertainty` vient du profil, 4 à 12).
