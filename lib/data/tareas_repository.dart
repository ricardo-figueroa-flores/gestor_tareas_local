import 'package:drift/drift.dart';

import '../models/tarea.dart';
import 'app_database.dart';
import 'validacion.dart';

class TareasRepository {
  final AppDatabase _db;

  TareasRepository(this._db);

  // con watch() la lista se actualiza sola cuando cambia la tabla
  Stream<List<Tarea>> observarTareas() {
    final consulta = _db.select(_db.tareas)
      ..orderBy([
        (t) => OrderingTerm.asc(t.completada),
        (t) => OrderingTerm.asc(t.id),
      ]);
    return consulta.watch().map((filas) => filas.map(_aModelo).toList());
  }

  Future<List<Tarea>> obtenerTareas() async {
    final filas = await (_db.select(_db.tareas)
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
    return filas.map(_aModelo).toList();
  }

  Future<int> agregar(String titulo) {
    final limpio = validarTitulo(titulo);
    return _db.into(_db.tareas).insert(TareasCompanion.insert(titulo: limpio));
  }

  // regresan false si no existe el id
  Future<bool> editarTitulo(int id, String nuevoTitulo) async {
    final limpio = validarTitulo(nuevoTitulo);
    final filas = await (_db.update(_db.tareas)..where((t) => t.id.equals(id)))
        .write(TareasCompanion(titulo: Value(limpio)));
    return filas > 0;
  }

  Future<bool> cambiarEstado(int id, bool completada) async {
    final filas = await (_db.update(_db.tareas)..where((t) => t.id.equals(id)))
        .write(TareasCompanion(completada: Value(completada)));
    return filas > 0;
  }

  Future<bool> eliminar(int id) async {
    final filas =
        await (_db.delete(_db.tareas)..where((t) => t.id.equals(id))).go();
    return filas > 0;
  }

  Future<void> cerrar() => _db.close();

  Tarea _aModelo(TareaRegistro fila) => Tarea(
        id: fila.id,
        titulo: fila.titulo,
        completada: fila.completada,
      );
}
