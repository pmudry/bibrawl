# Plan de développement — Bibrawl

Plan dérivé de [desc.md](desc.md). Moteur : **Godot 4.x** (GDScript), cibles mobile (Android/iOS) et desktop (Windows/macOS/Linux).

## 0. Couverture du cahier des charges

| Point de [desc.md](desc.md) | Où dans le plan |
|---|---|
| Comme Brawl Stars mais en mieux | Arène 2D top-down, §1 |
| Survivant solo d'abord, puis 2v2, puis biboule-ball | Phase 1 → 2 → 3, dans cet ordre |
| Biboule-ball : balle américaine avec le nom des personnes tuées | Phase 3 |
| 4 classes : assassin, archer, sorcier/support, tank | Phase 1 |
| Pas de super ; toucher l'ennemi charge, le bouton devient bleu | Phase 1, « capacité chargée » |
| Graphismes secondaires, mobile ET ordi | §1 (placeholders), Phase 0 (exports dès le départ) |
| Peu de skins, par paires opposées | Phase 5 |
| Skin ultra-rare chevalier licorne à 500 boîtes | Phase 5 (compteur pity serveur) |
| Ligues + trophées, classement hebdo, récompenses top 10, truc cool top 3 | Phase 4 |
| Petit coffre, appui long → grossit → meilleure récompense | Phase 5 |

## 1. Choix techniques

| Sujet | Choix | Pourquoi |
|---|---|---|
| Moteur | Godot 4.x, GDScript | Gratuit, export mobile + desktop natif, réseau intégré |
| Vue | 2D top-down (`Node2D`, `CharacterBody2D`) | Style arène type Brawl Stars, graphismes secondaires au début |
| Réseau | Multiplayer haut niveau Godot (`ENetMultiplayerPeer`, `MultiplayerSpawner`, `MultiplayerSynchronizer`) | Serveur autoritaire indispensable pour un jeu classé |
| Serveur | Build Godot headless (`--headless`) hébergé sur un VPS | Même code client/serveur, pas de second langage |
| Méta (comptes, trophées, ligues, coffres) | Backend séparé avec API HTTP + base de données | Le serveur de partie ne doit gérer que le combat ; le méta doit survivre aux redémarrages |
| Contrôles | Joysticks virtuels tactiles + clavier/souris | Une seule scène de contrôle avec détection de la plateforme |
| Assets | Placeholders (formes colorées, `Polygon2D`) | Graphismes « on s'en fiche » au début |

## 2. Architecture du projet Godot

```
bibrawl/
├── project.godot
├── autoload/            # singletons : GameState, NetworkManager, Backend
├── scenes/
│   ├── main_menu/
│   ├── lobby/
│   ├── arena/           # scène de combat + cartes
│   ├── characters/      # base_character.tscn + une scène par classe
│   ├── projectiles/
│   ├── ui/              # HUD, boutons tactiles, coffre, classement
│   └── shop/
├── scripts/
│   ├── characters/      # state machine, stats, capacité chargée
│   ├── modes/           # survivant_solo.gd, duo.gd, biboule_ball.gd
│   └── net/
├── resources/           # .tres : stats des persos, skins, tables de loot
├── server/              # point d'entrée headless, matchmaking
└── assets/
```

Principe : un `BaseCharacter` commun, chaque classe est une scène héritée avec une `Resource` de stats (`CharacterStats.tres`). Les modes de jeu sont des scripts interchangeables branchés sur la même arène.

## 3. Phases

### Phase 0 — Squelette (1–2 semaines)
- [ ] Projet Godot 4, structure de dossiers ci-dessus, `.gitignore` Godot
- [ ] Un perso qui se déplace au clavier ET au joystick virtuel
- [ ] Une arène avec murs (`TileMapLayer`) et caméra qui suit
- [ ] Export Android + Windows fonctionnels dès maintenant (éviter les surprises tard)

### Phase 1 — Combat local (2–3 semaines)
- [ ] `BaseCharacter` : PV, vitesse, attaque de base, mort/respawn
- [ ] Les 4 classes :
  - **Assassin** — mêlée rapide, faibles PV, dash
  - **Archer** — projectile à distance, PV moyens
  - **Sorcier / support** — zone de soin ou bouclier, dégâts faibles
  - **Tank** — PV élevés, lent, attaque courte portée
