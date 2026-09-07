# Bibrawl

Jeu de combat multijoueur type arène, mobile et desktop. Moteur : Godot 4.6.

- Concept : [desc.md](desc.md)
- Plan de développement : [PLAN.md](PLAN.md)

## Lancer

Ouvrir le dossier dans Godot 4.6 et appuyer sur F5, ou en ligne de commande :

```powershell
godot --path . 
```

Contrôles : WASD / flèches. Sur écran tactile, un joystick virtuel apparaît en bas à gauche.
Pour le tester à la souris sur desktop, cocher `always_visible` sur le nœud `HUD/VirtualJoystick`.

## Exporter

```powershell
godot --headless --path . --export-debug "Windows Desktop"
godot --headless --path . --export-debug "Android"
```

Les builds sortent dans `build/`. L'export Android nécessite le SDK Android et un JDK 17 configurés dans les préférences de l'éditeur.
