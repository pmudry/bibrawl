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

Les joysticks n'apparaissent que sur écran tactile. Pour les tester à la souris sur desktop,
cocher `always_visible` sur `HUD/MoveJoystick` et `HUD/AimJoystick`.

## Exporter

```powershell
godot --headless --path . --export-debug "Windows Desktop"
godot --headless --path . --export-debug "Android"
```

Les builds sortent dans `build/`. L'export Android nécessite le SDK Android et un JDK 17 configurés dans les préférences de l'éditeur.
