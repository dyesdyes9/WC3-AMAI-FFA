# AMAI — marche à suivre (installation locale)

## Ce qui a été constaté

| Point | Valeur |
| --- | --- |
| Version du jeu installée | **3.0.1.24371** (lue dans `D:\Games\Warcraft III\.build.info`) |
| Édition de scripts AMAI à utiliser | **REFORGED** |
| Version du code source dans ce dossier | 3.8.0 + « Unreleased » (changelog du 2026-10-17) |
| Perl disponible | 5.26, fourni par Git for Windows (pas de Strawberry Perl) |

La question « Reforged ou Definitive Edition » ne pose pas de problème : la table de
compatibilité du `README.md` donne les scripts **REFORGED** comme *optimaux* pour les
clients 3.0.0 / 3.0.1, c'est-à-dire exactement le client installé ici. AMAI continue
d'être maintenu pour ce client (dernière entrée de changelog : octobre 2026).

## Pourquoi il a fallu compiler

Ce dossier est le **dépôt source** GitHub, pas une release. Il ne contient aucun
dossier `Scripts\` prêt à l'emploi — il faut d'abord générer les `.ai` et le
`Blizzard.j` à partir des `.eai`.

`MakeREFORGED.bat` appelle `perlcheck.bat`, qui exige Perl ≥ 5.30 et refuse donc le
Perl 5.26 de Git. En pratique AMAI n'utilise que `strict`, `warnings` et `File::Copy`
(tous dans le cœur de Perl), et compile parfaitement avec 5.26 : `AMAI-Build.bat`
reprend les mêmes étapes en sautant uniquement ce contrôle de version. La sortie est
validée par `pjass.exe` et `jassparser.exe`, comme dans le script officiel.

Alternative « officielle » : installer <https://strawberryperl.com/> puis utiliser
`MakeREFORGED.bat` tel quel.

## Méthode 1 — par carte (ce qui a été fait)

```
AMAI-Build.bat
```

Une seule fois, ou après une mise à jour du dépôt. Produit `Scripts\REFORGED\`.

```
AMAI-Deploy.bat "<carte.w3x ou dossier de cartes>" [0|1|2]
```

Le script copie la ou les cartes dans
`%USERPROFILE%\Documents\Warcraft III\Maps\AMAI\<nom du dossier source>\`
puis installe AMAI **sur la copie** — les cartes d'origine ne sont jamais touchées.

Option Commander : `0` = sans, `1` = avec (défaut), `2` = AMAI (équipes impaires)
contre l'IA Blizzard (équipes paires).

Avec le Commander, deux boîtes de dialogue apparaissent au lancement (langue, mode de
jeu) ; en jeu, `Échap` ou `-cmd` ouvre le menu. Pour les supprimer, renseigner
`language` et `game_mode` dans `Scripts\REFORGED\Blizzard.j` avant d'installer.

### Déjà installé

- `Maps\AMAI\Season9\(8)Monopoly_S2_v1.5.w3x` — AMAI REFORGED + Commander
- `Maps\AMAI\Season9\(2)EchoIsles_S2_v2.2.w3x` — AMAI REFORGED + Commander
- `Maps\AMAI\Season9\` — tout le pool Season9, build du 2026-10-30 (**avant** les
  bonus FFA)
- `Maps\AMAI\Download\` — Crimson Oasis, Leviathan, Never Nerf, Buff Twice,
  builds du 10 au 18 novembre (**avant** les bonus FFA)
- `Maps\AMAI\Download\Crimson Oasis 1.3 - FFA IA.w3m` — AMAI REFORGED +
  Commander, build du 2026-11-21 **avec** les bonus FFA
  ([doc/06](doc/06-conception-ia-ffa.md)). Carte 24 joueurs (« 12v12, FFA »),
  c'est la carte de test des réglages FFA.

### Convention de nommage

Pour distinguer une carte avec les réglages FFA, le nom **affiché en jeu** doit
être `<NomCarte> - FFA IA`. Renommer le fichier ne suffit pas : Warcraft affiche
le nom interne de la carte. Sur ces cartes mêlée le nom est une chaîne de texte
dans `war3map.wts` (`STRING 1`), donc la modification est simple et sans risque :

```powershell
.\MPQEditor.exe e "<carte>" "war3map.wts" "<dossier de travail>"
```

Éditer la troisième ligne du fichier extrait en conservant le BOM UTF-8 et les
fins de ligne CRLF, puis le réinjecter :

```powershell
.\MPQEditor.exe a "<carte>" "<dossier de travail>\war3map.wts" war3map.wts
```

```powershell
.\MPQEditor.exe f "<carte>"
```

Note : `MPQEditor.exe` doit être lancé depuis la racine du dépôt (il y trouve
`SFmpq.dll`), et l'extraction de plusieurs fichiers en une seule commande en
oublie parfois — vérifier la liste obtenue et réextraire un par un au besoin.

Pour le reste du dossier d'un coup :

```
AMAI-Deploy.bat "C:\Users\dyesdyes\Documents\Warcraft III\Maps\Download\Season9" 1
```

Désinstallation d'une carte : `Uninstall.bat "<carte>"`, ou simplement supprimer la copie.

## Méthode 2 — en mod global (à envisager)

Installe les scripts une fois dans le jeu : **toutes** les cartes mêlée jouées en
partie personnalisée utilisent AMAI, y compris les cartes officielles embarquées dans
les archives CASC du jeu, qu'il est pénible d'extraire.

Autoriser les fichiers locaux — **déjà fait sur cette machine** : la clé
`HKCU\Software\Blizzard Entertainment\Warcraft III\Allow Local Files` vaut déjà `1`.
Si besoin de la remettre :

```
reg add "HKCU\Software\Blizzard Entertainment\Warcraft III" /v "Allow Local Files" /t REG_DWORD /d 1
```

Il ne reste donc que la copie des fichiers. Copier le contenu de `Scripts\REFORGED\` (les `*.ai` et `Blizzard.j`) dans
`D:\Games\Warcraft III\_retail_\Scripts\` — dossier à créer, et c'est bien `_retail_`
pour un client ≥ 1.32.7.

Avantages : plus d'installation carte par carte, mise à jour d'AMAI en une copie.
Inconvénient : s'applique à toutes les parties, et peut être écrasé par une mise à
jour du jeu.

## Limites à garder en tête

- AMAI ne vaut que pour les **cartes mêlée**. Sur une carte entièrement scriptée
  (Footmen Frenzy, tower defense…) il ne change rien, et le Commander peut même entrer
  en conflit avec les déclencheurs de la carte.
- `(8)Monopoly_S2_v1.5.w3x` est bien une carte mêlée ladder, pas le jeu de plateau :
  AMAI s'y applique normalement.
- Sur Battle.net, les cartes de ladder sont fournies par le serveur. AMAI ne joue que
  dans les parties personnalisées utilisant les fichiers locaux.
- Les cartes mêlée personnalisées doivent être réglées sur `Melee (Latest Patch)` dans
  l'éditeur (`Scenario` > `Map Options` > `Game Data Set`), sinon AMAI bloque au tier 2.
