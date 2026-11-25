import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

// tabla de tareas, el bool se guarda como 0/1 en sqlite
@DataClassName('TareaRegistro')
class Tareas extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get titulo => text().withLength(min: 1, max: 200)();
  BoolColumn get completada => boolean().withDefault(const Constant(false))();
  DateTimeColumn get creadaEn => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Tareas])
class AppDatabase extends _$AppDatabase {
  // en los tests le paso una base en memoria
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _abrir());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _abrir() {
    return driftDatabase(
      name: 'gestor_tareas',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  }
}
