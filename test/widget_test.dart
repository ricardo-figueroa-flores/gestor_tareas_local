import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_local/data/app_database.dart';
import 'package:gestor_tareas_local/data/tareas_repository.dart';
import 'package:gestor_tareas_local/main.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late TareasRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = TareasRepository(db);
  });

  // quitar la pantalla antes de cerrar la base para que no queden streams abiertos
  Future<void> limpiar(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
    await tester.runAsync(db.close);
  }

  testWidgets('La pantalla inicial se muestra sin errores', (tester) async {
    await tester.pumpWidget(GestorTareasApp(repositorio: repo));
    expect(find.text('Gestor de tareas'), findsOneWidget);
    expect(find.text('Agregar tarea'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    await limpiar(tester);
  });

  testWidgets('P5: un título con solo espacios no se guarda', (tester) async {
    await tester.pumpWidget(GestorTareasApp(repositorio: repo));

    await tester.enterText(find.byType(TextField), '    ');
    await tester.tap(find.text('Agregar tarea'));
    await tester.pump();

    expect(find.text('Escribe un título para la tarea.'), findsOneWidget);
    final guardadas = await tester.runAsync(repo.obtenerTareas);
    expect(guardadas, isEmpty);
    await limpiar(tester);
  });
}
