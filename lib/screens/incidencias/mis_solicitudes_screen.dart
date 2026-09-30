import 'package:flutter/material.dart';
import 'detalle_solicitud_screen.dart';

class MisSolicitudesScreen extends StatelessWidget {
  const MisSolicitudesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final solicitudes = [
      {
        "equipo": "Monitor Multiparámetro",
        "estado": "Pendiente"
      },
      {
        "equipo": "Desfibrilador",
        "estado": "En Proceso"
      },
      {
        "equipo": "Electrocardiógrafo",
        "estado": "Resuelta"
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis Solicitudes"),
      ),
      body: ListView.builder(
        itemCount: solicitudes.length,
        itemBuilder: (context, index) {
          final item = solicitudes[index];

          return Card(
            child: ListTile(
              leading: const Icon(Icons.assignment),
              title: Text(item["equipo"]!),
              subtitle: Text(item["estado"]!),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetalleSolicitudScreen(
                      equipo: item["equipo"]!,
                      estado: item["estado"]!,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}