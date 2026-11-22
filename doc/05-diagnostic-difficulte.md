# 05 — Diagnostic « l'IA est devenue plus facile »

Analyse menée à partir du code de la version 3.8.0 + Unreleased de ce dépôt.
**Rien ici n'a été vérifié en partie** : ce sont des conclusions de lecture de
code, à confirmer par test. Les leviers du §3 sont donnés dans l'ordre de
l'impact attendu.

> **Rectification (voir [06 §2.4](06-conception-ia-ffa.md)).** En FFA, le
> plateau à 80 de population est le **bon** régime d'après la page officielle
> de Blizzard : monter à 100 en permanence épuise l'or et désigne l'IA comme la
> menace. Le vrai problème n'est pas le plafond mais ce qui remplit les 80
> points (24 wisps + 15 chasseresses + 10 archères). La cause A ci-dessous
> reste valable, mais comme levier de **fin de partie**, pas comme régime
> permanent.

## 1. Les cinq causes identifiées

### A. Le remplissage automatique de la population a disparu (cause principale)

Avant 3.8.0, `DynamicBuildUnit(40)` — appelé dans `global_build_sequence` de
chaque race, à chaque palier — tirait une contre-unité et en commandait
`(100 − population utilisée) / coût` exemplaires. **L'IA remplissait donc
toujours sa population jusqu'au plafond.** C'est l'origine des « armées
énormes, toujours à 100 de pop ».

3.8.0 a remplacé ce système par les contre-unités adaptatives
(`adaptive_counters = true` dans `REFORGED/GlobalSettings.txt`). Désormais :

