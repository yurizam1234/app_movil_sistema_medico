import 'package:flutter/material.dart';

class RecorridoDiarioScreen extends StatelessWidget {
  const RecorridoDiarioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Recorrido Diario")),
      body: const Center(
        child: Text("Pantalla de Recorrido Diario"),
      ),
    );
  }
}
