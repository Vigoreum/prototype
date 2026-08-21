# Tecno-Dash — Proyecto Godot

Juego de microjuegos rápidos estilo *WarioWare*, hecho en Godot. Este documento
explica cómo abrir el proyecto, cómo está organizado y cómo agregar cosas nuevas.
Léelo antes de tocar el código.

\---

## Requisitos

* **Godot 4.6 (stable).** Es importante usar esta versión. Abrir el proyecto con
una versión distinta de Godot puede generar errores o romper escenas.
* No necesitas instalar nada más. El proyecto no depende de plugins externos.

Descarga Godot desde su página oficial (godotengine.org). Busca la versión 4.6.

\---

## Cómo abrir el proyecto

1. Descarga y descomprime el `.zip` del proyecto en una carpeta.
2. Abre Godot 4.6.
3. En el gestor de proyectos, pulsa **Importar** y selecciona el archivo
`project.godot` que está dentro de la carpeta descomprimida.
4. Abre el proyecto. La primera vez, Godot va a regenerar la carpeta `.godot/`
(caché e importación); esto es normal y puede tardar un poco.

Para jugar, pulsa el botón de **Play** (arriba a la derecha) o F5.

\---

## Resolución y estilo visual

* El juego corre en **640×360** (16:9), pensado para pixel art.
* El filtro de texturas está en **Nearest** para que el pixel art se vea nítido.
* Al importar imágenes nuevas de pixel art, revisa que su filtro también sea
Nearest (pestaña *Import*), o se verán borrosas.

\---

## Estructura del proyecto

```
res://
├── core/          Autoloads y recursos centrales (GameManager, etc.)
├── menus/         Pantallas y menús (main menu, pausa, game over, timer bar…)
├── microgames/    Un microjuego por carpeta (usb, delete, draw, wake\_up, correct\_password)
└── assets/        Arte, audio y fuentes
```

Cada microjuego vive en su propia carpeta dentro de `microgames/`, con su escena,
su script y su archivo de datos.

\---

## Cómo funciona el juego (arquitectura)

El juego está orquestado por varios **autoloads** (scripts globales que están
siempre activos). Los más importantes:

* **GameManager** — el cerebro del juego. Maneja la cola de microjuegos, el
sistema de vidas, y decide qué pasa cuando ganas o pierdes un microjuego.
También lleva el registro de todos los microjuegos disponibles.
* **IrisTransition** — las transiciones entre pantallas (el efecto de círculo).
* **AudioManager** — los sonidos de la interfaz (hover y clics de botones).
* **SettingsManager** — la configuración (pantalla completa, etc.), que se guarda
entre sesiones.
* **PauseMenu / OptionsMenu / CountdownOverlay** — el menú de pausa, las opciones
y la cuenta regresiva 3-2-1.

**Flujo de arranque:** pantalla de carga (splash) → pantalla de título → menú
principal.

\---

## El patrón de los microjuegos (lo más importante)

Todos los microjuegos siguen el mismo patrón. Entenderlo es la clave para poder
agregar o modificar microjuegos.

Cada microjuego tiene:

1. **Una escena** (`.tscn`) con la lógica del microjuego.
2. **Un archivo de datos** (`.tres`, un recurso de tipo `MicrogameData`) que define:

   * `title`: el título que se muestra en la intro.
   * `scene`: la escena del microjuego.
   * `duration`: cuántos segundos dura.
   * `show\_cursor`: si el cursor del mouse se ve o no durante ese microjuego
(por ejemplo, en microjuegos que solo usan teclado se desactiva).

El microjuego avisa su resultado al GameManager llamando a una de estas funciones:

* `GameManager.notify\_microgame\_won()` — cuando el jugador gana.
* `GameManager.notify\_microgame\_lost()` — cuando pierde.
* `GameManager.notify\_microgame\_timed\_out()` — cuando se acaba el tiempo.

El temporizador se maneja con la escena **TimerBar** (en `menus/`), que emite una
señal `time\_up` cuando se acaba el tiempo.

\---

## Convención importante: señales desde el editor

En todo el proyecto, las señales se conectan **desde el editor de Godot**
(pestaña *Node → Signals* del nodo), no por código. Por favor, mantén esta
convención al agregar cosas nuevas: hace que las conexiones sean visibles en el
editor y evita sorpresas.

\---

## Cómo agregar un microjuego nuevo

A grandes rasgos:

1. Crea una carpeta nueva en `microgames/` con el nombre del microjuego.
2. Crea la escena del microjuego con su lógica. Cuando el jugador gana/pierde,
llama a la función correspondiente del GameManager (ver arriba).
3. Crea un recurso `MicrogameData` (`.tres`) y rellena sus campos (título,
escena, duración, cursor).
4. Registra el microjuego en el GameManager, agregando la ruta de su `.tres` a la
lista de microjuegos disponibles.
5. Si usa temporizador, instancia la TimerBar y conéctala como en los otros
microjuegos.

Lo más fácil es abrir un microjuego que ya funcione (por ejemplo **DELETE**, que
está completo y ordenado) y usarlo como referencia.

\---

## Estado actual y cosas conocidas

* Hay **5 microjuegos**: USB, DELETE, DRAW, WAKE UP y CORRECT PASSWORD.
* Algunos microjuegos todavía usan arte provisional (placeholder), a la espera de
los assets finales.

\---

## Otros documentos

En el Drive de la célula encontrarás también:

* **GDD (Game Design Document)** — la visión completa del juego.
* **Assets** — el arte del proyecto (incluidos los archivos fuente).

\---

*Proyecto desarrollado por la Célula 21 "Godot" en HubLab. Hecho en Godot 4.6.*