- au plus 2 types de contre-unités ;
- budget limité à **25 %** de la population de combat (40 % face à de
  l'aérien) — `common.eai:11535` ;
- le relais censé consommer le reste de la population,
  `BuildAdaptiveReinforcements` (`common.eai:13804`), **abandonne dès qu'une
  seule unité de combat de la file de build est encore sous son objectif**
  (commentaire : *« Preserve the strategy's opening and replacement
  targets »*).

Or les listes de stratégie de palier 3 demandent systématiquement **plus** de
population que le plafond n'en laisse une fois les paysans payés
(voir [03 §5](03-economie-paysans-expansions.md) : ~107-110 demandés pour 100
disponibles chez l'Elfe). La condition de garde est donc presque toujours vraie,
et le remplissage ne se déclenche jamais.

**Résultat : l'armée s'arrête à la taille que la liste de stratégie et les
ressources permettent — typiquement 55-65 points de population — au lieu de
monter au plafond.**

### B. Le plafond à 80 coûte double

`AddedAggression.txt` donne +12 d'agressivité à 80 de population, mais +20 à 88
et **+25 à 99**. Une IA qui stagne à 80 perd donc 13 points d'agressivité en
plus de sa force manquante. Et 13 points, dans `IsTargetGood`, c'est
l'équivalent de 1,5 tour ennemie ou de 6 grunts.

La cause A et la cause B se renforcent mutuellement : moins d'armée → moins
d'agressivité → moins d'attaques → moins de pression → le joueur a le temps de
faire plus de tours → encore moins d'attaques.

### C. La force des héros a été réduite en 3.8.0

Changelog 3.8.0 : *« Hero strength now reflects learned abilities and available
mana, with reduced level growth and smaller bonuses for passive skills. »*

`GetHeroStrength` (`common.eai:5925`) vaut maintenant
`2 + 0,5 × (niveau − 1) + bonus de compétences`, les bonus des sorts à mana
étant **multipliés par la fraction de mana restante**. Un héros niveau 6 pèse
donc environ 4,5 + compétences, et bien moins encore après un combat (mana
vide). Comme `own_strength` inclut `GetPlayerHeroStrengthMod`, cela abaisse
directement le membre droit de `IsTargetGood` **et** rend le seuil
`has_siege = ai_strength > 60` plus difficile à atteindre — donc les tours
ennemies comptent ×4 plus souvent.

### D. `stop_creeping_after_level_5` immobilise les IA

Nouveau réglage 3.8.0, activé par défaut en Reforged et TFT. Quand tous les
héros entraînés sont niveau 5+, le creep « faute de mieux » est interdit. Or
c'était la **dernière branche** de l'arbre de décision : si le test d'attaque
échoue, il ne reste que `Sleep(4 × sleep_multiplier)`.

Avant, une IA sans cible valide partait creeper : elle bougeait, gagnait de
l'XP, croisait des joueurs. Depuis, elle dort dans sa base. C'est l'explication
la plus directe de « ils restent souvent sans rien faire dans leur base ».

### E. Le choix de cible en FFA écarte le joueur fort

Avec `attacking_strategy = 4` (valeur livrée), `ChooseAnEnemyTarget` utilise
2 fois sur 3 `GetWeakAndNearEnemy`, qui minimise `force + distance`. En FFA,
le joueur humain qui domine a la force estimée la plus haute : il est
systématiquement écarté. Il ne reste que `GetNearestThreatEnemy` (1 fois sur 3)
et `GetMegaTarget` pour le désigner.

Pire, `ChooseAnyEnemyTarget` (`common.eai:15340`) ne teste **qu'un seul
candidat** avec un bonus d'agressivité de 0 ; en cas d'échec il renvoie `null`
sans essayer un autre ennemi. D'où le troisième joueur qui « attend » pendant
qu'on tue le deuxième.

### F. Les paysans (secondaire, mais réel)

À 3 mines : 21-24 wisps, 18-22 paysans/peons, 15 acolytes
(voir [03 §1](03-economie-paysans-expansions.md)). Soit 5 à 8 points de
population de plus qu'un joueur humain. Ce n'est pas la cause principale, mais
cela se cumule.

Noter aussi que `MAX_WORKER_TARGET_MINES = 3` et le plafond effectif de
4 mines (inatteignable car il exige `attacking_aggression > 0`) **vont déjà dans
le sens souhaité** : l'IA se stabilise à 3 mines, ce qui est proche du
comportement décrit comme « celui d'avant » (2-3 mines).

## 2. Ce qui n'est PAS la cause

- **Le plafond de population n'est pas bridé.** `ver_food_limit` =
  `PLAYER_STATE_FOOD_CAP_CEILING` = 100 en mêlée, et `FarmBuilder` construit
  jusqu'à `max_farms` = 10 fermes / puits de lune.
- **L'upkeep ne bloque pas à 80** dès que l'IA a 2 mines
  (`upkeep_mines_needed = 2` pour les deux paliers). Le blocage et l'épargne de
  2000 or ne concernent que l'IA restée à une seule mine.
- **La répétition des mêmes unités n'est pas un bug** : les listes de palier 3
  de `BuildSequence.ai` demandent explicitement des grunts, des chasseresses et
  des archers, et `strat_food_persistence × population` verrouille la stratégie
  courante dès que l'armée est grosse.

## 3. Leviers de réglage, par impact attendu

Tous les fichiers cités sont des sources : relancer `AMAI-Build.bat` puis
`AMAI-Deploy.bat` après modification.

### 3.1 Rendre le remplissage de population effectif

Deux options, de la plus prudente à la plus franche.

**Option 1 — revenir à l'ancien système.** Dans
`REFORGED/GlobalSettings.txt` :

```
adaptive_counters	false
```

`DynamicBuildUnitBase` reprend alors sa branche historique et remplit la
population jusqu'au plafond. On perd l'adaptation à deux menaces simultanées
introduite en 3.8.0.

**Option 2 — débloquer `BuildAdaptiveReinforcements`.** Assouplir la garde 2
de `common.eai:13828` pour n'exclure que les unités réellement finançables
(par exemple ignorer celles dont le bâtiment producteur n'existe pas, ou
n'exclure que les unités dont la quantité manquante dépasse un seuil).
C'est le correctif de fond, mais il demande un vrai test de non-régression.

### 3.2 Réduire la charge en paysans

`REFORGED/<Race>/Settings.txt`. Baisser surtout les valeurs « 3+ mines » :

| Réglage | Elfe livré | Suggestion |
| --- | --- | --- |
| `peon_mines_number` | 24 | 18 |
| `min_peon_number_multi_mine` | 21 | 15 |
| `peon_2_mines_number` | 20 | 16 |
| `min_peon_number_double_mine` | 16 | 13 |

Équivalents Orc / Humain : `peon_mines_number` 22 → 17,
`min_peon_number_multi_mine` 18-19 → 14. Chaque point récupéré part directement
dans l'armée, puisque les paysans ont une priorité (280) supérieure aux unités
(35-65).

### 3.3 Remonter l'agressivité

- `REFORGED/GlobalSettings.txt` : `attacking_aggression 2` → `6` ou `8`.
  Effet immédiat sur `IsTargetGood`, sur la fuite (`GetFleeMultiple`) **et** sur
  la prise de la 4ᵉ mine (qui exige `attacking_aggression > 0`).
- `REFORGED/Profiles.txt`, colonne 3 : la quasi-totalité des profils est entre
  −6 et −15. Les relever de +5 globalement les ramènerait autour de 0.
- `REFORGED/AddedAggression.txt` : aplatir la courbe, par exemple 80 → 18 au
  lieu de 12, pour que la perte de population coûte moins cher.

### 3.4 Casser le verrou des tours

C'est le levier le plus direct contre « 5-6 tours suffisent ».
`GetTowerFactor` (`common.eai:15173`) :

```jass
if h_siege then
  return tstrength
else
  return 4 * tstrength      // <- facteur 4
endif
```

Pistes : passer le facteur à 2, ou abaisser le seuil `has_siege =
ai_strength > 60` (`common.eai:16239`) à 40, ou — plus propre — faire en sorte
qu'une IA face à beaucoup de tours **produise** du siège plutôt que renonce
(les tables `AddUnitToAntitowers` existent déjà, il faudrait que leur poids
monte avec `enemy_towers`).

On peut aussi réduire `ver_tower_check_radius` (2000, `GlobalSettings.txt`) :
un rayon de 2000 autour de la cible ramasse énormément de tours sur une base
compacte.

### 3.5 Remettre les IA en mouvement

`REFORGED/GlobalSettings.txt` :

```
stop_creeping_after_level_5	false
```

L'IA sans cible valide repart creeper au lieu de dormir. Effet de bord : plus
d'XP pour ses héros, donc des héros plus forts — ce qui est souhaitable ici.

### 3.6 Viser le joueur qui domine en FFA

`REFORGED/GlobalSettings.txt` : `attacking_strategy 4` → `5`
(1 fois sur 3 la menace la plus proche, sinon `GetFFAEnemy()`), ou `2`
(l'ennemi le plus fort — brutal mais c'est exactement le comportement
« ils venaient tous sur moi »).

Correctif de fond : faire boucler `ChooseAnyEnemyTarget` sur plusieurs ennemis
au lieu d'un seul candidat.

### 3.7 Nettoyer les unités obsolètes au palier 3

`REFORGED/<Race>/BuildSequence.ai`, blocs `if tier == 3`. Pour chaque
stratégie, baisser la quantité des unités de palier 1 et/ou leur priorité.
Exemple `NormalOrc` :

```jass
call BuildUnit(6, uGRUNT, 40)        // -> BuildUnit(2, uGRUNT, 30)
call BuildUnit(4, uHEAD_HUNTER, 40)  // -> BuildUnit(2, uHEAD_HUNTER, 30)
call BuildUnit(4, uTAUREN, 44)       // -> BuildUnit(8, uTAUREN, 55)
```

Même logique côté Elfe : `7 HUNTRESS 50` et `6 ARCHER 54` au palier 3 sont les
deux lignes à réduire, et le `SetBuildReact(42, 15, uHUNTRESS, 0, uARCHER, …)`
de `MassHuntress` est ce qui produit des archers jusqu'en fin de partie quand
le joueur est aérien.

Attention : chaque suppression de population dans ces listes ne profite à
l'armée **que si** le §3.1 est traité ; sinon on réduit l'armée au lieu de la
recomposer.

## 4. Ordre de travail suggéré

1. `stop_creeping_after_level_5 = false` et `attacking_aggression = 6` — deux
   lignes, effet visible immédiatement, zéro risque de régression.
2. `adaptive_counters = false` pour confirmer en partie que la cause A est bien
   la bonne. Si l'IA remonte à 100 de population, le diagnostic est validé.
3. Si validé : implémenter le correctif de fond du §3.1 option 2, pour garder
   les contre-unités adaptatives **et** le remplissage.
4. Baisser les paysans (§3.2) et nettoyer les listes de palier 3 (§3.7).
5. Traiter le facteur tours (§3.4) et le ciblage FFA (§3.6).
