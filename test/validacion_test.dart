import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_local/data/validacion.dart';

void main() {
  group('validarTitulo', () {
    test('quita los espacios de los extremos', () {
      expect(validarTitulo('  Estudiar SQLite  '), 'Estudiar SQLite');
    });

    test('rechaza vacío, solo espacios y null', () {
      for (final valor in ['', '   ', '\n\t', null]) {
        expect(
          () => validarTitulo(valor),
          throwsA(isA<TituloInvalidoException>()),
          reason: 'valor: "$valor"',
        );
      }
    });

    test('rechaza títulos de más de $largoMaximoTitulo caracteres', () {
      expect(
        () => validarTitulo('a' * (largoMaximoTitulo + 1)),
        throwsA(isA<TituloInvalidoException>()),
      );
      expect(validarTitulo('a' * largoMaximoTitulo).length, largoMaximoTitulo);
    });
  });
}
