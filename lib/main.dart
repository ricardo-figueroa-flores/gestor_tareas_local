import 'package:flutter/material.dart';

import 'data/tareas_repository.dart';
import 'screens/tareas_page.dart';

void main() {
  runApp(const GestorTareasApp());
}

class GestorTareasApp extends StatelessWidget {
  final TareasRepository? repositorio;

  const GestorTareasApp({super.key, this.repositorio});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestor de tareas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: TareasPage(repositorio: repositorio),
    );
  }
}
