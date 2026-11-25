class TituloInvalidoException implements Exception {
  final String mensaje;
  const TituloInvalidoException(this.mensaje);

  @override
  String toString() => mensaje;
}

const int largoMaximoTitulo = 200;

String validarTitulo(String? titulo) {
  final limpio = (titulo ?? '').trim();
  if (limpio.isEmpty) {
    throw const TituloInvalidoException('Escribe un título para la tarea.');
  }
  if (limpio.length > largoMaximoTitulo) {
    throw const TituloInvalidoException(
      'El título no puede pasar de $largoMaximoTitulo caracteres.',
    );
  }
  return limpio;
}
