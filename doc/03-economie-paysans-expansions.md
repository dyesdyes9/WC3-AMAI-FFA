# 03 — Économie : paysans, mines, fermes, population

## 1. Nombre de paysans

`PeonBuilder` (`common.eai:13495`) appelle `GetPeonTargetForMines`
(`common.eai:10722`), qui interpole **linéairement selon le bois en stock**
entre un maximum et un minimum :

```
w ≤ maximum_peon_wood (200)   → objectif = peon_<n>_mine(s)_number   (max)
w ≥ minimum_peon_wood (2000)  → objectif = min_peon_number_<n>_mine  (min)
entre les deux                → interpolation
```

(`maximum_peon_wood = 200` et `minimum_peon_wood = 2000` viennent de
`GlobalSettings.txt`.)

Le nombre de mines utilisé est plafonné à 3 :
`MineWorkerTargetCount` = `Min(mines, MAX_WORKER_TARGET_MINES = 3)`
(`common.eai:6896`, constante ligne 164). Prendre une 4ᵉ mine n'augmente donc
plus l'objectif de paysans.

### Valeurs livrées (REFORGED)

| Race | 1 mine | 2 mines | 3+ mines |
| --- | --- | --- | --- |
| Night Elf | 11 → 15 | 16 → 20 | **21 → 24** |
| Orc | 8 → 13 | 13 → 18 | **18 → 22** |
| Human | 8 → 14 | 14 → 18 | **19 → 22** |
| Undead | 5 | 10 | **15** |

(lecture : `minimum (bois abondant) → maximum (bois rare)`)

Les wisps et les paysans coûtent 1 point de population pièce, les acolytes 1
également. Donc à 3 mines, une IA Elfe consacre **21 à 24 points de population
sur 100** à l'économie, une Orc ou Humaine 18 à 22, une Mort-Vivante 15.
Pour comparaison, un joueur humain tourne plutôt à 14-16 ouvriers sur 2-3 bases.

L'Undead est à part : ses ghouls bûcherons sont comptés séparément
(`race_has_ghouls`, `ghoul_prio = 250`, `race_min_ghouls` / `race_max_ghouls`),
et la branche `race_has_ghouls` de `GetPeonTargetForMines` renvoie directement
le **minimum**, sans interpolation.

### Pré-réservation à l'expansion

`QueueExpansionPeonsIfNeeded` (`common.eai:10744`) calcule l'objectif pour
`mines + 1` et le pousse dans `pendingExpansionPeons`, repris par
`PeonBuilder` via `Max(peonTarget, pendingExpansionPeons)`. L'IA construit
donc les paysans de la future mine **avant** que celle-ci soit opérationnelle.

### Goblin Shredder

`race_uses_shredder` + `shredder_peon_count = 10` : un shredder compte pour
10 paysans bûcherons et réduit d'autant l'objectif. Acheté quand
`gold/wood > 4`, `gold − wood > 500`, `wood < 550`.

### Affectation or / bois

