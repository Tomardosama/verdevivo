# Trabajar con Godot y GitHub

## Lo que sí podemos automatizar

ChatGPT puede modificar los archivos versionados del repositorio mediante GitHub. Después, GitHub Desktop sincroniza esos cambios con la carpeta local que Godot abre. Godot ejecuta el proyecto en tu PC.

No existe en esta configuración una conexión de control remoto en vivo al editor Godot: no puedo mover el mouse dentro de tu editor, ver su pantalla continuamente ni ejecutar el juego en tu computadora por mi cuenta. Para verificar el resultado real necesitamos una ejecución local, un registro de errores o capturas que compartas.

## Configuración única

1. Instala Godot 4.7 y GitHub Desktop.
2. En GitHub Desktop, clona `Tomardosama/verdevivo` usando **File > Clone repository**.
3. Selecciona una carpeta fácil de encontrar, por ejemplo `Documentos/Godot/verdevivo`.
4. En Godot Project Manager, pulsa **Import** y selecciona el archivo `project.godot` dentro de esa carpeta.
5. Abre el proyecto. No crees otro proyecto en una carpeta diferente.

## Cada vez que publique una actualización

1. Abre GitHub Desktop y selecciona `verdevivo`.
2. Pulsa **Fetch origin**.
3. Si hay cambios disponibles, pulsa **Pull origin**.
4. Vuelve a Godot. Si no detecta los cambios automáticamente, usa **Project > Reload Current Project**.
5. Ejecuta con **F6** (escena actual) o **F5** (proyecto).
6. Si aparece un error, copia el texto completo del panel **Debugger / Output** y envíamelo.

## Para enviarme información útil de un fallo

- Captura de la ventana del juego.
- Captura del panel Output/Debugger con el error completo.
- Indica qué tecla o acción estabas realizando.
- Si el error aparece al importar, comparte también el primer error de la lista, no solamente el último.

## Reglas para evitar conflictos

- No edites los mismos archivos mientras se prepara una actualización en GitHub.
- Antes de empezar una sesión, haz **Fetch origin** y **Pull origin**.
- Si GitHub Desktop muestra cambios locales sin commit, no hagas Pull a ciegas: comparte una captura para resolverlo sin perder trabajo.
- No borres la carpeta `.godot` manualmente salvo que estemos diagnosticando un problema de caché.
