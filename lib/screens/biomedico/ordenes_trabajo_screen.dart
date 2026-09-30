import 'package:flutter/material.dart';
import 'detalle_orden_screen.dart';

class OrdenesTrabajoScreen extends StatelessWidget {
  const OrdenesTrabajoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ordenes = [
      {
        "equipo": "Monitor Multiparámetro",
        "area": "UCI",
        "estado": "Pendiente",
        "fecha": "15/06/2026",
      },
      {
        "equipo": "Desfibrilador",
        "area": "Emergencias",
        "estado": "En proceso",
        "fecha": "14/06/2026",
      },
      {
        "equipo": "Ventilador Mecánico",
        "area": "Quirófano",
        "estado": "Pendiente",
        "fecha": "13/06/2026",
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Órdenes de Trabajo"),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: ordenes.length,
        itemBuilder: (context, index) {
          final orden = ordenes[index];

          Color colorEstado;

          switch (orden["estado"]) {
            case "Pendiente":
              colorEstado = Colors.orange;
              break;
            case "En proceso":
              colorEstado = Colors.blue;
              break;
            case "Finalizado":
              colorEstado = Colors.green;
              break;
            default:
              colorEstado = Colors.grey;
          }

          return Card(
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Row(
                    children: [

                      const CircleAvatar(
                        child: Icon(Icons.medical_services),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Text(
                          orden["equipo"]!,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                    ],
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [

                      const Icon(Icons.location_on,
                          color: Colors.red),

                      const SizedBox(width: 8),

                      Text(
                        "Área: ${orden["area"]}",
                      ),

                    ],
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [

                      Icon(
                        Icons.circle,
                        color: colorEstado,
                        size: 14,
                      ),

                      const SizedBox(width: 8),

                      Text(
                        "Estado: ${orden["estado"]}",
                      ),

                    ],
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [

                      const Icon(Icons.calendar_today),

                      const SizedBox(width: 8),

                      Text(
                        "Fecha: ${orden["fecha"]}",
                      ),

                    ],
                  ),

                  const SizedBox(height: 25),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.assignment),
                      label: const Text("Abrir Orden"),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const DetalleOrdenScreen(incidenciaId: ''),
                          ),
                        );
                      },
                    ),
                  ),

                ],
              ),
            ),
          );
        },
      ),
    );
  }
}