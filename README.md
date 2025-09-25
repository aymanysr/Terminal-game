# Terminal-game

A minimal terminal-based Ruby game where you move a player through a map to collect cookies while avoiding bombs and moving enemies.

- Objective: Eat all cookies (`o`) to win.
- Player: `@` — starts with 100 health. Colliding with enemies or bombs reduces health.
- Enemies: `M` — move horizontally and damage 50 to the player.
- Bombs: `x` — stepping on a bomb deals 25 damage.
- [Walls: `#`], [doors: `+`], [open space: `.`], [cookie spawn points: `o`].

Controls
- Move: `w` (up), `s` (down), `a` (left), `d` (right)
- Quit: `q`

Run
```sh
ruby cligame.rb
```
