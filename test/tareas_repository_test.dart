import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_local/data/app_database.dart';
import 'package:gestor_tareas_local/data/tareas_repository.dart';
import 'package:gestor_tareas_local/data/validacion.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('CRUD sobre SQLite (base en memoria)', () {
    late AppDatabase db;
    late TareasRepository repo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = TareasRepository(db);
    });

    tearDown(() => db.close());

    test('INSERT y SELECT: guarda el título limpio y pendiente', () async {
      final id = await repo.agregar('  Comprar cable UTP ');
      final tareas = await repo.obtenerTareas();

      expect(tareas, hasLength(1));
      expect(tareas.first.id, id);
      expect(tareas.first.titulo, 'Comprar cable UTP');
      expect(tareas.first.completada, isFalse);
    });

    test('no inserta títulos vacíos', () async {
      await expectLater(
        () => repo.agregar('   '),
        throwsA(isA<TituloInvalidoException>()),
      );
      expect(await repo.obtenerTareas(), isEmpty);
    });

    test('UPDATE de título y de estado', () async {
      final id = await repo.agregar('Tarea vieja');

      expect(await repo.editarTitulo(id, 'Tarea nueva'), isTrue);
      expect(await repo.cambiarEstado(id, true), isTrue);

      final tarea = (await repo.obtenerTareas()).single;
      expect(tarea.titulo, 'Tarea nueva');
      expect(tarea.completada, isTrue);
    });

    test('DELETE por id y id inexistente', () async {
      final a = await repo.agregar('A');
      final b = await repo.agregar('B');

      expect(await repo.eliminar(a), isTrue);
      expect(await repo.eliminar(9999), isFalse);

      final ids = (await repo.obtenerTareas()).map((t) => t.id);
      expect(ids, [b]);
    });

    test('el stream emite de nuevo después de una escritura', () async {
      final emisiones = repo.observarTareas().map((l) => l.length);
      final esperado = expectLater(emisiones, emitsInOrder([0, 1]));
      await Future<void>.delayed(Duration.zero);
      await repo.agregar('Nueva');
      await esperado;
    });
  });

  test('persistencia: los datos siguen ahí al cerrar y reabrir el archivo',
      () async {
    final dir = await Directory.systemTemp.createTemp('gestor_tareas_');
    final archivo = File('${dir.path}/prueba.sqlite');
    addTearDown(() => dir.delete(recursive: true));

    var db = AppDatabase(NativeDatabase(archivo));
    var repo = TareasRepository(db);
    final uno = await repo.agregar('Uno');
    final dos = await repo.agregar('Dos');
    final tres = await repo.agregar('Tres');
    await repo.cambiarEstado(uno, true);
    await repo.editarTitulo(dos, 'Dos (editada)');
    await repo.eliminar(tres);
    await db.close();

    // se vuelve a abrir el mismo archivo
    db = AppDatabase(NativeDatabase(archivo));
    repo = TareasRepository(db);
    final tareas = await repo.obtenerTareas();
    await db.close();

    expect(tareas.map((t) => t.titulo), ['Uno', 'Dos (editada)']);
    expect(tareas.first.completada, isTrue);
    expect(tareas.any((t) => t.id == tres), isFalse);
  });
}
