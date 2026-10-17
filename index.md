---
title: Pokémon Z para macOS
lang: es
---

# Pokémon Z para macOS

[English](README.en.md)

* Repositorio: <https://github.com/ialejandro/pokemon-z-macos-port>
* Documentación: <https://ialejandro.github.io/pokemon-z-macos-port/>

Port no oficial para macOS de **Pokémon Z V2.18**, el fangame de EricLostie. Ejecuta el juego original de Windows en Macs con Apple Silicon gracias a [mkxp-z](https://github.com/mkxp-z/mkxp-z) y a un par de scripts de Ruby que suplen lo que la versión de Windows espera del sistema.

> [!IMPORTANT]
> No tengo ninguna relación ni vínculo con EricLostie, el autor de Pokémon Z, y este proyecto no cuenta con su respaldo. No genera ningún beneficio económico ni lo hará. El juego, su historia, gráficos, música y scripts son suyos. Descarga el juego y sigue las novedades en su página oficial: <https://lostiefangames.blogspot.com/p/pokemon-z.html>
>
> Pokémon es © Nintendo, Game Freak, Creatures y The Pokémon Company.

Este repositorio **no incluye el juego**. Solo contiene los ficheros necesarios para jugar tu propia copia de `Pokémon Z V2.18` en un Mac.

▶ [Vídeo del juego funcionando en macOS](https://ialejandro.github.io/pokemon-z-macos-port/)

## Compatibilidad

| | |
| --- | --- |
| Versión del juego | Pokémon Z V2.18 |
| Arquitectura | Solo arm64 (Apple Silicon: M1 o posterior) |
| macOS | 27 o posterior (compilado con el SDK de macOS 27 y `minos 27.0`) |
| Macs con Intel | No soportados. No se ha compilado binario x86_64 ni universal. |
| Firma | Firma ad hoc, sin notarizar |

Si usas un macOS anterior o un Mac con Intel, tendrás que recompilar mkxp-z tú mismo (ver [Recompilar el motor](#recompilar-el-motor)).

## Instalación

1. Descarga Pokémon Z V2.18 desde la [página del autor](https://lostiefangames.blogspot.com/p/pokemon-z.html) y descomprímelo.
2. Copia todo el contenido de este repositorio dentro de la carpeta del juego y reemplaza los ficheros cuando te lo pida: `Pokemon Z.app`, `Game`, `mkxp.json`, `macos_compat.rb`, `cheats.rb` y `Data/Scripts.rxdata`.
3. La app no está notarizada, así que macOS la bloqueará la primera vez. Haz clic derecho sobre `Pokemon Z.app` y elige **Abrir**, o ejecuta:

   ```sh
   xattr -dr com.apple.quarantine "Pokemon Z.app"
   ```

4. Abre `Pokemon Z.app`, o ejecuta `./Game` desde el Terminal.

La app tiene que quedarse dentro de la carpeta del juego, porque mkxp-z busca `Game.ini`, `Data/`, `Graphics/` y `Audio/` a su lado.

## Cómo está compilado

`Pokemon Z.app/Contents/MacOS/bundle_mkxp-z` es un único binario estático compilado desde la rama `dev` de mkxp-z:

| Componente | Versión |
| --- | --- |
| mkxp-z | 2.4.2 (dev) |
| Ruby | 1.8.7 (MRI legacy, la versión para la que se escribieron los juegos de RPG Maker XP) |
| SDL2 | 2.28.1 |
| ANGLE | chromium/8037, OpenGL ES dibujado sobre Metal |
| FluidSynth | 2.5.0 (MIDI) |
| OpenSSL | 3.0.8 |

Solo enlaza con frameworks del sistema (Metal, AppKit, CoreAudio, GameController...), así que no hace falta instalar nada más.

## Cómo funciona el port

El juego es un proyecto de Pokémon Essentials para RPG Maker XP. Sus scripts llaman directamente a APIs de Windows, así que mkxp-z por sí solo no puede ejecutarlos. `mkxp.json` carga dos scripts antes que el código del juego (`preloadScript`):

| Fichero | Qué hace |
| --- | --- |
| `Pokemon Z.app` | El motor mkxp-z empaquetado como app de macOS (bundle id `pokemonz.macos`). |
| `mkxp.json` | Ajustes de mkxp-z: VSync desactivado, título de la ventana y los scripts de precarga. |
| `macos_compat.rb` | Sustituye `Win32API` por versiones falsas de las llamadas que el juego usa de verdad (tamaño de ventana, posición del cursor, lectura de `Game.ini`, nombre de usuario, registro). El resto devuelve 0. También conserva el código de capturas de mkxp-z cuando el script "Map - Klein" intenta cambiarlo por uno de GDI de Windows, hace que el reinicio de la opción VSync encuentre `./Game`, y activa la entrada de texto solo mientras el juego lee lo que escribes, para que mantener una tecla pulsada no abra el selector de acentos de macOS. En Windows no hace nada. |
| `cheats.rb` | Activa y desactiva el modo debug, ver [Trucos](#trucos-y-modo-debug-opcional). |
| `Game` | Lanzador en shell. La opción VSync del juego lo usa para reiniciar. |
| `Data/Scripts.rxdata` | Los scripts del autor con un único arreglo: en el script `Compiler`, `pbImportNewMaps` pasaba un argumento de más a `sprintf`. Solo falla en modo debug, pero cuando falla el compilador borra todos los ficheros compilados de `Data/`. Lo demás está intacto. |

## Trucos y modo debug (opcional)

Pokémon Essentials incluye un modo debug pensado para quien desarrolla el juego. `cheats.rb` permite activarlo mientras juegas, por si quieres probar cosas: montar un equipo, probar un combate o saltarte un rato de farmeo. No hace falta para jugar.

### Activarlo y desactivarlo

Pulsa **Control + Shift + 0** después de cargar la partida. Un sonido agudo indica que el debug está activo y uno grave que se ha desactivado. Siempre arranca desactivado al abrir el juego.

No lo actives en la pantalla de título. Si el juego arranca en modo debug y encuentra un fichero de `PBS/` más nuevo que sus datos compilados, lo recompila todo, y una compilación fallida deja `Data/` vacío.

Si prefieres no tenerlo, quita `"cheats.rb"` de `preloadScript` en `mkxp.json` (y borra el fichero si quieres). El port funciona igual sin él.

### Qué desbloquea

| Control | Qué hace |
| --- | --- |
| `F9` en el mapa (`fn` + `F9` en la mayoría de teclados de Mac) | Abre el menú de debug |
| Menú de pausa -> "Depurador" | Abre el mismo menú |
| Mantener `Control` + `Shift` al caminar | Atraviesas paredes y bordes del mapa, sin encuentros salvajes |
| Mantener `Control` + `Shift` al empezar un combate | Se salta el combate, salvaje o contra entrenador |
| Mantener `Control` + `Shift` en el mapa de Vuelo | Vuelas a pueblos que aún no has visitado |
| Mantener `Control` + `Shift` en el minijuego de excavación | Los golpes no agrietan la pared |

Los atajos de mantener necesitan las dos teclas. Control solo no hace nada especial, así que no atravesarás una pared sin querer.

El menú principal de debug tiene "Curar Equipo", "Agregar Pokémon", "Agregar Objeto", "Llenar Mochila", "Llenar Cajas de Almacenamiento", "Usar PC" (abre el PC en cualquier sitio), "Saltar a Mapa", "Setear Dinero", "Setear Monedas" y "Setear Medallas", "Eclosión rápida" y "Probar Batalla con Salvaje" o "con Entrenador".

Cada Pokémon tiene además la opción "Depurador" en la pantalla del equipo y en el PC. Desde ahí puedes cambiarle el nivel, la especie, los movimientos, la habilidad, la naturaleza, el género, la forma, si es shiny, la felicidad, los EV e IV, la Poké Ball y el Pokérus, convertirlo en huevo, duplicarlo o borrarlo.

Con el debug activo, los movimientos de campo como Corte, Surf o Fuerza funcionan sin las medallas que normalmente piden, y la mochila deja tirar objetos clave.

### Antes de experimentar

Haz primero una copia de `Game.rxdata`. Todo lo que te des se guarda con la partida, y desactivar el debug no lo quita.

No toques las opciones de editor del menú de debug: "Compilar Datos", "Setear Metadatos", "Setear Encuentros", "Setear Etiquetas de Terrenos", "Editar Tipos de Entrenadores", "Conexiones de Mapas", "Editor de Animaciones", "Extraer Texto" y "Compilar Texto". Reescriben ficheros de `Data/` o `PBS/`, así que un error ahí rompe el juego entero, no solo una partida.

## Partidas guardadas

El juego guarda en su propia carpeta: `Game.rxdata` y `LastSave.dat`. Haz copia de seguridad antes de copiar una versión nueva del juego o del port encima.

Las partidas nunca se suben al repositorio. `.gitignore` las bloquea junto con todo lo que no sea un fichero del port.

## Ficheros que no necesitas en macOS

La descarga original trae ficheros para Windows y Android que la versión de Mac no usa. Puedes borrarlos de tu carpeta si quieres, y ninguno debe subirse a este repositorio:

- **Windows:** `Game.exe`, `Data/Game.exe`, `RGSS102E.dll`, `RGSS102J.dll`, `RGSS104E.dll`, `fluidsynth.dll`, `gif.dll`, `KleinBitmap.dll`, `rgssdisp.dll`, `rubyscreen.dll`, `Partidas Guardadas.lnk`, `Data/Editor.ini`
- **Android (JoiPlay):** `.nomedia`, `1GUIA DE JOIPLAY.pdf`, `configuration.json`, `preload.rb`
- **Logs:** `errorlog.txt`, `Data/debuglog.txt`

No borres `Game.ini`: mkxp-z lee de ahí el título y la ruta de los scripts.

## Trabajar con el port

El repositorio está pensado para clonarse encima de la carpeta del juego. `.gitignore` funciona como lista blanca: lo ignora todo y solo permite los ficheros del port, así que los recursos del autor, los ficheros de Windows y tus partidas no se pueden subir por error.

```sh
cd "Pokemon Z V2.18"            # tu juego descomprimido
git clone https://github.com/ialejandro/pokemon-z-macos-port.git port
cp -R port/. .                  # copia también .git, la carpeta del juego pasa a ser el repo
rm -rf port
```

Los arreglos en Ruby van en `macos_compat.rb`. Se ejecuta antes que los scripts del juego y usa sintaxis de Ruby 1.8 a propósito, así que reinicia el juego después de cada cambio. Los ajustes del motor están en `mkxp.json`, que lista todas las opciones de mkxp-z con comentarios.

Los scripts del juego están en `Data/Scripts.rxdata`, y ese fichero solo se puede editar con RPG Maker XP. Prefiero parchear desde `macos_compat.rb` y tocar lo mínimo el fichero del autor. Cuando algo falla, el error queda en `errorlog.txt`, dentro de la carpeta del juego.

## Recompilar el motor

No se conservó el directorio de compilación original, así que tómalo como punto de partida y no como receta exacta. mkxp-z descarga sus dependencias como subproyectos de Meson, así que solo hacen falta las herramientas de compilación. Son las mismas que se usaron para este binario, instaladas con [Homebrew](https://brew.sh):

```sh
xcode-select --install                                      # clang, git, codesign (si no las tienes ya)
brew install meson ninja cmake pkgconf autoconf automake
```

Meson y Ninja compilan mkxp-z, CMake compila algunas de sus dependencias (SDL2, fmt...), autoconf y automake configuran Ruby 1.8.7, y pkgconf localiza librerías. No hace falta instalar Xcode completo.

Con las herramientas listas:

```sh
git clone -b dev https://github.com/mkxp-z/mkxp-z.git
cd mkxp-z
meson setup build --buildtype=release -Dmri_version=1.8
ninja -C build
```

Si añades `--cross-file macos/meson-arm64.txt`, el binario apunta a macOS 11 en lugar de a la versión en la que compilas, y con `macos/meson-x86_64.txt` se compila para Intel. Esos cross-files llaman a `ccache`, así que instálalo antes con `brew install ccache`. Pon el binario resultante en `Pokemon Z.app/Contents/MacOS/bundle_mkxp-z` y fírmalo ad hoc:

```sh
codesign --force --deep -s - "Pokemon Z.app"
```

Cuando termines, puedes desinstalar las herramientas. El juego no las necesita para funcionar:

```sh
brew uninstall meson cmake pkgconf automake autoconf
brew uninstall ccache                                       # solo si lo instalaste para los cross-files
brew autoremove                                             # quita ninja y m4 si nada más los usa
```

## Licencia

Los ficheros escritos para este port (`macos_compat.rb`, `cheats.rb`, `Game`, `mkxp.json` y la documentación) están bajo [licencia MIT](LICENSE).

Esa licencia no cubre Pokémon Z ni sus scripts (son de EricLostie), Pokémon (Nintendo, Game Freak, Creatures, The Pokémon Company), ni mkxp-z y sus librerías dentro de `Pokemon Z.app`, que mantienen sus propias licencias. mkxp-z es GPLv2+, y como esta compilación incluye OpenSSL, el binario queda bajo GPLv3. Su código fuente está en <https://github.com/mkxp-z/mkxp-z>.