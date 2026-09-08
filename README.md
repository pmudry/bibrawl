# Bibrawl

Jeu de combat multijoueur type arène, mobile et desktop. Moteur : Godot 4.6.

- Concept : [desc.md](desc.md)
- Plan de développement : [PLAN.md](PLAN.md)

## Lancer

Ouvrir le dossier dans Godot 4.6 et appuyer sur F5, ou en ligne de commande :

```powershell
godot --path . 
```

Contrôles :

| | Déplacement | Tir |
|---|---|---|
| Clavier / souris | WASD ou flèches | clic gauche vers la souris, espace devant soi |
| Tactile | joystick gauche | joystick droit : viser puis relâcher ; tap = tir devant soi ; tap ailleurs = tir vers le point touché |

Deux bots servent de cibles : un rose immobile, un vert qui erre au hasard.
Chacun réapparaît 3 s après avoir été détruit.

## Niveaux

On commence au niveau 0. Chaque ennemi tué donne +1 niveau, jusqu'à 9999. Le niveau
fait monter PV max, régénération, dégâts, portée, vitesse et cadence de tir, avec une
courbe logarithmique (gros gains au début, petits ensuite). Les chiffres sont dans
[level_stats.gd](scripts/characters/level_stats.gd).

Mourir ne fait pas perdre de niveau : on réapparaît au point de départ avec tous ses PV.
Les bots naissent avec leur propre niveau (celui du joueur, -2 à +3), affiché au-dessus d'eux.

Les joysticks n'apparaissent que sur écran tactile. Pour les tester à la souris sur desktop,
cocher `always_visible` sur `HUD/MoveJoystick` et `HUD/AimJoystick`.

## Exporter

```powershell
godot --headless --path . --export-debug "Windows Desktop"
godot --headless --path . --export-debug "Android"
```

Les builds sortent dans `build/`. L'export Android nécessite le SDK Android et un JDK 17 configurés dans les préférences de l'éditeur.
