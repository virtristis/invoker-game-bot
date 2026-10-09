<div align="center">

<img src="docs/logo.png" width="96" alt="">

# Invoker Game Bot

[![Release](https://img.shields.io/github/v/release/virtristis/invoker-game-bot?style=flat-square&color=8b5cf6&label=release)](https://github.com/virtristis/invoker-game-bot/releases/latest) [![Downloads](https://img.shields.io/github/downloads/virtristis/invoker-game-bot/total?style=flat-square&color=f59e0b)](https://github.com/virtristis/invoker-game-bot/releases) [![Tests](https://img.shields.io/github/actions/workflow/status/virtristis/invoker-game-bot/tests.yml?branch=main&style=flat-square&label=tests)](https://github.com/virtristis/invoker-game-bot/actions/workflows/tests.yml) [![License: MIT](https://img.shields.io/badge/license-MIT-3b82f6?style=flat-square)](LICENSE) [![Website](https://img.shields.io/badge/website-online-22c55e?style=flat-square)](https://virtristis.github.io/invoker-game-bot/)

[English](README.md) · [Русский](README.ru.md) · **Español** · [中文](README.zh.md) · 🌐 [Sitio web](https://virtristis.github.io/invoker-game-bot/)

</div>

Un bot y **entrenador** en AutoHotkey v2 para el entrenador [invoker-game.com](https://invoker-game.com/). Puede jugar solo a la velocidad que elijas, o no tocar nada y mostrarte el combo correcto mientras juegas tú. Funciona con Invoker **New** (10 hechizos) y **Old** (27 hechizos).

<p align="center"><img src="docs/speedrun.gif" width="950" alt="Demo"></p>
<p align="center"><sub>El bot a máxima velocidad en invoker-game.com: primero New, luego Old, con la superposición de la app a la derecha</sub></p>

## 💡 Cómo empezó

Empezó con un bot. Quería ver si un programa podía jugar solo en [invoker-game.com](https://invoker-game.com/), así que escribí uno que lee la página e invoca cada hechizo. Cuando funcionó, me di cuenta de que lo más útil era ayudar a la gente a aprender las combinaciones por sí misma, así que construí mi propio entrenador dentro del bot: el **entrenador** con una superposición que ilumina tus pulsaciones y la **práctica** dentro de la app, con iconos de hechizos, cronómetro y un gráfico de progreso. La idea es sencilla: pulsar exactamente las teclas correctas, sin errores, hasta que las combinaciones te salgan solas.

> [!IMPORTANT]
> **Es un proyecto educativo.** Muestra cómo un programa de escritorio puede leer una página web mediante Windows UI Automation y ayuda a aprender los combos de Invoker. **No** está pensado para batir récords, subir en las clasificaciones ni hacer pasar los resultados del bot como habilidad propia.
> No uses el modo bot con la sesión de récords del sitio iniciada y no envíes partidas del bot. El entrenador existe para que la gente practique con Invoker. Respeta eso y a su autor.

## Funciones

- **Modo bot**: juega **New** y **Old** solo y detecta el modo automáticamente
  - **Control del tiempo**: indica cuántos segundos debe durar la partida o elige la velocidad máxima
  - Pausas aleatorias tipo humano (opcional), reinicio automático
- **Modo entrenador**: no pulsa nada. Una superposición sobre el juego muestra el combo del hechizo actual y resalta las teclas que ya pulsaste. Las teclas brillan con el color de su orbe (Quas azul, Wex morado, Exort ámbar), la siguiente tiene un borde de color y el resto quedan en gris. En New el orden no importa, así que la pista sigue el orden en que pulsas. Ideal para aprender los 27 combos ordenados de Old. Arrastra la superposición para moverla y su esquina o con la rueda del ratón para cambiar el tamaño; clic derecho para restablecer.
- **Práctica sin el sitio**: la app muestra un hechizo con su icono (New u Old), tú juntas los orbes y pulsas R, y cronometra cada hechizo. **Solo mis hechizos débiles** practica solo los hechizos que según tus estadísticas son los más lentos.
- **Estadísticas**: gráfico de progreso (segundos por hechizo a lo largo del tiempo), historial de partidas, mejores tiempos y tus hechizos más lentos
- **Bandeja / modo compacto**: la ventana se oculta y una pequeña superposición muestra lo que hace el bot
- **Tecla de inicio/parada** personalizable (F1 por defecto) y teclas Q/W/E/R personalizadas
- Un sonido y un aviso de Windows al terminar la partida: **5 sonidos incluidos, el sonido de Windows o tu propio archivo, con control de volumen** (botón 🔊 junto al interruptor)
- **Intro**: al iniciar, una ventana tipo consola dibuja a Invoker con puntos braille, enciende Quas · Wex · Exort y lanza **INVOKE!**, y luego se pliega en la ventana principal (clic o Esc para saltarla, `intro=0` en `invoker_bot.ini` la desactiva)
- **Sun Strike al salir**: al cerrar la ventana cae un Sun Strike sobre ella: un círculo dorado, una columna de luz, chispas, y la ventana se consume
- Comprueba si hay actualizaciones al iniciar y **se actualiza con un clic**: pulsa la línea de la cabecera, la app descarga el nuevo `.exe`, comprueba su SHA-256 y se reinicia
- Interfaz oscura en **English, Русский, Español, 中文**
- **3 temas de color** (violeta / azul / dorado) y **diseño vertical u horizontal**: se cambian con los puntos y el botón ⇆ de la cabecera. Los botones se iluminan al pasar el ratón y los interruptores se deslizan con suavidad
- No necesita extensiones ni marcadores

![Interfaz](docs/banner.png)

<details><summary>Estadísticas y gráfico de progreso</summary>

![Estadísticas](docs/stats.png)

</details>

<details><summary>Diseño horizontal</summary>

![Diseño horizontal](docs/horizontal.png)

</details>

<details><summary>Superposición del entrenador</summary>

![Superposición del entrenador](docs/coach-overlay.png)

</details>

## ✨ Inicio y salida

<table>
<tr>
<td align="center" width="50%"><img src="docs/intro.gif" alt="Inicio"><br><sub>Al iniciar: el retrato en puntos braille, Quas · Wex · Exort, INVOKE!</sub></td>
<td align="center" width="50%"><img src="docs/exit.gif" alt="Salida"><br><sub>Al salir: un Sun Strike quema la ventana</sub></td>
</tr>
</table>

## 🎓 Modo entrenador: aprende Invoker de verdad

El bot muestra lo que es posible. **El entrenador es lo que te hace mejorar a *ti*.** No pulsa nada: juegas tú, y él observa y te ayuda.

- **Pista del combo en tiempo real.** Una superposición sobre el juego muestra el hechizo actual y las teclas que necesitas, con los colores de los orbes: Quas azul, Wex morado, Exort ámbar. Empiezas a asociar los hechizos con colores en lugar de leer texto.
- **Respuesta inmediata a cada pulsación.** Las teclas correctas se iluminan, la siguiente tiene un borde de color y las incorrectas no encienden nada. Ves el error en el momento, no al final.
- **Sigue las reglas del juego.** En **New** el orden de los orbes no importa, así que la pista sigue tu orden. En **Old** sí importa (27 combos con orden), y el entrenador comprueba el orden exacto. También recuerda los orbes que ya tienes, como el juego: si ya encajan, solo te dice que pulses **R**.
- **Encuentra tus puntos débiles.** Cada hechizo se cronometra. La ventana de **Estadísticas** muestra tus hechizos más lentos, para que sepas qué practicar.
- **Muestra tu progreso.** Cada partida se guarda con el tiempo y el rango del sitio, así ves cómo vas mejorando.

**Cómo entrenar**
1. Elige **Entrenador**, pulsa **F1**, abre invoker-game.com y pulsa **Start Game**.
2. Juega con normalidad y mira la superposición solo cuando dudes.
3. Tras unas partidas, abre **Estadísticas**, busca tus hechizos más lentos y céntrate en ellos.
4. Cuando tengas los combos en los dedos, minimiza la ventana a la bandeja e intenta no mirar la superposición.

## 🎯 Modo práctica: entrena sin el sitio

<p align="center"><img src="docs/practice-run.gif" width="508" alt="Práctica completa"></p>
<p align="center"><sub>Una práctica completa: 10 hechizos de New, una pista tras una pausa, un error y el resultado</sub></p>

<details><summary>Capturas: New, Old y el resultado</summary>

![Modo práctica](docs/practice.png)

</details>

La práctica funciona entera dentro de la app, así que sirve sin internet y entre partidas.

- **Iconos de hechizos como en el juego.** Ves el icono y el nombre del hechizo, juntas los orbes con Q/W/E e invocas con **R**. ¿Hechizo incorrecto? Cuenta un error y muestra la pista.
- **Pista solo cuando la necesitas.** El combo aparece si piensas más de 2,5 segundos o te equivocas, así practicas recordar, no leer.
- **New u Old.** New usa los 10 hechizos y Old los 27 (allí importa el orden de los orbes), cada vez en orden aleatorio.
- **Solo mis hechizos débiles.** La app toma tus hechizos más lentos de las estadísticas (y los que aún no has practicado) y practica solo esos, cada uno dos veces.
- El tiempo de cada hechizo va a las mismas estadísticas que el entrenador, así que tus puntos débiles se actualizan a medida que mejoras.

Los iconos se descargan una sola vez en `%APPDATA%\InvokerGameBot\icons`: New desde el CDN de Dota 2 de Valve y Old desde invoker-game.com. No forman parte de este repositorio. Sin internet la app dibuja orbes simples.

## Cómo funciona

El sitio ignora los eventos de teclado sintéticos de JavaScript, así que el bot trabaja desde fuera del navegador:

1. Lee el hechizo actual y el progreso (`3 / 10`) de la página mediante **Windows UI Automation**, la API de accesibilidad que usan los lectores de pantalla.
2. Busca la combinación de orbes, por ejemplo *Sun Strike* = `E E E` y después `R`.
3. **Bot:** envía pulsaciones reales con AutoHotkey y las espacia para cumplir el tiempo objetivo.
   **Entrenador:** escucha tus pulsaciones de Q/W/E y resalta cuánto del combo llevas.

## Descargar

- **Lo más fácil:** descarga `InvokerGameBot-vX.Y.Z.exe` desde [Releases](https://github.com/virtristis/invoker-game-bot/releases/latest) y ejecútalo. No necesitas AutoHotkey.
  El `.exe` lo compila [GitHub Actions](.github/workflows/release.yml) directamente desde el código fuente de cada versión.
- **O** descarga `InvokerGameBot-vX.Y.Z-source.zip` (o clona el repositorio) y ejecuta `invoker_bot.ahk` con [AutoHotkey v2](https://www.autohotkey.com/). Necesita la carpeta `lib` al lado.

> [!NOTE]
> El `.exe` no está firmado digitalmente, así que Windows SmartScreen o el antivirus pueden mostrar una advertencia. Es habitual en los scripts de AutoHotkey compilados. Comprueba la suma SHA-256 de las notas de la versión o usa el código fuente `.ahk`.

## Requisitos

- Windows 10/11
- Un navegador basado en Chromium (Chrome, Edge, Brave, Opera…)
- AutoHotkey v2, solo si ejecutas el código fuente `.ahk`

## Uso

1. Ejecuta `InvokerGameBot-vX.Y.Z.exe` (o `invoker_bot.ahk`).
2. Abre [invoker-game.com](https://invoker-game.com/) y elige **New** u **Old**.
3. Elige un modo:
   - **Bot**: ajusta el tiempo (o **Máx. velocidad**), cambia a la pestaña del juego y pulsa **F1**. El bot pulsa Start él solo.
   - **Entrenador**: pulsa **F1**, cambia a la pestaña del juego y pulsa **Start Game**. Después sigue la superposición.
   - **Práctica**: elige New u Old, pulsa **F1** y luego **Espacio** en la ventana de práctica. No hace falta el navegador.
4. Pulsa **F1** otra vez para detenerlo.

La pestaña del juego debe estar activa mientras el bot funciona. Si cambias de ventana, el bot espera a que vuelvas.
La configuración y las estadísticas se guardan en `%APPDATA%\InvokerGameBot` (`invoker_bot.ini`, `invoker_stats.csv`, `invoker_spells.ini`), así que no se crea nada junto al programa.

## Cambios

Consulta [CHANGELOG.md](CHANGELOG.md).

## Aviso legal

Sin relación con invoker-game.com, su autor ni Valve Corporation. Dota 2 e Invoker son marcas registradas de Valve Corporation. Úsalo bajo tu propia responsabilidad.

## Autor

Hecho por **[virtristis](https://github.com/virtristis)**. Licencia [MIT](LICENSE).