- [ ] Capacité chargée : chaque coup **qui touche** remplit une jauge ; à 100 % le bouton devient **bleu** et déclenche l'attaque spéciale de la classe (pas de « super » à la Brawl Stars, c'est la même attaque en version renforcée)
- [ ] Bots basiques pour tester seul
- [ ] Mode **Survivant solo** (dernier debout gagne)

### Phase 2 — Multijoueur (3–4 semaines)
- [ ] `NetworkManager` autoload : héberger / rejoindre via ENet
- [ ] Serveur autoritaire : le client envoie des inputs, le serveur simule, `MultiplayerSynchronizer` diffuse positions/PV
- [ ] Interpolation côté client, prédiction locale du déplacement
- [ ] Build serveur headless + script de lancement
- [ ] Matchmaking simple : file d'attente, création de partie dès N joueurs
- [ ] Mode **2v2** (équipes, réapparition, condition de victoire)

### Phase 3 — Biboule-ball (2 semaines)
- [ ] Mode balle américaine : une balle, deux camps, éliminer en touchant
- [ ] La balle porte **le nom de toutes les personnes éliminées** avec elle (liste affichée sur/près de la balle, grandit au fil de la partie)
- [ ] Règles de reprise de balle et de fin de manche à préciser en jouant

### Phase 4 — Méta et progression (3–4 semaines)
- [ ] Backend : comptes (login anonyme par device puis lien optionnel), trophées, ligues, inventaire
- [ ] **Trophées** gagnés/perdus par partie selon le classement final
- [ ] **Ligues** par palier de trophées
- [ ] **Saison hebdomadaire** : reset du classement chaque semaine (job planifié côté backend), récompenses pour le **top 10**, récompense spéciale pour le **top 3**
- [ ] Écran classement dans le client
- [ ] Anti-triche minimum : tout gain de trophée/coffre est décidé par le serveur, jamais par le client

### Phase 5 — Coffres et skins (2 semaines)
- [ ] **Coffre à maintien** : appui long → le coffre grossit par paliers → récompense meilleure au relâchement (paliers de durée définis dans une `Resource`)
- [ ] Table de loot avec rareté
- [ ] Skins **par paires opposées** : fleur / champignon, pirate / ninja, musique / surf…
- [ ] Skin ultra-rare **chevalier licorne** : garanti au bout de **500 coffres ouverts** (compteur pity côté serveur) en plus d'un tirage très faible
- [ ] Sélection du skin dans le menu, skin = simple swap de sprite/couleur sur `BaseCharacter`

### Phase 6 — Finitions (continu)
- [ ] Remplacer les placeholders par de vrais graphismes
- [ ] Sons, feedback d'impact, écran de fin de partie
- [ ] Équilibrage des classes à partir des données de parties
- [ ] Publication : Play Store / App Store / itch.io ou Steam pour desktop

## 4. Ordre de priorité si le temps manque

1. Phase 0 → 1 → 2 avec **Survivant solo uniquement** : c'est le cœur jouable
2. 2v2
3. Trophées + classement hebdo (donne une raison de revenir)
4. Coffres et skins
5. Biboule-ball

## 5. Risques identifiés

- **Réseau** : le point le plus dur. Commencer par le multijoueur dès la phase 2, pas à la fin, et ne jamais faire confiance au client.
- **Mobile + desktop** : deux systèmes de contrôle à maintenir ; tester sur téléphone réel chaque semaine.
- **Backend méta** : un second système à héberger. Garder l'API minimale (login, résultat de partie, ouvrir coffre, classement).
- **Équilibrage** : 4 classes avec une seule mécanique de charge, c'est simple à comprendre mais chaque classe doit rester utile — prévoir des chiffres modifiables sans recompiler (`.tres`).

## 6. Questions ouvertes

- Biboule-ball : que se passe-t-il quand la balle sort du terrain ? Un porteur touché lâche-t-il la balle ?
- Combien de joueurs en Survivant solo (6 ? 8 ? 10) ?
- Les récompenses hebdo sont-elles des coffres, des skins, de la monnaie ?
- Y a-t-il une monnaie du jeu, ou les coffres viennent uniquement des parties et du classement ?
