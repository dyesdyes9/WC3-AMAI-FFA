# 04 — Quand et qui l'IA attaque

## 1. L'arbre de décision

`SingleMeleeAttackAM` (`common.eai:15600`), dans l'ordre. Le **premier** cas
qui s'applique gagne et sort de la fonction.

| # | Cas | Condition |
| --- | --- | --- |
| 0 | Assaut désespéré | `desperation_assault` — attaque perpétuelle, sans aucun test de force |
| 1 | Défense | `town_threatened` → `SleepUntilTownDefended` |
| 2 | Commandes du Commander | `no_attack`, `queue_running`, `attack_player`, `attack_point`, `attack_unit` |
| 3 | Expansion par milice | `militia_expanding` |
| 4 | Tower rush | `towerrush` |
| 5 | Expansion par Ancient | `ancient_expanding` et force suffisante |
| 6 | Rush de creep (Elfe BR) | `rushcreep_target` |
| 7 | Défense d'expansion contestée | `double_expansion_target` + `IsTargetGood(…, 10)` |
| 8 | Nettoyage de creeps sur une mine à prendre | `needs_exp` |
| 9 | Cible commune des alliés | `c_ally_total > 0` et cible partagée |
| 10 | **Mega-target** | `difficulty != EASY` et tirage ≤ `comp_chosen_target_rate` et `GetMegaTarget() != null` |
| 11 | **Attaque d'un joueur** | fenêtre XP/population (ci-dessous) + `ChooseAttackTarget() != null` |
| 12 | Creep | sinon — **sauf** si `stop_creeping_after_level_5` et tous les héros ≥ niveau 5 |
| 13 | **Rien** | `Sleep(4 × sleep_multiplier)` et on recommence |

### La fenêtre d'attaque du cas 11 (`common.eai:15846`)

```jass
if hero_xp < GetRandomInt(50,150)
   or hero_xp > GetRandomInt(300,850)
   or second_hero_xp > 450
   or FoodUsed() > GetRandomInt(40,60) then
      hall = ChooseAttackTarget(hall)
```

Lecture :

- **très tôt** (héros 1 sous ~50-150 XP) → l'IA tente une attaque / un rush
- **fenêtre morte** : entre ~150 et ~300 XP du héros 1, si la population est
  sous 40-60 et que le héros 2 est sous 450 XP → l'IA **ne regarde même pas**
  une cible joueur, elle part creeper
- **ensuite** (héros expérimenté ou population > 40-60) → elle regarde une cible

Donc passé ~15 minutes avec 60+ de population, le test est satisfait : l'IA
*cherche* une cible. Si elle ne vient pas, c'est que `ChooseAttackTarget`
renvoie `null` — c'est-à-dire le test `IsTargetGood`.

## 2. `IsTargetGood` — le verrou central

`common.eai:15233` :

```jass
GetTargetStrength(target) + GetTowerFactor(target)
  <= own_strength
     + attacking_aggression
     + added_aggression
     + added_racial_aggression
     + attacker_bonus
```

### Membre de gauche

