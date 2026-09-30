import 'package:flutter/material.dart';

class OrdenesScreen extends StatelessWidget {
  const OrdenesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Órdenes de Servicio")),
      body: const Center(
        child: Text("Pantalla de Órdenes de Servicio"),
      ),
    );
  }
}
