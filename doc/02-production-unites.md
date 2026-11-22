# 02 — Comment l'IA choisit et produit ses unités

## 1. Le choix de la stratégie

Chaque race a une table `REFORGED/<Race>/Strategy.txt`, une ligne par
stratégie. Exemple Orc : `NormalOrc`, `FastSh`, `WyvSh`, `HHunters`,
`Raiders`, `GruntCatapults`, `HeadCatapults`, `Wyvern`, `BarrackMix`,
`BestiaryMix`, `AntiPierce`, `AntiAir`, `OAntiTower`, `VersusHuman`,
`VersusUndead`, `VersusElf`.

Colonnes importantes :

| Colonne | Effet |
| --- | --- |
| `key_building1/2`, `key_upgrade1/2`, `key_unit` | Si l'IA possède déjà ces bâtiments / améliorations / unités, la stratégie gagne des points (`kb_add1..4`, `ku_add1..3`, `fav_unit_add` dans `Settings.txt`) |
| `beginning_strat` | La stratégie peut être choisie en ouverture |
| `strat_minimum_time` | Durée minimale avant de pouvoir changer (en secondes / 6) |
| `main_strategy_tier` | Palier « naturel ». Bonus `strategy_tier_bonus = 22` si l'IA est à ce palier |
| `base rp` | Points de base |
| `ally / 1on1 / FFA / random enemy bonus` | Bonus selon le format de partie |
| `ELF/HUMAN/ORC/UNDEAD enemy bonus` | Bonus selon la race adverse |
| `anti air`, `anti casters`, `anti towers`, `anti piercing`, … | Notes de contre, confrontées à la composition ennemie réelle |
| `expansion time`, `second expansion time` | Décalage d'expansion propre à la stratégie |
| `first/second/third hero bonus` | Priorité des héros |
| `enemy_<RACE> add agg t1/t2/t3` | Agressivité ajoutée face à telle race, par palier |

