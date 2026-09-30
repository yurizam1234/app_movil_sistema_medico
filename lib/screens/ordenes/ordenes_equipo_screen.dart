import 'package:flutter/material.dart';

class OrdenesEquipoScreen extends StatelessWidget {
  final String nombreEquipo;

  const OrdenesEquipoScreen({
    super.key,
    required this.nombreEquipo,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Órdenes - $nombreEquipo'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Crear nueva orden
        },
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: const [
          OrdenCard(
            titulo: 'Mantenimiento preventivo',
            fecha: '2025-02-04',
            estado: 'Pendiente',
            color: Colors.orange,
          ),
          OrdenCard(
            titulo: 'Revisión eléctrica',
            fecha: '2025-01-18',
            estado: 'En proceso',
            color: Colors.blue,
          ),
          OrdenCard(
            titulo: 'Calibración anual',
            fecha: '2024-12-20',
            estado: 'No realizada',
            color: Colors.red,
          ),
          OrdenCard(
            titulo: 'Cambio de piezas',
            fecha: '2024-12-10',
            estado: 'Completado',
            color: Colors.green,
          ),
        ],
      ),
    );
  }
}

/////

class OrdenCard extends StatelessWidget {
  final String titulo;
  final String fecha;
  final String estado;
  final Color color;

  const OrdenCard({
    super.key,
    required this.titulo,
    required this.fecha,
    required this.estado,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(Icons.build, color: color),
        title: Text(
          titulo,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Fecha: $fecha'),
        trailing: Chip(
          label: Text(
            estado,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: color,
        ),
        onTap: () {
          // Detalle de orden
        },
      ),
    );
  }
}
