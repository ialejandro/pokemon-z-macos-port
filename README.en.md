# Pokémon Z for macOS

[Español](README.md)

* Repository: <https://github.com/ialejandro/pokemon-z-macos-port>
* Docs: <https://ialejandro.github.io/pokemon-z-macos-port/en.html>

An unofficial macOS port of **Pokémon Z V2.18**, the fan game by EricLostie. It runs the original Windows game on Apple Silicon Macs through [mkxp-z](https://github.com/mkxp-z/mkxp-z), with a few small Ruby scripts that cover what the Windows build expects from the system.

> [!IMPORTANT]
> I have no relation or connection with EricLostie, the author of Pokémon Z. This project is not endorsed by them. It makes no money and never will. The game, its story, graphics, music and scripts are theirs. Get the game, news and support from the official page: <https://lostiefangames.blogspot.com/p/pokemon-z.html>
>
> Pokémon is © Nintendo, Game Freak, Creatures and The Pokémon Company.

This repository **does not include the game**. It only contains the files needed to run your own copy of Pokémon Z V2.18 on a Mac.

▶ [Video of the game running on macOS](https://ialejandro.github.io/pokemon-z-macos-port/en.html)

## Compatibility

| | |
| --- | --- |
| Game version | Pokémon Z V2.18 |
| Architecture | arm64 only (Apple Silicon: M1 or newer) |
| macOS | 27 or newer (built against the macOS 27 SDK with `minos 27.0`) |
| Intel Macs | Not supported. No x86_64 or universal binary was built. |
| Signature | Ad-hoc signed, not notarized |

If you are on an older macOS or an Intel Mac, you will need to rebuild mkxp-z yourself (see [Rebuilding the engine](#rebuilding-the-engine)).

## Installing

1. Download Pokémon Z V2.18 from the [author's page](https://lostiefangames.blogspot.com/p/pokemon-z.html) and unzip it.
2. Copy everything from this repository into the game folder, replacing files when asked: `Pokemon Z.app`, `Game`, `mkxp.json`, `macos_compat.rb`, `cheats.rb` and `Data/Scripts.rxdata`.
3. The app is not notarized, so macOS will block it the first time. Either right-click `Pokemon Z.app` and choose **Open**, or run:

   ```sh
   xattr -dr com.apple.quarantine "Pokemon Z.app"
   ```

4. Open `Pokemon Z.app`, or run `./Game` from Terminal.

The app has to stay inside the game folder. mkxp-z looks for `Game.ini`, `Data/`, `Graphics/` and `Audio/` next to it.

## How it was built

`Pokemon Z.app/Contents/MacOS/bundle_mkxp-z` is a single static binary built from the `dev` branch of mkxp-z:

| Component | Version |
| --- | --- |
| mkxp-z | 2.4.2 (dev) |
| Ruby | 1.8.7 (legacy MRI, the version RPG Maker XP games were written for) |
| SDL2 | 2.28.1 |
| ANGLE | chromium/8037, OpenGL ES drawn through Metal |
| FluidSynth | 2.5.0 (MIDI) |
| OpenSSL | 3.0.8 |

It only links against system frameworks (Metal, AppKit, CoreAudio, GameController...), so nothing else needs to be installed.

## How the port works

The game is a Pokémon Essentials project for RPG Maker XP. Its scripts call Windows APIs directly, so a bare mkxp-z can't run them. `mkxp.json` loads two scripts before the game's own code (`preloadScript`):

| File | What it does |
| --- | --- |
| `Pokemon Z.app` | The mkxp-z engine, packaged as a macOS app (bundle id `pokemonz.macos`). |
| `mkxp.json` | mkxp-z settings: VSync off, window title, and the preload scripts. |
| `macos_compat.rb` | Replaces `Win32API` with fake versions of the calls the game actually uses (window size, cursor position, reading `Game.ini`, user name, registry). Everything else returns 0. It also keeps mkxp-z's own screenshot code when the "Map - Klein" script tries to swap in a Windows GDI one, makes the VSync option's restart find `./Game`, and switches text input on only while the game is reading typed text, so holding a key doesn't open the macOS accent picker. It does nothing on Windows. |
| `cheats.rb` | Debug mode toggle, see [Cheats](#cheats-and-debug-mode-optional). |
| `Game` | Shell launcher. The in-game VSync option restarts the game with it. |
| `Data/Scripts.rxdata` | The author's scripts with one fix: in the `Compiler` script, `pbImportNewMaps` passed an extra argument to `sprintf`. That only raises an error in debug mode, but when it does the compiler deletes every compiled file in `Data/`. Everything else is untouched. |

## Cheats and debug mode (optional)

Pokémon Essentials ships with a debug mode meant for the game's developer. `cheats.rb` lets you switch it on while playing, in case you want to try things out: build a team, test a battle, or skip a grind. You don't need it to play.

### Turning it on and off

Press **Control + Shift + 0** after loading your save. A high-pitched sound means debug is on, a low one means it's off. It always starts off when you open the game.

Don't turn it on at the title screen. If the game starts in debug mode and finds a `PBS/` file newer than its compiled data, it recompiles everything, and a failed compile leaves `Data/` empty.

If you'd rather not have it at all, remove `"cheats.rb"` from `preloadScript` in `mkxp.json` (and delete the file if you like). The port works the same without it.

### What it unlocks

| Control | What it does |
| --- | --- |
| `F9` on the map (`fn` + `F9` on most Mac keyboards) | Opens the debug menu |
| Pause menu -> "Depurador" | Opens the same menu |
| Hold `Control` + `Shift` while walking | Walk through walls and off map edges, with no wild encounters |
| Hold `Control` + `Shift` when a battle starts | Skips the battle, wild or trainer |
| Hold `Control` + `Shift` on the Fly map | Fly to towns you haven't visited yet |
| Hold `Control` + `Shift` in the mining minigame | Swings don't crack the wall |

The hold shortcuts need both keys. Control on its own does nothing special, so you won't walk through a wall by accident.

The game is in Spanish, so the menus are too. The main debug menu has "Curar Equipo" (heal party), "Agregar Pokémon" (add Pokémon), "Agregar Objeto" (add item), "Llenar Mochila" (fill bag), "Llenar Cajas de Almacenamiento" (fill PC boxes), "Usar PC" (open the PC anywhere), "Saltar a Mapa" (warp), "Setear Dinero", "Setear Monedas" and "Setear Medallas" (money, coins, badges), "Eclosión rápida" (hatch eggs now), and "Probar Batalla con Salvaje" or "con Entrenador" (start a test battle).

Each Pokémon also gets a "Depurador" option in the party screen and in the PC. From there you can change its level, species, moves, ability, nature, gender, form, shininess, happiness, EVs and IVs, Poké Ball and Pokérus, turn it into an egg, duplicate it or delete it.

With debug on, field moves like Cut, Surf and Strength also work without the badges they normally need, and the bag lets you throw away key items.

### Before you experiment

Back up `Game.rxdata` first. Anything you give yourself gets saved with the game, and turning debug off doesn't take it away.

Leave the editor entries in the debug menu alone: "Compilar Datos", "Setear Metadatos", "Setear Encuentros", "Setear Etiquetas de Terrenos", "Editar Tipos de Entrenadores", "Conexiones de Mapas", "Editor de Animaciones", "Extraer Texto" and "Compilar Texto". They rewrite files in `Data/` or `PBS/`, so a mistake there breaks the game itself, not just one save.

## Saves

The game saves into its own folder: `Game.rxdata` and `LastSave.dat`. Back them up before copying a new version of the game or the port over your folder.

Saves are never committed. `.gitignore` blocks them along with everything else that isn't a port file.

## Files you don't need on macOS

The original download ships files for Windows and Android that the Mac version never uses. You can delete them from your game folder if you like, and none of them belong in this repository:

- **Windows:** `Game.exe`, `Data/Game.exe`, `RGSS102E.dll`, `RGSS102J.dll`, `RGSS104E.dll`, `fluidsynth.dll`, `gif.dll`, `KleinBitmap.dll`, `rgssdisp.dll`, `rubyscreen.dll`, `Partidas Guardadas.lnk`, `Data/Editor.ini`
- **Android (JoiPlay):** `.nomedia`, `1GUIA DE JOIPLAY.pdf`, `configuration.json`, `preload.rb`
- **Logs:** `errorlog.txt`, `Data/debuglog.txt`

Keep `Game.ini`. mkxp-z reads the title and the scripts path from it.

## Working on the port

The repository is meant to be cloned on top of a game folder. `.gitignore` works as a whitelist: it ignores everything and then allows only the port files, so the author's assets, the Windows files and your saves can't be committed by accident.

```sh
cd "Pokemon Z V2.18"            # your unzipped game
git clone https://github.com/ialejandro/pokemon-z-macos-port.git port
cp -R port/. .                  # copies .git too, so the game folder becomes the repo
rm -rf port
```

Ruby fixes go in `macos_compat.rb`. It runs before the game scripts and is written in Ruby 1.8 syntax on purpose, so restart the game after each change. Engine settings live in `mkxp.json`, which lists every mkxp-z option with comments.

The game's own scripts are in `Data/Scripts.rxdata`, and only RPG Maker XP can edit that file. I'd rather patch things from `macos_compat.rb` and touch the author's file as little as possible. When something crashes, the error ends up in `errorlog.txt` in the game folder.

## Rebuilding the engine

The original build tree wasn't kept, so treat this as a starting point rather than an exact recipe. mkxp-z downloads its dependencies as Meson subprojects, so you only need the build tools. These are the same ones used for this binary, installed with [Homebrew](https://brew.sh):

```sh
xcode-select --install                                      # clang, git, codesign (skip if you have them)
brew install meson ninja cmake pkgconf autoconf automake
```

Meson and Ninja build mkxp-z, CMake builds some of its dependencies (SDL2, fmt...), autoconf and automake configure Ruby 1.8.7, and pkgconf finds libraries. You don't need the full Xcode.

With the tools in place:

```sh
git clone -b dev https://github.com/mkxp-z/mkxp-z.git
cd mkxp-z
meson setup build --buildtype=release -Dmri_version=1.8
ninja -C build
```

Adding `--cross-file macos/meson-arm64.txt` targets macOS 11 instead of the version you're building on, and `macos/meson-x86_64.txt` builds for Intel. Those cross files call `ccache`, so install it first with `brew install ccache`. Put the resulting binary in `Pokemon Z.app/Contents/MacOS/bundle_mkxp-z` and sign it ad hoc:

```sh
codesign --force --deep -s - "Pokemon Z.app"
```

Once you're done you can remove the tools. The game doesn't need them to run:

```sh
brew uninstall meson cmake pkgconf automake autoconf
brew uninstall ccache                                       # only if you installed it for the cross files
brew autoremove                                             # removes ninja and m4 if nothing else uses them
```

## License

The files written for this port (`macos_compat.rb`, `cheats.rb`, `Game`, `mkxp.json` and the docs) are under the [MIT license](LICENSE).

That license does not cover Pokémon Z or its scripts (EricLostie's), Pokémon (Nintendo, Game Freak, Creatures, The Pokémon Company), or mkxp-z and its libraries inside `Pokemon Z.app`, which keep their own licenses. mkxp-z is GPLv2+, and because this build includes OpenSSL the binary falls under GPLv3. Its source code is at <https://github.com/mkxp-z/mkxp-z>.