Le score final (`rp_strat[]`) est normalisé par `rp_strat_normal = 250`
(GlobalSettings). Un changement n'a lieu que si la nouvelle stratégie dépasse
l'actuelle d'un facteur `strategy_change_threshold = 1.05`, et la stratégie en
cours reçoit en plus `strat_food_persistence × population actuelle` (3 × food
chez l'Orc) — **plus l'armée est grosse, plus l'IA refuse de changer de
stratégie.** D'où l'impression que « elle fait toujours la même armée » :
une fois à 60-80 de population, le bonus de persistance est de 180-240 points,
ce qui dépasse l'écart entre deux stratégies.

`relevant_strat_change_number = 2` : seules les 2 meilleures stratégies sont
candidates lors d'un changement.

Pour tester, `debug_strategy` dans `<Race>/Settings.txt` verrouille la race sur
un numéro de stratégie (`-1` = libre).

## 2. Les ordres de construction

`REFORGED/<Race>/BuildSequence.ai` contient, pour chaque stratégie :

- `init_strategy_<Nom>` — exécuté une fois au passage à cette stratégie
  (blocs de prérequis, groupes de harcèlement)
- `build_sequence_<Nom>` — réexécuté à chaque passe, avec un `if tier == 3 /
  elseif tier == 2 / else`

Plus deux fonctions globales communes à toutes les stratégies de la race :
`global_init_strategy` et `global_build_sequence`.

### Primitives

| Appel | Sens |
| --- | --- |
| `BuildUnit(qty, unit, prio)` | « je veux au total `qty` de cette unité », à la priorité `prio` |
| `BuildUpgr(level, upgrade, prio)` | améliorations |
| `BuildItem(qty, item, prio)` | achats en boutique |
| `BuildAtMine` / `BuildFront` / `DefendTownsDone` | même chose avec un emplacement imposé |
| `BasicExpansionAM(cond, hall, prio)` | expansion conditionnelle |
| `SetBuildReact(food, min1, u1, min2, u2, enemy_str, s1, s2, prio)` | répartit `food` points de population entre `u1` et `u2` selon la force ennemie mesurée |
| `DynamicBuildUnit(prio)` | les contre-unités (voir §4) |
| `AddHarass(groupe, qty, unit)` | réserve des unités pour un groupe de harcèlement |

`qty` est **un objectif cumulé**, pas un incrément : `BuildUnit(6, uGRUNT, 40)`
signifie « avoir 6 grunts », et l'IA reconstruit jusqu'à ce total quand ils
meurent.

### Exemple — `NormalOrc`, palier 3 (`Orc/BuildSequence.ai:337`)

```
hero[1] 140 / hero[2] 130 / hero[3] 130
6 GRUNT 40        4 TAUREN 44       4 WYVERN 46
2 BATRIDER 48     4 RAIDER 44       4 HEAD_HUNTER 40
1 KODO_BEAST 50   4 SHAMAN 44       2 SPIRIT_WALKER 50
2 CATAPULT 48     2 WITCH_DOCTOR 60
```

### Exemple — `NormalElf`, palier 3 (`Elf/BuildSequence.ai:347`)

```
3 MOUNTAIN_GIANT 60   7 HUNTRESS 50   6 ARCHER 54   4 DRYAD 58
1 DRUID_CLAW 64       1 FAERIE_DRAGON 64   1 DRUID_TALON 64   2 CHIMAERA 62
```

### Unités de base devenues obsolètes — `TierObsolete.txt`

Les listes de palier 3 des tables continuent de demander 6 grunts,
7 chasseresses, 6 archères… et comme `qty` est un objectif cumulé, tuer ces
unités déclenchait leur reconstruction jusqu'à la fin de la partie.

Un plafond central corrige cela, piloté par `<VERSION>/TierObsolete.txt` :

```
Unit	From tier	Max allowed
GRUNT	3	2
HEAD_HUNTER	3	4
BERSERKER	3	4
FOOTMAN	3	0
RIFLEMAN	3	4
ARCHER	3	4
HUNTRESS	3	2
```

« À partir de ce palier, ne jamais dépasser ce nombre de cette unité. »
Le tableau est chargé dans `InitArrays` (`common.eai:3417`) vers
`obsolete_from_tier[]` / `obsolete_allowed[]`, et appliqué dans **une seule
fonction**, `BlockListCheck` (`common.eai:10883`) :

```jass
if obsolete_from_tier[t] > 0 and tier >= obsolete_from_tier[t] then
  set max_qty = Min(max_qty, obsolete_allowed[t])
endif
```

`BlockListCheck` est le point de passage commun de tous les consommateurs, ce
qui donne un comportement cohérent sans toucher aux tables de stratégie :

| Appelant | Effet du plafond |
| --- | --- |
| Boucle de build (`common.eai:13929`) | la file ne produit plus au-delà du plafond |
| `AdaptiveCandidateValid` (`:11382`) | l'unité cesse d'être candidate comme contre-unité |
| `AdaptiveAllowedTarget` (`:11386`) | plus de population réservée pour elle |
| Garde de `BuildAdaptiveReinforcements` (`:13828`) | une fois le plafond atteint, la garde ne se déclenche plus → la population libérée part en renforts |

Ce dernier point est important : le plafond ne réduit pas l'armée, il
**redirige** la population. Les archères coupées ne laissent pas un trou, elles
financent les unités avancées de la stratégie puis les renforts adaptatifs.

Deux unités de base sont volontairement **absentes** du tableau :

- **GHOUL** (Mort-Vivant) — ce sont aussi les bûcherons. Les plafonner
  étranglerait l'économie de bois (`race_min_ghouls` / `race_max_ghouls`
  passent par le même `BuildUnit`).
- **CRYPT_FIEND** (Mort-Vivant) — seule unité terrestre anti-air de la race, et
  les sources la donnent comme la meilleure unité de palier 1 en fin de partie.

L'allocation de 4 pour **ARCHER** n'est pas un arbitrage de goût : les
cavaliers d'hippogriffe ont `needed2 = ARCHER` dans `StandardUnits.txt`, et les
prérequis sont auto-commandés par `SetBuildDependency` (`common.eai:11024`). Un
plafond à 0 rendrait les cavaliers d'hippogriffe impossibles à produire, donc
casserait `HippoChim`, qui est l'une des meilleures stratégies elfes en FFA.

Les paires base → avancée de `<Race>/Settings.txt` (`race_simple_melee` /
`race_advanced_melee`) confirment ce découpage : FOOTMAN→KNIGHT, GRUNT→TAUREN,
ARCHER→DRUID_CLAW, GHOUL→ABOMINATION.

