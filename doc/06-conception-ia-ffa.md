# 06 — Conception d'une IA spécialisée FFA

Objectif : faire jouer AMAI comme un joueur de FFA (8 à 12 joueurs, grande
carte), et non comme un joueur de 1c1 placé dans une partie à 12.

## 0. État de la recherche

La recherche web sur le sujet est **pauvre et datée**. La seule source
substantielle et faisant autorité est la page officielle de Blizzard
[Warcraft III — FFA Tips](http://classic.battle.net/war3/basics/ffatips.shtml)
(époque Reign of Chaos). S'y ajoute un journal personnel,
[31 Days of Warcraft III Strategy](https://garote.bdmonkeys.net/warcraft3/index.html),
riche mais non vérifié, orienté Night Elf. Le « Complete Free for All Guide »
de d3scene est hors ligne (page vide). Les autres résultats sont des avis de
forums pré-Reforged ([GameFAQs](https://gamefaqs.gamespot.com/boards/589475-warcraft-iii-the-frozen-throne/52627375?page=1),
[forums Blizzard Reforged](https://us.forums.blizzard.com/en/warcraft3/t/how-to-play-orcs-now/21707),
[warcraft3.info](https://warcraft3.info/articles/233/new-to-warcraft-what-race-should-i-play),
[StrategyWiki](https://strategywiki.org/wiki/Warcraft_III:_The_Frozen_Throne/Orc_strategies),
[RankedBoost](https://rankedboost.com/warcraft-3/best-units/)).

**Les compositions par race du §4 sont donc à considérer comme du consensus
communautaire, pas comme une source vérifiée.** Elles restent à valider en
partie.

## 1. Ce que dit la page officielle de Blizzard

Les points directement exploitables, résumés :

**Économie et population**

- Monter à 100 de population « ne marche pas » contre de bons joueurs FFA : on
  tombe à court d'or. Rester à **80 de population avec plusieurs expansions**,
  monter à 100 seulement quand c'est nécessaire, et **redescendre à 80 quand on
  reste inactif**.
- À 100 de population avec 3 expansions ou plus, on est visiblement la menace
  et tout le monde converge.
- 3 mines coûtent 15 points de population en récolteurs. L'écart entre
  upkeep bas et haut vaut ~20 unités.

**Héros**

- **Toujours prévoir 3 héros.** 1 ou 2 héros est une mauvaise idée car une
  partie longue épuise l'or.
- Creeper **jusqu'au niveau 5, puis se battre**. Les creeps ne donnent plus
  d'XP utile ensuite.
- Orc : Far Seer, et **passer des Loups à Far Sight niveau 3** vers le niveau
  5-7 (Tome de réapprentissage, 300 or) — « peut-être le meilleur sort du jeu
  en FFA ».
- Humain : Archmage d'abord, Élémentaires d'eau pour creeper, puis **Blizzard**
  vers le niveau 5 contre les grosses armées.

**Combat et diplomatie implicite**

- **Ne pas s'attirer d'ennemis supplémentaires.** Un joueur qu'on attaque
  continuera à se focaliser sur nous jusqu'à ce que l'un des deux meure.
- Le harcèlement de héros est explicitement **mauvais en FFA** : il enferme
  dans un duel de 20 minutes pendant que les autres techent et s'étendent.
  Si on harcèle, il faut aller jusqu'à l'élimination.
- Cibler les joueurs **les plus forts ou ceux qui amassent le plus de
  ressources**, pas forcément le plus proche.
- Scouter toute la carte toutes les quelques minutes : la menace principale
  change.
- **Raids en force divisée** : envoyer quelques unités sur les expansions non
  défendues, attaquer deux endroits à la fois, faire dépenser des portails.
- Garder **plusieurs parchemins de portail**.
- Les emplacements des joueurs déconnectés sont des mines libres.
- La passivité est un « game killer » : si la partie stagne, accumuler l'or et
  acheter des objets.

**Tours**

- Quelques tours à la base principale et aux expansions. Elles servent à
  **gagner du temps** et de panneau « propriété privée » : la plupart des
  joueurs FFA vont voir ailleurs. **Ne pas compter sur elles pour gagner.**

**Composition**

- Prévoir un modèle d'armée **par adversaire** (l'auteur en a 5 ou 6).
- Une armée de 80 de population avec la bonne composition bat une armée de 100
  mal composée.
- Shredder gobelin recommandé pour Humain / Orc / Mort-Vivant, **pas** pour
  Night Elf.

## 2. Diagnostic : pourquoi AMAI joue mal le FFA aujourd'hui

### 2.1 Le crochet FFA existe mais est quasi inutilisé

`IsGameFFA()` (`common.eai:9935`) renvoie vrai dès qu'il y a **plus de 3
équipes**, donc toujours dans une partie à 10-12. `game_is_ffa` n'est utilisé
que pour :

1. une variable de chat (`common.eai:3042`) ;
2. `removeNonBeginningStrats` (`common.eai:10494`) — en FFA avec plus de 3
   ennemis, **les stratégies non-« beginning » sont autorisées dès le départ**.
   Bonne nouvelle : le mécanisme pour démarrer directement sur une stratégie de
   palier 3 existe déjà ;
3. la colonne **« FFA bonus »** des tables de stratégie (`races.eai:236`,
   colonne `%16`).

### 2.2 La colonne « FFA bonus » favorise exactement les mauvaises stratégies

Valeurs livrées (colonne FFA bonus) :

| Race | Stratégies ayant un bonus FFA | Valeur |
| --- | --- | --- |
| Elfe | `AoWMix`, `AoLMix` | **15** |
| Humain | `BarrackMix`, `SanctumMix` | **15** |
| Orc | `BarrackMix` 5, `BestiaryMix` | 5 / **10** |
| Mort-Vivant | `CryptMix` 5, `TempleMix` | 5 / **10** |

**Toutes les autres stratégies ont 0.** Or ces stratégies « Mix » ont aussi les
`base rp` les plus hauts du tableau (40 et 35, contre 18 à 32 pour les autres).

Score FFA effectif d'une stratégie Elfe en partie à races aléatoires :

| Stratégie | base | FFA | random | Total | + bonus de palier (22) |
| --- | --- | --- | --- | --- | --- |
| `AoWMix` (palier 1) | 40 | 15 | 10 | **65** | 87 au palier 1 |
| `AoLMix` (palier 3) | 35 | 15 | 5 | 55 | 77 au palier 3 |
| `HippoChim` (palier 3) | 22 | 0 | 0 | **22** | 44 au palier 3 |
| `DryadChim` (palier 3) | 22 | 0 | 0 | **22** | 44 au palier 3 |
| `Hippo` (palier 2) | 25 | 0 | 5 | 30 | 52 au palier 2 |

`AoWMix` écrase tout. Et voici ce qu'`AoWMix` construit **au palier 3**
(`Elf/BuildSequence.ai:2157`) :

```jass
SetBuildReact(50, 15, uHUNTRESS, 10, uARCHER, …)   // 50 pop, min 15 chasseresses + 10 archères
SetBuildReact(20,  2, uARCHER,    3, uBALLISTA, …) // 20 pop de plus
```

**C'est littéralement « 15 chasseresses et 10 archères au palier 3 ».** C'est
la réponse mécanique exacte à « ils viennent m'attaquer avec des archers et des
chasseresses, en FFA ça n'a aucun sens ».

Même schéma ailleurs :

| Stratégie | Palier 3 construit |
| --- | --- |
| Orc `BarrackMix` | 36 pop grunts/head hunters (min 4 grunts) + 36 pop grunts/catapultes |
| Humain `BarrackMix` | 36 pop chevaliers/fusiliers (min 6 fusiliers) + tanks |
| Mort-Vivant `CryptMix` | 20 pop aboms/crypt fiends + 20 pop fiends/gargouilles |
| Elfe `HippoChim` (bonne strat) | mais **12 archères** (24 pop) en plus des hippogriffes et chimères |

Et une fois l'armée construite, `strat_food_persistence × population`
(3 × food chez l'Orc) verrouille la stratégie : à 70 de population, +210
points, impossible à renverser. L'IA est enfermée dans son mauvais choix
d'ouverture **pour toute la partie**.

### 2.3 Les notes de contre ne servent à rien en FFA

Les colonnes `anti air / anti casters / anti piercing / …` sont confrontées à
la composition ennemie **agrégée de tous les ennemis**. À 12 joueurs qui font
tous un peu de tout, toutes les menaces sont moyennes et toutes les stratégies
obtiennent des notes de contre équivalentes. Le signal se noie exactement comme
l'intuition le disait. C'est seulement en fin de partie, à 2-3 survivants, que
ces colonnes redeviennent pertinentes.

### 2.4 Rectification du diagnostic précédent

Le [doc 05](05-diagnostic-difficulte.md) présentait le plateau à 80 de
population comme un problème. **La page de Blizzard dit l'inverse :** 80 de
population avec plusieurs expansions est le bon régime FFA, et monter à 100 en
permanence est une erreur.

Le vrai problème n'est donc pas le plafond, c'est **ce qui remplit les 80
points** : aujourd'hui 24 wisps + 15 chasseresses + 10 archères, là où il
faudrait 18 wisps + chimères/hippogriffes/dryades. Le §3.1 du doc 05
(remplissage de population) reste valable, mais comme levier de **fin de
partie** (« monter à 100 quand c'est nécessaire »), pas comme régime permanent.

## 3. Architecture proposée

Trois couches, de la moins risquée à la plus intrusive. Chacune est utile
seule.

### Couche A — données uniquement, aucun code (impact maximal, risque nul)

Trois fichiers par race, zéro ligne de JASS.

**A1. Recalibrer la colonne « FFA bonus » de `<Race>/Strategy.txt`.** ✅ **FAIT**
Pénaliser les stratégies de masse de palier 1-2, récompenser les stratégies
air / casters / palier 3. Le bonus est de l'ordre de ±25 pour compenser
`strategy_tier_bonus = 22` et permettre à une stratégie de palier 3 d'être
choisie dès le palier 1 (ce que `removeNonBeginningStrats` autorise déjà en
FFA).

Valeurs appliquées (REFORGED, recompilé et validé par `pjass`) :

| Race | Stratégie | FFA actuel | FFA proposé |
| --- | --- | --- | --- |
| **Elfe** | `AoWMix` (archères/chasseresses) | 15 | **−25** |
| | `MassHuntress` | 0 | −15 |
| | `Archer` | 0 | −15 |
| | `MassHD` | 0 | −5 |
| | `NormalElf` | 0 | 0 |
| | `Ballista` | 0 | 0 |
| | `Talon` | 0 | +8 |
| | `MGDryads` | 0 | +12 |
| | `Hippo` | 0 | +12 |
| | `Druids` | 0 | +15 |
| | `AoLMix` (druides/dryades/chimères) | 15 | +20 |
| | `HippoChim` | 0 | **+25** |
| | `DryadChim` | 0 | **+25** |
| **Orc** | `BarrackMix` (grunts/HH/catapultes) | 5 | **−25** |
| | `HHunters` | 0 | −15 |
| | `NormalOrc` | 0 | −10 |
| | `GruntCatapults` | 0 | **−25** |
| | `HeadCatapults` | 0 | −5 |
| | `Raiders` | 0 | 0 |
| | `AntiAir` (batriders) | 0 | +8 |
| | `Wyvern` | 0 | +15 |
| | `WyvSh` (chamans + wyvernes) | 0 | +20 |
| | `BestiaryMix` | 10 | +22 |
| | `FastSh` (chamans + taurens) | 0 | **+25** |
| **Humain** | `BarrackMix` | 15 | **−25** |
| | `Rifle` | 0 | −10 |
| | `NormalHuman` | 0 | −5 |
| | `MassSB` | 0 | +5 |
| | `Copters` | 0 | +8 |
| | `Knight` | 0 | +8 |
| | `MassSp` (sorcières) | 0 | +10 |
| | `Dragonhawk` | 0 | +12 |
| | `SanctumMix` (griffons/dragonhawks/casters) | 15 | +22 |
| | `Gryph` | 0 | **+25** |
| **Mort-Vivant** | `CryptMix` | 5 | **−20** |
| | `Ghouls` | 0 | −20 |
| | `GargGhouls` | 0 | −10 |
| | `Fiends` | 0 | −5 |
| | `NormalUndead` | 0 | 0 |
| | `MeatFiends` | 0 | 0 |
| | `Banshee` | 0 | +5 |
| | `Aboms` | 0 | +12 |
| | `TempleMix` | 10 | +20 |
| | `MassDestroyer` | 0 | +20 |
| | `GargWyrm` | 0 | +22 |
| | `Wyrms` | 0 | **+25** |

Les stratégies absentes du tableau ci-dessus restent à **0**, sauf quatre
ajouts de cohérence : `DotC` (Elfe, palier 3) **+15** comme `Druids`, et les
stratégies anti-tours `NEAntiTower` / `OAntiTower` / `HAntiTower` /
`UAntiTower` **+5** — le siège est le seul moyen de forcer une base fortifiée,
ce que la page de Blizzard rappelle. Les stratégies de matchup (`VersusHuman`,
`VersusOrc`, …) restent à 0 : elles ne sont pertinentes qu'en fin de partie,
quand il ne reste que 2-3 joueurs.

### Arithmétique de la sélection — pourquoi ±25 suffit

Deux chemins mènent à un choix de stratégie, et ils ne se valent pas du tout.

**À l'ouverture** (`races.eai:999`) : `chooseStrategyRP()` tourne avec
`ai_time <= 2`, donc **sans** le `mult_rp_strat(3)`, et `choose_strategy()`
(`common.eai:10297`) est un **tirage pondéré sur toutes les stratégies**, sans
bonus de palier. Le score est donc simplement
`base + FFA + bonus par race ennemie`. Comme une partie à 12 contient les
4 races, **les 4 colonnes de bonus par race ennemie s'additionnent toutes** —
d'où le besoin de pousser `GruntCatapults` à −25 : ses bonus de race cumulent
+36 à eux seuls.

**Lors d'un changement** (`StrategyChanger`, `races.eai:273`) : `base` est
multiplié par 3, ce qui diluerait les bonus FFA. Mais ce chemin est en pratique
mort en FFA : `finish_strategy_change` ajoute à la stratégie courante
`strat_persistence` (**700 à 1100** selon le profil) + `3 × population`, puis la
multiplie par `Pow(c_enemy_total, 0.75)` (≈ ×6 avec 11 ennemis), face à des
scores normalisés autour de 17. Et `StrategyChanger` abandonne d'emblée si
`FoodUsed() >= 85`.

**Conclusion : en FFA, l'ouverture est le choix définitif.** C'est exactement
ce que la colonne « FFA bonus » pilote, et c'est pourquoi la couche A1 suffit à
elle seule à changer le comportement observé.

### Probabilités d'ouverture mesurées (12 joueurs, 4 races présentes)

Calcul `base + FFA + Σ bonus par race ennemie`, normalisé.

| Race | Stratégies de masse bas niveau | Avant → Après |
| --- | --- | --- |
| Elfe | `AoWMix` + `Archer` + `MassHuntress` + `MassHD` | **32,1 % → 15,0 %** |
| Orc | `BarrackMix` + `HHunters` + `NormalOrc` + `GruntCatapults` | **30,7 % → 16,6 %** |
| Humain | `BarrackMix` + `Rifle` + `NormalHuman` | **25,5 % → 13,4 %** |
| M.-Vivant | `CryptMix` + `Ghouls` + `GargGhouls` + `Fiends` | **30,7 % → 18,3 %** |

Nouveaux favoris par race :

- **Elfe** : `DryadChim` 11,8 %, `Hippo` 10,8 %, `Druids` 10,4 %, `AoLMix`
  10,4 %, `HippoChim` 8,9 %. `AoWMix` tombe de 11,5 % à 2,8 %, `Archer` de
  3,3 % à 0,2 %.
- **Orc** : `WyvSh` 14,2 %, `BestiaryMix` 10,1 %, `Raiders` 9,1 %, `FastSh`
  8,5 %, `Wyvern` 6,4 %. `BarrackMix` tombe de 8,0 % à 2,7 %.
- **Humain** : `Gryph` 16,3 %, `SanctumMix` 12,9 %, `Knight` 8,9 %, `Mortars`
  8,5 %. `BarrackMix` tombe de 11,5 % à 3,0 %.
- **Mort-Vivant** : `GargWyrm` 14,8 %, `MassDestroyer` 11,5 %, `Necro` 11,1 %,
  `TempleMix` 9,4 %, `Wyrms` 9,3 %. `CryptMix` tombe de 9,2 % à 4,3 %.

Aucune stratégie ne descend à un score négatif, ce qui était la contrainte à
respecter : `choose_strategy()` fait un tirage sur des sommes cumulées et
`make_rp_strat_positive()` **n'est pas appelé** sur le chemin d'ouverture.
C'est la raison pour laquelle les pénalités s'arrêtent à −25 et non −45.

Les stratégies de masse restent accessibles en 1c1, où le bonus FFA ne
s'applique pas, et gardent une petite probabilité en FFA — l'objectif était de
les rendre minoritaires, pas de les interdire.

**Reste à surveiller en partie** : `Necro` (Mort-Vivant, 11,1 %) et `Raiders`
(Orc, 9,1 %) montent dans le classement par simple effet de normalisation. Les
deux sont défendables en FFA, mais à confirmer à l'usage.

**A2. Empêcher la production d'unités de palier 1 au palier 3.** ✅ **FAIT**,
mais **pas** par édition des blocs `tier == 3` comme prévu ci-dessous : par un
plafond central piloté par `<VERSION>/TierObsolete.txt`, décrit dans
[02 § Unités de base devenues obsolètes](02-production-unites.md). Une seule
règle, dans `BlockListCheck`, au lieu de ~60 éditions de tables, et la
population libérée est automatiquement redirigée vers les unités avancées puis
les renforts adaptatifs.

Deux conséquences à connaître :

- **La règle s'applique à tous les modes de jeu**, pas seulement au FFA. En 1c1
  aussi, une Elfe ne dépassera plus 2 chasseresses au palier 3. Si c'est
  indésirable, il suffit de conditionner le test de `BlockListCheck` à
  `game_is_ffa`.
- Les stratégies dont le bloc `tier == 3` est presque entièrement composé
  d'unités de base (`AoWMix`, `MassHuntress`, `Archer` chez l'Elfe,
  `BarrackMix` et `Rifle` chez l'Humain) n'ont plus grand-chose à produire en
  propre au palier 3 et dépendent des renforts adaptatifs. Elles restent jouables
  mais perdent leur identité. Les réécrire proprement reste souhaitable — c'est
  le tableau ci-dessous, désormais optionnel.

Lignes concernées si l'on veut aussi réécrire les tables, par ordre de gravité :

| Fichier | Ligne actuelle | Proposition |
| --- | --- | --- |
| `Elf` `AoWMix` t3 | `SetBuildReact(50, 15, uHUNTRESS, 10, uARCHER, …)` | si on garde la stratégie : `SetBuildReact(30, 2, uHUNTRESS, 2, uARCHER, …)` + chimères/dryades pour le reste |
| `Elf` `HippoChim` t3 | `BuildUnit(12, uARCHER, 50)` | `BuildUnit(4, uARCHER, 40)` |
| `Elf` `NormalElf` t3 | `7 HUNTRESS 50`, `6 ARCHER 54` | `3 HUNTRESS 40`, `2 ARCHER 40` |
| `Orc` `BarrackMix` t3 | `SetBuildReact(36, 4, uGRUNT, 4, uHEAD_HUNTER, …)` ×2 | min grunts à 0-2, basculer 36 pop vers taurens/chamans |
| `Orc` `NormalOrc` t3 | `6 GRUNT 40`, `4 HEAD_HUNTER 40` | `2 GRUNT 30`, `2 HEAD_HUNTER 30`, et `8 TAUREN 55` |
| `Orc` `FastSh` t1 | `BuildUnit(10, uGRUNT, 40)` | `BuildUnit(4, uGRUNT, 40)` — « 2-3 grunts pour farmer, 4-5 pour ne pas perdre d'unités » |
| `Human` `BarrackMix` t3 | `min 6 uRIFLEMAN` | min 2, reporter sur griffons/sorcières |
| `Undead` `CryptMix` t3 | `min 5 uABOMINATION`, `0 uCRYPT_FIEND` | garder aboms (front line valable), réduire les fiends |

Attention à l'ordre des opérations : **réduire ces quantités sans faire A1 ni
le §3.1 du doc 05 réduit l'armée au lieu de la recomposer.** A1 d'abord.

**A3. Agressivité et expansions.** Dans `REFORGED/GlobalSettings.txt` et
`Profiles.txt`, voir [doc 05 §3.3](05-diagnostic-difficulte.md). En FFA on veut
`attacking_aggression` à 6 (et non 2), ce qui débloque aussi la 4ᵉ mine. Les
colonnes `expansion time` / `second expansion time` des stratégies de palier 3
sont à avancer (70-80 → 50-60) : la page de Blizzard insiste sur
« expand immediately, tech up rapidly ».

Et `stop_creeping_after_level_5 = false` reste à faire : la page officielle dit
« creeper jusqu'au niveau 5 puis se battre », ce qui correspond au réglage —
mais tant que l'IA n'a pas de cible valide à cause du facteur tours ×4, le
réglage la transforme en statue. À réactiver seulement une fois le §3.4 du
doc 05 traité.

### Couche B — un drapeau FFA dans les tables (code léger)

Le problème restant après la couche A : les notes de contre
(`anti air / anti casters / …`) restent noyées par l'agrégation des 12
ennemis (§2.3), et `strat_food_persistence` verrouille le choix d'ouverture
pour toute la partie.

Deux modifications ciblées :

**B1. Pondérer les forces ennemies par la menace réelle.** Dans le calcul de
`enemy_air`, `enemy_casters`, etc., ne retenir que les 2 ou 3 ennemis les plus
proches ou les plus forts au lieu de la somme sur tous. En fin de partie, quand
il ne reste que 2-3 joueurs, le calcul redevient naturellement celui
d'aujourd'hui — ce qui est exactement le comportement souhaité (« à la toute
fin, quand tu es en 1 contre 1, là c'est différent »).

**B2. Rendre `strat_food_persistence` dépendant du nombre d'ennemis
restants.** Diviser la persistance par le nombre d'ennemis vivants, ou la
mettre à 0 tant que `c_enemy_total > 3`. Cela permet à l'IA de corriger un
mauvais choix d'ouverture pendant la phase à 12 joueurs, et de se verrouiller
en fin de partie quand le choix est devenu pertinent.

### Couche C — comportement FFA (code, le plus de travail)

Les trois comportements que la page officielle décrit et qu'AMAI n'a pas.

**C1. Ne pas défendre une mine secondaire jetable.** C'est le point le plus
important du retour terrain : « quand tu rases une base secondaire, un vrai
joueur la laisse tomber et regroupe ». Aujourd'hui `town_threatened` déclenche
`SleepUntilTownDefended` (`common.eai:15455`) sans distinguer la base
principale d'une expansion, et `teleport_low_threat = 50` fait rentrer l'armée
au portail.

Proposition : pondérer la menace par la valeur de la ville (hall principal +
nombre de bâtiments + or restant dans la mine). Sous un seuil, ne pas rappeler
l'armée principale ; laisser les tours et les défenseurs locaux faire ce qu'ils
peuvent, et marquer le site pour reconstruction ultérieure
(`CheckExpansionRebuildAt` existe déjà).

**C2. Regrouper au lieu d'envoyer au compte-gouttes.** Le flux d'unités une par
une a deux sources distinctes, à traiter séparément :

- les **groupes de harcèlement** (`AddHarass`, [doc 04 §5](04-decision-attaque.md)),
  qui sont voulus mais dont la fréquence a augmenté en 3.8.0 — à réduire en FFA
  (`max_harass_groups`, ou ne pas réalimenter un groupe perdu tant que l'armée
  principale est sous son effectif) ;
- le **réarmement de l'attaque** : `attack_reform_length = 10` (× 2 s) fait
  rejoindre les nouvelles unités à l'armée en cours de route. Si l'armée est en
  train de mourir, chaque unité produite part la rejoindre seule. Il faudrait un
  seuil : ne pas réalimenter une attaque dont la force est tombée sous X %, mais
  rappeler et reformer à la base.

**C3. Choix de cible FFA.** Voir [doc 04 §3](04-decision-attaque.md) :
`attacking_strategy = 4` écarte systématiquement le joueur fort, et
`ChooseAnyEnemyTarget` ne teste **qu'un seul candidat**. Pour du FFA :

- faire boucler le choix de cible sur plusieurs ennemis au lieu d'abandonner au
  premier échec ;
- ajouter un critère « richesse » (nombre de mines exploitées, nombre
  d'expansions) au classement des cibles — la page de Blizzard dit de cibler
  « les plus forts ou ceux qui amassent le plus de ressources » ;
- garder le biais « ne pas s'attirer d'ennemis supplémentaires » : rester sur la
  même cible jusqu'à l'élimination plutôt que de changer d'avis à chaque cycle.

## 4. Compositions FFA par race (consensus communautaire, à valider)

Rappel : hors de la page officielle de Blizzard, ce qui suit n'est pas sourcé
de façon solide. C'est le consensus habituel de la communauté, cohérent avec le
retour terrain. L'aérien est central en FFA : grandes cartes, nécessité de
projeter la force et de frapper des expansions éloignées.

### Orc

| Phase | Composition |
| --- | --- |
| Ouverture | 3-5 grunts pour creeper uniquement, Far Seer en premier héros |
| Héros | Far Seer (**Far Sight niveau 3**, réapprentissage vers le niveau 5-7), Shadow Hunter (Healing Wave, Serpent Wards), Tauren Chieftain |
| Palier 3 — ligne A | Taurens + Chamans (Bloodlust) + Witch Doctors (Sentry/Healing Ward), Kodo pour War Drums |
| Palier 3 — ligne B | Wyvernes (Envenomed Spears) + Chamans / Witch Doctors |
| Anti-air dédié | Batriders — indispensable en FFA car beaucoup d'aérien adverse |
| À ne plus faire | masse de grunts et de head hunters après le palier 2 |

Stratégies AMAI correspondantes : `FastSh`, `WyvSh`, `BestiaryMix`, `AntiAir`.

### Night Elf

| Phase | Composition |
| --- | --- |
| Ouverture | quelques archères / chasseresses pour creeper, puis techer |
| Héros | Priestess of the Moon (Trueshot Aura), Keeper of the Grove (Entangling Roots + Thorns, Tranquility), Demon Hunter ou Warden |
| Palier 3 — ligne A | Chimères (Corrosive Breath) + Hippogriffes / Hippogryph Riders |
| Palier 3 — ligne B | Druides de la Griffe en forme d'ours + Mountain Giants en ligne de front, Dryades (Abolish Magic), Druides du Talon (Faerie Fire) |
| À ne plus faire | masse d'archères et de chasseresses après le palier 2 |

Note : le journal consulté confirme que les Druides de la Griffe ne servent
qu'au palier 3 (forme d'ours), et que les Faerie Dragons sont l'anti-caster de
référence. Pas de Shredder pour le Night Elf d'après la page officielle.

Stratégies AMAI correspondantes : `HippoChim`, `DryadChim`, `Druids`,
`MGDryads`, `AoLMix`.

### Humain

| Phase | Composition |
| --- | --- |
| Ouverture | quelques footmen pour creeper, Archmage en premier héros |
| Héros | Archmage (Élémentaires pour creeper, **Blizzard** vers le niveau 5), Mountain King ou Blood Mage, Paladin |
| Palier 3 | Griffons (Storm Hammers) + Dragonhawks (Cloud contre les tours, Aerial Shackles) |
| Support | Sorcières (Slow, Polymorph), Prêtres, 1-3 Chevaliers pour la présence au sol |
| Contre les tours | Mortiers ou Siege Engines |
| À ne plus faire | masse de footmen et de fusiliers après le palier 2 |

Stratégies AMAI correspondantes : `Gryph`, `SanctumMix`, `Dragonhawk`,
`MassSp`.

### Mort-Vivant

| Phase | Composition |
| --- | --- |
| Ouverture | ghouls (bois + creep), Death Knight en premier héros |
| Héros | Death Knight (Death Pact), Lich (Frost Nova, Dark Ritual), Crypt Lord (Impale, Carrion Beetles) |
| Palier 3 | Frost Wyrms + Destroyers (immunité aux sorts, Devour Magic) |
| Ligne de front | Abominations ou Crypt Fiends, Obsidian Statues pour le soin et la mana |
| Contre les tours | Meat Wagons |
| À ne plus faire | masse de ghouls de combat après le palier 2 |

Plusieurs avis de forum donnent le Mort-Vivant comme la meilleure race en
milieu et fin de FFA, précisément grâce aux Wyrms et Destroyers.

Stratégies AMAI correspondantes : `Wyrms`, `GargWyrm`, `MassDestroyer`,
`TempleMix`, `Aboms`.

## 5. Ordre de travail suggéré

1. ~~**Couche A1** — recalibrer les 4 colonnes « FFA bonus ».~~ ✅ **Fait**, les
   4 tables REFORGED sont modifiées et `Scripts/REFORGED/` recompilé. À vérifier
   en partie : les IA doivent annoncer des stratégies aériennes / casters au
   lieu de `BarrackMix` et `AoWMix`. Non appliqué à `TFT/` et `ROC/`, dont les
   tables ont la même structure si on veut étendre.
2. **Couche A3** — `attacking_aggression`, temps d'expansion.
3. ~~**Couche A2** — nettoyage des blocs `tier == 3`.~~ ✅ **Fait** via
   `TierObsolete.txt`, les trois versions recompilées.
4. **Doc 05 §3.4** — le facteur tours ×4, sans quoi l'IA continuera de ne pas
   attaquer quoi qu'elle construise.
5. **Couche C1** — ne pas défendre les mines jetables.
6. **Couche C3** — choix de cible multi-candidats.
7. **Couche B** — pondération des menaces et persistance de stratégie.
8. **Couche C2** — regroupement contre le compte-gouttes.

### Option : un jeu de tables FFA séparé

Si l'on veut éviter tout compromis entre 1c1 et FFA, le système de build le
permet : `#INCLUDETABLE <$VER$\$RACE$\Strategy.txt>` pourrait devenir
`StrategyFFA.txt`, sélectionné par une variable de build. Cela double le
travail de maintenance des tables, mais supprime le besoin de régler des bonus
qui doivent convenir aux deux formats. À envisager seulement si les bonus FFA
de la couche A s'avèrent impossibles à équilibrer.
