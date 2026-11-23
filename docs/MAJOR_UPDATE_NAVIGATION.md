# TRush: navegación, perfiles y combate sísmico

## Resumen

Esta continuación integra navegación del mundo, radar, perfiles locales, personalización de la interfaz y una nueva fase de combate para el Coloso. El inicio del proyecto abre ahora un menú funcional; la escena de juego sigue disponible en `scenes/main/main.tscn`.

El trabajo se realizó sobre `feat/trush-ecosystem-progression-vacuum-expansion`, sin cambiar de rama ni crear un commit. Se preservaron los cambios locales previos y los ejecutables de Godot.

## Señales y mapa

- Los rótulos de las regiones usan un componente reutilizable que interpola el giro horizontal hacia el jugador sin inclinar el texto.
- El minimapa top-down usa la misma extensión de mundo y puntos del arroyo que el generador. Incluye orientación del jugador, reciclaje, tienda, cabaña, mirador, regiones, rutas, agua y jefes con icono distinto.
- Al activar el radar, aparecen marcadores rojos solo para instancias vivas del grupo de residuos normales. Los jefes nunca entran en esa colección. El mapa actualiza posiciones y retira residuos recogidos cada 0,18 s.
- Cerca del Mirador de Raíces, **R** cuesta $1000 una sola vez. El estado bloqueado, desbloqueado y activo se guarda en el perfil. El alcance actual es 90 m y el círculo se muestra en el mapa.

## Perfiles y opciones

`TRushProfileManager` administra tres archivos independientes bajo `user://trush_profile_1.cfg` a `user://trush_profile_3.cfg`, con versión de esquema 3. La escena de menú permite crear, cargar y reemplazar perfiles. El borrado de una partida tiene su propio diálogo de confirmación y solo elimina el archivo de ese espacio.

Se guardan dinero, bolsa, mejoras, habilidades, XP, limpieza, especies y zonas, día y fruta, posición/orientación/salud del jugador, radar, jefes y encuentros divididos, residuos soltados por jefes todavía pendientes y un cursor separado de residuos iniciales recogidos. Separar ese cursor evita que recoger residuos de jefes haga desaparecer residuos iniciales tras cargar.

Los archivos dañados o de una versión futura se muestran como no cargables y permanecen intactos. Los datos antiguos `user://trush_save.cfg` se copian una sola vez al espacio 1 si este está vacío; el archivo original no se borra. La personalización y las opciones se guardan globalmente en `user://trush_settings.cfg`, por lo que aplican a los tres perfiles.

Las opciones incluyen volumen maestro/música/efectos, sensibilidad, brillo, FOV, MSAA, tamaño de ventana, pantalla completa y tema. **MODIFICAR UI** permite cambiar textos predefinidos, escala, tema y color de acento, con vista previa y restauración de valores iniciales. La edición se limita a esos campos: no admite scripts ni propiedades libres.

## Daño y combate

- La barra de salud permanece visible. Cada golpe actualiza los HP, superpone un flash rojo breve y muestra un indicador; los tweens previos se cancelan con seguridad cuando llegan golpes seguidos.
- Los jefes fijan su dirección al iniciar un ataque, muestran una zona de peligro en forma de cono sobre el suelo y la intensifican durante la espera configurable. Una onda viaja dentro de ese mismo ángulo y alcance; la prueba verifica que no daña fuera del cono y que impacta dentro.
- El proyectil lento ya no forma parte del ataque activo de estos jefes. Los scripts y la escena del proyectil anterior quedan en el repositorio, pero la configuración actual no los instancia.
- Al llegar a cero, el mayor jefe ejecuta su colapso y genera exactamente dos mini-jefes con IDs, salud y posiciones independientes. La recompensa final del encuentro espera hasta derrotar ambos. La fase, hijos pendientes y posiciones se guardan para evitar duplicarlos al cargar.
- Los residuos extraídos siguen siendo `TrashPickup`: llenan la bolsa normal, respetan su capacidad y cuentan para limpieza al recogerlos. La cola limita la generación a dos instancias por fotograma. No se depositan recompensas directamente en la bolsa.

## Geometría y colisiones

- El arroyo usa una única cinta triangular continua con extremos extendidos y ancho acotado; la máscara circular del shader se desactiva solo en esa cinta. El estanque conserva su máscara circular y sus ondas contenidas.
- Las mallas decorativas de las sierras ya no crean cuerpos de colisión que atrapen al jugador. El suelo y los objetos interactivos conservan sus colisiones existentes.
- El generador de agua, los puntos compartidos del mapa y el minimapa usan una fuente de coordenadas común para mantener alineación.

## Rendimiento y límites conocidos

- El minimapa se actualiza con intervalo y solo consulta residuos cuando el radar está activo. La vegetación repetida existente sigue agrupada en `MultiMesh`; las sierras decorativas no crean cuerpos físicos.
- Las opciones de calidad actualmente cambian MSAA. No hay pistas de música ni banco de efectos de audio en el proyecto, así que los controles correspondientes se guardan y aplican a buses cuando existan, pero no producen audio audible con el contenido actual.
- Los residuos iniciales se reconstruyen de forma determinista a partir del número recogido, no mediante una lista persistida de IDs y posiciones individuales. Los residuos liberados por jefes sí conservan registros individuales.
- La prueba de sierras confirma que no se generan cuerpos estáticos en las mallas decorativas; no se hizo una sesión de movimiento WASD sobre el terreno en renderer gráfico.
- Agua, fauna, señales y jefes siguen usando materiales y geometría procedural. No se midieron FPS ni draw calls en hardware objetivo. No se completó inspección gráfica en esta sesión; por ello, la legibilidad del mapa, el cono, las animaciones, el agua y la composición visual requieren revisión en un renderer gráfico.

## Validación ejecutada

Con Godot 4.7.2:

```powershell
& '.\Godot.exe' --headless --editor --path . --quit
& '.\Godot.exe' --headless --path . --quit-after 420
& '.\Godot.exe' --headless --path . res://scenes/main/main.tscn --quit-after 420
& '.\Godot.exe' --headless --path . res://tests/major_update_smoke.tscn
git diff --check
```

La importación, el menú (420 fotogramas), la escena de juego (420 fotogramas) y la prueba de integración finalizaron con código 0. La prueba terminó con **32 comprobaciones aprobadas**: espacios separados, nombre/carga, confirmación de borrado, cursor de limpieza, radar y marcadores, agua y colisiones decorativas, cono sísmico, división/carga del encuentro y salud/respawn/bolsa. `git diff --check` pasó; Git solo mostró avisos de normalización LF/CRLF en archivos modificados.

Godot no pudo acceder al almacén de certificados de Windows ni crear `user://logs`; el editor tampoco pudo guardar sus preferencias globales de usuario. El renderer dummy/headless notificó RIDs de Jolt, mallas e instancias al cerrar el proceso de prueba. Esos avisos no equivalen a una medida de rendimiento y se registran como limitación de la validación headless.

La inspección gráfica no se completó: la captura de las ventanas Godot existentes expiró dos veces. Se lanzó una instancia nueva con `--path .`, que sigue activa, pero Windows no expone una ventana para ese proceso (`MainWindowHandle=0`); no se puede confirmar visualmente qué se ve en pantalla. Las ventanas anteriores no se reiniciaron ni cerraron. No se midieron FPS/draw calls. No hay commit nuevo; HEAD permanece en `33e83bd`.