Pour ajuster : éditer `TierObsolete.txt`, pas les blocs `tier == 3`. Le fichier
existe dans les trois dossiers de version (`BERSERKER` est absent de celui de
ROC, cette unité n'existant pas dans cette version).

## 3. La file de build et les priorités

`StartUnitAM` (`common.eai:12690`) traite une entrée :

1. si `TownCountTown(unit) >= qty` → `BUILT_ALL`, rien à faire
2. calcule `afford_gold`, `afford_wood`, `afford_food` et prend le minimum
3. si `food_cost > total_food` → `CANNOT_BUILD` (on **saute** l'entrée au lieu
   de bloquer la file)
4. `ApplyUpkeepCheck` limite la quantité si franchir le palier d'upkeep n'est
   pas autorisé (voir [03](03-economie-paysans-expansions.md))
5. si on ne peut financer même 1 unité → `NOT_ENOUGH_RES`, ce qui **bloque la
   suite de la file** (l'IA met de l'argent de côté)

Priorités de référence (Orc, `Settings.txt`) :

| Élément | Priorité |
| --- | --- |
| Ferme / burrow | `farm_prio` = 400 |
| Paysan | `peon_prio` = 280 |
| Expansion | `expa_prio` = 280, urgence 500, reconstruction 400 |
| Héros | 120 à 150 |
| Unités de combat | 35 à 65 |
| Améliorations | 35 à 75 |

Donc : **fermes et paysans passent toujours avant l'armée.** Ce n'est pas un
bug, mais c'est le mécanisme qui fait que 20 paysans sont bâtis avant les
dernières unités de la liste.

`prio_t_inc = 1` : chaque passe de la boucle augmente de 1 la priorité de ce
qui n'a pas pu être construit, ce qui évite les famines éternelles.
`build_array_reset_time = 100` (× 5 s) remet la file à zéro périodiquement.

## 4. Contre-unités : l'ancien et le nouveau système

### Les tables de contre

`global_build_sequence` déclare, par palier, quelle unité contre quel type de
menace :

```
call AddUnitToAntiair(uARCHER, 15)
call AddUnitToAntimediumarmor(uHUNTRESS, 1)
...
call DynamicBuildUnit(40)
```

Les forces ennemies (`enemy_air`, `enemy_casters`, `enemy_piercing`, …) sont
calculées à partir de `REFORGED/Strengths.txt` et des notes de
`StandardUnits.txt`.

### Ancien système (`adaptive_counters = false`)

`DynamicBuildUnitBase` (`common.eai:11763`) tirait **une seule** contre-unité
au hasard pondéré, puis :

```
num = (100 − population utilisée) / coût en population
BuildUnit(Min(num, déjà_fait + 10), contre_unité, 40)
```

→ l'IA **remplissait systématiquement sa population jusqu'au plafond** avec
cette unité. C'est l'origine des « armées énormes toujours à 100 de pop ».

### Nouveau système (`adaptive_counters = true`, défaut Reforged et TFT depuis 3.8.0)

`BuildAdaptiveCounters` (`common.eai:11663`) remplace cela :

- au plus **2 types** de contre-unités retenus (`adaptive_selected[0..1]`)
- budget de population :
  `adaptive_budget = 25 % × (population de combat actuelle + marge ≤ 10)`
  porté à **40 %** si l'ennemi a de l'aérien (`enemy_air ≥ 10` et couverture
  < 50 %) — `common.eai:11535`
- `adaptive_reserved_food` **réserve** cette population : tant que les
  contre-unités manquantes ne sont pas produites, les autres unités de combat
  voient `AdaptiveAvailableFood()` réduit d'autant (`common.eai:12710`) et
  renvoient `CANNOT_BUILD`

`BuildAdaptiveReinforcements` (`common.eai:13804`) est censé consommer la
population restante, mais il abandonne immédiatement si :

1. une contre-unité sélectionnée est encore sous son objectif, **ou**
2. **n'importe quelle** unité de combat de la file de build est encore sous son
   objectif — commentaire du code : *« Preserve the strategy's opening and
   replacement targets »*, **ou**
3. la passe précédente s'est terminée en `NOT_ENOUGH_RES`

Comme les listes de stratégie de palier 3 demandent plus de population que le
plafond n'en laisse après les paysans, la condition 2 est presque toujours
vraie → **les renforts ne se déclenchent quasiment jamais**, et le remplissage
automatique jusqu'à 100 de population a disparu.

C'est, à notre lecture, la cause principale de « l'armée est plus petite
qu'avant ». Voir [05-diagnostic-difficulte.md](05-diagnostic-difficulte.md).

### `SetBuildReact`

Utilisé par les stratégies « mass X » pour arbitrer dynamiquement entre deux
unités (`common.eai:11213`) :

```
SetBuildReact(42, 15, uHUNTRESS, 0, uARCHER, enemy_air, 5, 20, 92)
```

= « j'alloue 42 points de population ; plus `enemy_air` monte de 5 vers 20,
plus la part va aux archers, le reste aux chasseresses ; minimum 15
chasseresses ».

C'est la raison pour laquelle, en jouant aérien (griffons, chimères, dragons),
on voit l'IA Elfe produire des **archers jusqu'en fin de partie** : ce sont,
dans ses tables, ses anti-air de base, et le mécanisme est purement un arbitrage
de population, sans notion de palier technologique.