- `GetTargetStrength` = `GetUnexactPlayerStrength(propriétaire)`, l'estimation
  de la force **totale du joueur** (pas de l'armée locale), plus une pénalité
  de distance si elle est sous 100.
- `GetTowerFactor` (`common.eai:15173`) =
  `GetLocationTowerStrength(cible, ver_tower_check_radius = 2000)`,
  **multiplié par 4 si l'IA n'a pas de siège**.

```jass
has_siege = ai_strength > 60  ou  un bâtiment/unité marqué `siege` est terminé
```

Le tag `siege` est la colonne `type` de `StandardUnits.txt` : Ballista et
Chimaera pour l'Elfe, Catapult pour l'Orc, Mortar pour l'Humain, Meat Wagon
pour l'Undead.

Une tour vaut ~2 de force. **Sans siège, une tour coûte donc 8 points de force
exigés à l'IA.** 6 tours = +48. Une armée de 100 points de population pèse
environ 50-75 de force : l'IA ne peut mathématiquement pas valider l'attaque.

C'est le mécanisme exact derrière « je mets 5-6 tours et ça suffit ».
Le seuil `ai_strength > 60` est brutal : juste en dessous, les tours comptent
×4 ; juste au-dessus, ×1.

### Membre de droite

| Terme | Source | Valeur typique |
| --- | --- | --- |
| `own_strength` | `GetOwnStrength()` — **hors paysans, hors héros blessés, hors unités en soin** | 30 à 75 |
| `attacking_aggression` | `GlobalSettings.txt` (**2**) `+ p_aggression[profil]` | **−9 à +7**, le plus souvent ≈ **−7** |
| `added_aggression` | `AddedAggression.txt`, selon la population | voir table |
| `added_racial_aggression` | `<Race>/RaceAggression.txt`, selon race ennemie × palier | −1 à +5 |
| `attacker_bonus` | `expansion_target_bonus` (profil, 3-12) ou `comp_chosen_target_bonus` (profil, 3-8), **0** pour une cible choisie par AMAI | 0 à 12 |

`AddedAggression.txt` :

| Population ≥ | Agressivité ajoutée |
| --- | --- |
| 99 | 25 |
| 88 | 20 |
| 80 | 12 |
| 70 | 10 |
| 60 | 8 |
| 50 | 7 |
| 40 | 6 |
| 30 | 5 |
| 20 | 2 |

Et `−10` supplémentaires si le héros 1 n'est pas encore sorti
(`set_aggression`, `common.eai:8343`).

**Point important** : la table est très non linéaire entre 80 et 99 (12 → 25).
Une IA qui plafonne à 80 de population perd 13 points d'agressivité par rapport
à une IA à 99 — et 13 points, c'est l'équivalent de 1,5 tour ennemie, ou de
6 grunts. **La perte de taille d'armée se paie donc deux fois : moins de force
réelle, et moins d'agressivité.**

### Agressivité par profil

`Profiles.txt`, colonne 3. Sur les ~20 premiers profils :
`Crazy_Rusher +5`, `Aggressario −2`, `Crusher −6`, `Xerox / Xenon / Utopio −7`,
`Razkal / Zmasher −8`, `CPU / Terra / Q −9`, `Hunter / MaTrIx / ErRoR −10`,
`RomuLus / ReMus / Menace / Razkal −11`, `chick3n −15`.

Avec `attacking_aggression = 2` en base, l'agressivité effective est donc
**presque toujours négative**, autour de −7. Conséquence directe :
`attacking_aggression > 0` est quasi jamais vrai → la 4ᵉ mine
(voir [03 §4](03-economie-paysans-expansions.md)) n'est pratiquement jamais
prise.

## 3. Choix de la cible

`ChooseAttackTarget` (`common.eai:15361`) :

```
avec probabilité comp_chosen_target_rate (profil, 0,3 à 0,8) :
    1. ChooseEnemyExpansionTarget  → cible fournie par l'IA Blizzard, bonus expansion_target_bonus
    2. sinon ChooseEnemyBaseTarget → cible Blizzard, bonus comp_chosen_target_bonus
sinon / si échec :
    3. ChooseAnyEnemyTarget → ChooseAnEnemyTarget, bonus 0
```

`ChooseAnEnemyTarget` dépend de `attacking_strategy` (GlobalSettings,
**valeur livrée = 4**) :

| Valeur | Comportement |
| --- | --- |
| 1 ou 3 | ennemi le plus faible |
| 2 | ennemi le plus fort |
| 5 | 1 fois sur 3 la menace la plus proche, sinon `GetFFAEnemy()` |
| **4 (défaut)** ou autre | 1 fois sur 3 `GetNearestThreatEnemy()`, sinon `GetWeakAndNearEnemy()` |

`GetWeakAndNearEnemy` (`common.eai:15069`) minimise
`force estimée + distance/1400`.

### Deux faiblesses structurelles en FFA

1. **Un seul candidat est testé.** `ChooseAnyEnemyTarget` calcule *un* ennemi,
   lui applique `IsTargetGood` avec un bonus de **0**, et renvoie `null` en cas
   d'échec. Il n'y a **aucune boucle sur les autres ennemis**. Si l'adversaire
   le plus faible-et-proche est encore trop fort (ou trop fortifié), l'IA
   n'attaque personne, alors qu'un autre joueur était peut-être à sa portée.
2. **Avec le défaut 4, le joueur fort n'est jamais visé.** En FFA, l'humain
   qui domine a la force estimée la plus haute : `GetWeakAndNearEnemy`
   l'écarte systématiquement. Il ne reste que `GetNearestThreatEnemy` (1 fois
   sur 3) et `GetMegaTarget` pour le désigner.

