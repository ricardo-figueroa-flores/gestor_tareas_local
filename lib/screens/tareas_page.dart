import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../data/tareas_repository.dart';
import '../data/validacion.dart';
import '../models/tarea.dart';

class TareasPage extends StatefulWidget {
  final TareasRepository? repositorio;

  const TareasPage({super.key, this.repositorio});

  @override
  State<TareasPage> createState() => _TareasPageState();
}

class _TareasPageState extends State<TareasPage> {
  final TextEditingController _tituloController = TextEditingController();

  late final TareasRepository _repo;
  late final bool _repoPropio;

  // se crea una vez en initState para no consultar en build()
  late final Stream<List<Tarea>> _tareas;

  @override
  void initState() {
    super.initState();
    _repoPropio = widget.repositorio == null;
    _repo = widget.repositorio ?? TareasRepository(AppDatabase());
    _tareas = _repo.observarTareas();
  }

  Future<void> _agregarTarea() async {
    final ok = await _ejecutar(
      () => _repo.agregar(_tituloController.text),
      'No se pudo guardar la tarea.',
    );
    if (ok) _tituloController.clear();
  }

  Future<void> _alternarCompletada(Tarea tarea, bool completada) async {
    await _ejecutar(
      () => _repo.cambiarEstado(tarea.id, completada),
      'No se pudo actualizar el estado.',
    );
  }

  Future<void> _editarTarea(Tarea tarea) async {
    final nuevoTitulo = await showDialog<String>(
      context: context,
      builder: (context) => _DialogoEditar(tituloActual: tarea.titulo),
    );
    if (nuevoTitulo == null) return;
    await _ejecutar(
      () => _repo.editarTitulo(tarea.id, nuevoTitulo),
      'No se pudo cambiar el título.',
    );
  }

  Future<void> _eliminarTarea(Tarea tarea) async {
    final ok = await _ejecutar(
      () => _repo.eliminar(tarea.id),
      'No se pudo eliminar la tarea.',
    );
    if (ok) _mostrarMensaje('Tarea "${tarea.titulo}" eliminada');
  }

  Future<bool> _ejecutar(
    Future<Object?> Function() operacion,
    String mensajeError,
  ) async {
    try {
      final resultado = await operacion();
      if (resultado == false) {
        _mostrarMensaje('La tarea ya no existe.');
        return false;
      }
      return true;
    } on TituloInvalidoException catch (e) {
      _mostrarMensaje(e.mensaje);
    } catch (e, st) {
      debugPrint('Error de almacenamiento: $e\n$st');
      _mostrarMensaje(mensajeError);
    }
    return false;
  }

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  void dispose() {
    _tituloController.dispose();
    if (_repoPropio) _repo.cerrar();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestor de tareas')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _tituloController,
              maxLength: largoMaximoTitulo,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _agregarTarea(),
              decoration: const InputDecoration(
                labelText: 'Nueva tarea',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _agregarTarea,
              icon: const Icon(Icons.add),
              label: const Text('Agregar tarea'),
            ),
            const SizedBox(height: 12),
            const Text('Mis tareas', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<List<Tarea>>(
                stream: _tareas,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('No se pudo leer la base de datos.'),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final tareas = snapshot.data!;
                  if (tareas.isEmpty) {
                    return const Center(
                      child: Text('Todavía no hay tareas guardadas'),
                    );
                  }
                  return ListView.builder(
                    itemCount: tareas.length,
                    itemBuilder: (context, index) {
                      final tarea = tareas[index];
                      return Card(
                        child: ListTile(
                          leading: Checkbox(
                            value: tarea.completada,
                            onChanged: (valor) {
                              if (valor != null) {
                                _alternarCompletada(tarea, valor);
                              }
                            },
                          ),
                          title: Text(
                            tarea.titulo,
                            style: tarea.completada
                                ? const TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                  )
                                : null,
                          ),
                          subtitle: Text(
                            'ID: ${tarea.id} · '
                            '${tarea.completada ? 'Completada' : 'Pendiente'}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Editar',
                                icon: const Icon(Icons.edit),
                                onPressed: () => _editarTarea(tarea),
                              ),
                              IconButton(
                                tooltip: 'Eliminar',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _eliminarTarea(tarea),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogoEditar extends StatefulWidget {
  final String tituloActual;
  const _DialogoEditar({required this.tituloActual});

  @override
  State<_DialogoEditar> createState() => _DialogoEditarState();
}

class _DialogoEditarState extends State<_DialogoEditar> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.tituloActual);
  String? _error;

  void _guardar() {
    try {
      Navigator.of(context).pop(validarTitulo(_controller.text));
    } on TituloInvalidoException catch (e) {
      setState(() => _error = e.mensaje);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar tarea'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: largoMaximoTitulo,
        onSubmitted: (_) => _guardar(),
        decoration: InputDecoration(labelText: 'Título', errorText: _error),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _guardar, child: const Text('Guardar')),
      ],
    );
  }
}
