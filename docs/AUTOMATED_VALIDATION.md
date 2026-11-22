# Validación automática con Godot

El workflow `.github/workflows/godot-check.yml` descarga Godot 4.7 y realiza dos comprobaciones en cada push a main/ramas feat y en cada pull request:

1. Importa el proyecto en modo headless y analiza los scripts.
2. Inicia el proyecto durante unos segundos para detectar errores de arranque.

La validación automática no sustituye probar controles, interfaz, iluminación ni rendimiento visual en una computadora.