`universal_peon_assignment` (`common.eai:16294`) répartit en fonction du ratio
or/bois, avec `ver_optimal_gold = 5` paysans par mine comme cible nominale.
Depuis 3.8.0, deux mineurs d'or passent au bois quand `bois < 200` et
`or > 300` (Elfe, Orc, Humain ; l'Undead garde ses deux populations séparées).

## 2. Fermes et plafond de population

`FarmBuilder` (`common.eai:13437`) :

```
si FoodCap() >= ver_food_limit        → ne rien faire
si FoodSpace() <= farm_food2          → 2 fermes
si FoodSpace() <= farm_food           → 1 ferme
```

- `ver_food_limit` = `GetPlayerState(ai_player, PLAYER_STATE_FOOD_CAP_CEILING)`
  → 100 en mêlée standard. **Le plafond de population n'est pas bridé par
  AMAI.**
- `farm_food` vient du profil (colonne « Build Farm at left food », 5 à 8)
- `farm_food2 = −4` chez l'Orc : si la population dépasse déjà la production,
  deux fermes d'un coup
- `max_farms` = `GetMaxFarms()` (`common.eai:10039`) = `ceil(100 / production
  d'une ferme)` → 10 puits de lune, 10 fermes humaines, 13 burrows…
- `race_farms_at_mine = 2` : les 2 premières fermes sont posées à la mine
- `race_build_farms_front` + `race_farms_front_limit` : certaines races posent
  des fermes vers le front
- depuis 3.8.0, `farm_recovery_target` (1 à 3) relance jusqu'à 3 chantiers
  simultanés si des fermes inachevées sont détruites, pendant 60 s

**Conclusion : si l'IA s'arrête à 80 de population, ce n'est pas la faute des
fermes ni du plafond — c'est que sa file de build ne demande plus rien.**
Voir [02 §4](02-production-unites.md) et [05](05-diagnostic-difficulte.md).

## 3. Upkeep

`REFORGED/Upkeep.txt` :

| Palier | Seuil population | Résistance (or) | Temps d'épargne | Mines requises | Revenu |
| --- | --- | --- | --- | --- | --- |
| LOW | 50 | 500 | 30 + rand(0,60) | 2 | ×0,7 |
| HIGH | 80 | 2000 | 100 + rand(0,300) | 2 | ×0,4 |

Mécanique (`common.eai:9758` à `9830`) :

- `CheckUpkeepAllowed` : si la population est **déjà** au-delà du seuil, le
  palier est `ALLOWED` (on ne redescend pas)
- `ApplyUpkeepCheck` : pour franchir un seuil il faut
  **`or total > résistance` OU `mines ≥ mines requises`**.
  Comme les deux paliers demandent 2 mines, une IA à 2 mines ou plus franchit
  librement le seuil 80.
- `ApplyUpkeepSaving` : quand le franchissement est refusé, `total_gold` est
  diminué de la résistance (jusqu'à **2000 or** fictifs) pendant
  `upkeep_save_time` ticks (1 tick = 5 s de jeu, donc 500 à 2000 s pour HIGH).
  L'IA « économise » et ne dépense plus.

Le cas à surveiller est donc l'IA **à une seule mine** : elle se retrouve
bloquée à 80 de population et met de côté 2000 or pendant plusieurs minutes.
`use_linear_upkeep_saving = false` (recommandé, le mode linéaire est documenté
comme contre-productif).

`upkeep_goldchange` sert aussi à `GetGoldIncome` : l'IA sait qu'au-delà de 80
de population son revenu est divisé par 2,5, ce qui pèse sur ses décisions
d'achat.

## 4. Expansions

`ExpansionBuilder` (`common.eai:13537`) :

```
minetimeready =  mines < 2 et temps écoulé > exp_first_time
              ou mines < 3 et temps écoulé > exp_second_time
              ou mines < 4 et attacking_aggression > 0
                            et tirage(0,100) < 42
                            et or > 1000 et bois > 700
```

- `exp_first_time` / `exp_second_time` viennent du **profil** (colonnes 7 et 8
  de `Profiles.txt`), par exemple `Hunter` = −5 et 10, `Crazy_Rusher` = 4 et −8.
  Une valeur négative signifie « très tôt ».
- La table de stratégie a aussi ses propres `expansion time` /
  `second expansion time` (50-80 et 120-160 selon la stratégie).
- **4 mines est le plafond effectif**, et la 4ᵉ exige `attacking_aggression > 0`,
  ce qui est rare puisque la quasi-totalité des profils ont une agressivité
  négative (voir [04](04-decision-attaque.md)). En pratique l'IA se stabilise
  donc à **3 mines**.
- `expansion_radius = 1250` : rayon de vérification des creeps autour d'une mine
- `expansion_taken_radius = 1300` : distance à laquelle un bâtiment ennemi fait
  considérer la mine comme prise
- `race_max_expa_mine_distance = 850` : distance max entre la mine et le
  bâtiment d'expansion

Priorités : `expa_prio = 280` (= paysan), `expa_emergency_prio = 500` (mines
épuisées), `expa_rebuild_prio = 400`.

Modes d'expansion spéciaux, par race (`<Race>/Settings.txt`) :

| Mécanisme | Réglages |
| --- | --- |
| Expansion par objet (Tiny Great Hall…) | `race_item_expansion_available`, `_probability` (75 % chez l'Orc), `_item_id`, `race_item_sale_level` |
| Expansion par Ancient (Elfe) | `race_ancient_expansion_available`, `_probability` (50 %), `_strength` (15) |
| Expansion par milice (Humain) | `race_militia_expansion_available` |
| Expansion par bâtiment-mine (Undead) | `race_uses_mine_expansion` |

## 5. Récapitulatif d'un budget de population type

IA Elfe, palier 3, 3 mines, stratégie `NormalElf` :

| Poste | Population |
| --- | --- |
| Wisps | 21 à 24 |
| 3 héros | 15 |
| Liste de stratégie (3 MG, 7 chasseresses, 6 archers, 4 dryades, 2 chimères, 3 druides/dragon-fée) | ~71 demandés |
| **Total demandé** | **107 à 110** |

Le plafond étant à 100, l'IA ne finit jamais sa liste — donc
`BuildAdaptiveReinforcements` reste bloqué par sa condition 2, et l'armée se
stabilise là où les ressources et les priorités l'ont menée (typiquement
55-65 points de population d'armée réelle, soit « 80 de pop » affichés).
