import 'package:flutter/material.dart';

class DetalleSolicitudScreen extends StatelessWidget {
  final String equipo;
  final String estado;

  const DetalleSolicitudScreen({
    super.key,
    required this.equipo,
    required this.estado,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detalle Solicitud"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            ListTile(
              leading: const Icon(Icons.medical_services),
              title: Text(equipo),
            ),

            ListTile(
              leading: const Icon(Icons.info),
              title: Text("Estado: $estado"),
            ),

            const ListTile(
              leading: Icon(Icons.person),
              title: Text("Biomédico Asignado"),
              subtitle: Text("Ing. Carlos Rojas"),
            ),

            const ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text("Fecha Reporte"),
              subtitle: Text("12/06/2026"),
            ),

            const ListTile(
              leading: Icon(Icons.description),
              title: Text("Descripción"),
              subtitle: Text(
                "El equipo presenta fallas intermitentes."
              ),
            ),

          ],
        ),
      ),
    );
  }
}