C'est cohérent avec l'observation « quand il reste 3 joueurs et que j'attaque
l'un des deux autres, le troisième attend » : son candidat unique est le joueur
en train d'être attaqué (le plus faible), mais le combat en cours fait grimper
la menace locale et déclenche `RETREAT_CONTROL` / `town_threatened`, ou bien le
test échoue et l'IA s'arrête — elle ne bascule pas sur une seconde cible.

## 4. Pourquoi l'IA peut rester totalement inactive

Quatre portes se ferment l'une après l'autre :

1. `AwaitMeleeHeroesAM` (`common.eai:15955`) : si **tous** les héros entraînés
   sont dans le groupe de soin, `creeping_only = true` → aucune attaque joueur.
2. `GetOwnStrength` et `GetHeroStrength` renvoient **0** pour les unités et
   héros en soin. Après un combat perdu, la force mesurée s'effondre, donc la
   boucle `races.eai:638` attend, et `IsTargetGood` échoue.
3. `IsTargetGood` échoue (tours ×4, agressivité négative, estimation haute de
   la force du joueur).
4. `stop_creeping_after_level_5 = true` (nouveau en **3.8.0**, activé par défaut
   en Reforged et TFT) : avec tous les héros niveau 5+, le creep de
   remplissage est interdit. Le dernier recours de l'arbre de décision devient
   `Sleep(4 × sleep_multiplier)`.

Avant 3.8.0, une IA qui échouait au test d'attaque partait au moins creeper :
elle bougeait, elle gagnait de l'XP, elle croisait des joueurs en route. Depuis,
elle **dort sur place**. C'est très probablement ce que l'on voit sur la
minimap : des IA immobiles dans leur base.

## 5. Harcèlement (les attaques « au compte-gouttes »)

Système distinct de l'armée principale. `AddHarass(groupe, qty, unit)`
(`common.eai:11832`) réserve des unités à un groupe de harcèlement,
`max_harass_groups = 10`.

Exemple Orc (`global_init_strategy` + `init_strategy_NormalOrc`) :

```
AddHarass(1, 1, uGRUNT)        // 1 grunt
AddHarass(2, 5, uGRUNT)        // 5 grunts, groupe de distraction
AddHarass(3, 2, uWYVERN)
AddHarass(4, 1, uBLADE_MASTER)
```

Ces groupes ciblent les paysans, les expansions, un emplacement ou le hall
principal (`Jobs/HARASS.eai`), et agissent **indépendamment** du test
`IsTargetGood`. Paramètres dans `GlobalSettings.txt` :
`harass_radius_attack_ranged/melee`, `harass_radius_flee_ranged/melee`,
`ver_harass_tower_check_radius`.

Ce sont ces groupes que l'on reçoit « une unité à la fois » : ils ne sont pas
une attaque, mais du harcèlement, et ils se renouvellent dès qu'un groupe est
perdu (corrigé en 3.8.0 : *« Harassment can start again after a group is lost
or finishes retreating »*, ce qui rend le phénomène **plus** fréquent
qu'avant).

## 6. Fuite et retraite

`GetFleeMultiple` (`common.eai:3847`) interpole entre `ver_flee_multiple1 = 1`
et `ver_flee_multiple3 = 3` selon l'agressivité effective, entre
`ver_low_aggression = −15` et `ver_high_aggression = 45`. Avec une agressivité
effective autour de −7 à +10, le multiplicateur de fuite est bas : l'IA fuit
tôt.

3.8.0 a renforcé cela : *« Equal or stronger nearby enemies can trigger
AMAI-controlled retreat before combat begins »* et *« Retreat assessments
include hostile towers and attacking Ancients »*.

Téléportation défensive : `teleport_low_threat = 50`,
`teleport_high_threat = 100`, `teleport_army_min_strength = 20` — l'armée
rentre au portail dès qu'une menace dépasse ces seuils, ce qui interrompt les
attaques en cours.
