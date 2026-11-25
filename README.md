# Gestor de tareas con SQLite

Práctica de Programación de Dispositivos Móviles (UAA).
Angel Ricardo Figueroa Flores - 479329

App en Flutter para guardar tareas en una base SQLite local. Se pueden agregar, editar, marcar como completadas y borrar, y se quedan guardadas aunque se cierre la app.

## Persistencia

Usé **Drift** con **drift_flutter**. Escogí Drift porque con el mismo código abre la base en Android, iOS, escritorio y web (en web usa sqlite3 en WebAssembly). sqflite no funciona en web, por eso no lo usé.

Tabla `tareas`:

| columna | tipo | notas |
|---|---|---|
| id | INTEGER | llave primaria, autoincremento |
| titulo | TEXT | 1 a 200 caracteres |
| completada | INTEGER | 0 o 1 (Drift lo maneja como bool) |
| creada_en | INTEGER | fecha de creación |

## Archivos

- `lib/data/app_database.dart`: tabla y conexión
- `lib/data/tareas_repository.dart`: insertar, consultar, actualizar y borrar
- `lib/data/validacion.dart`: validación del título
- `lib/screens/tareas_page.dart`: pantalla
- `web/sqlite3.wasm` y `web/drift_worker.js`: necesarios para que funcione en el navegador (sacados de la release de Drift de la misma versión que está en `pubspec.lock`)

## Cómo correrlo

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter test
flutter run -d web-server --web-port=8080   # y abrir localhost:8080 en Chrome
flutter run -d macos
```

En web no uso `-d chrome` para probar la persistencia: ese comando abre Chrome con un perfil temporal nuevo cada vez y por eso parecía que no se guardaba nada. Con `web-server` y mi Chrome normal los datos sí se quedan. El puerto fijo es porque otro puerto es otro origen.

## Pruebas

- `widget_test.dart`: que la pantalla abra y que no se guarde un título vacío.
- `validacion_test.dart`: validación del título.
- `tareas_repository_test.dart`: agregar, editar, cambiar estado, borrar, y que los datos sigan después de cerrar y abrir otra vez el archivo de la base.

## Resultados

| Prueba | macOS | Web (Chrome) | Android |
|---|---|---|---|
| P1 Agregar 3, cerrar y abrir | OK | OK | OK |
| P2 Completar y reiniciar | OK | OK | OK |
| P3 Editar y reiniciar | OK | OK | OK |
| P4 Eliminar y reiniciar | OK | OK | OK |
| P5 Título vacío | OK | OK | OK |
| P6 Recargar y cerrar/abrir pestaña | - | OK | - |

Plataformas probadas: macOS, web (Chrome) y Android (teléfono físico).

Plataformas previstas sin probar: iOS, Windows y Linux.
