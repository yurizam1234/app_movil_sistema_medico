import 'package:flutter/material.dart';


class ReportarMantenimientoScreen extends StatefulWidget {
  const ReportarMantenimientoScreen({super.key});

  @override
  State<ReportarMantenimientoScreen> createState() =>
      _ReportarMantenimientoScreenState();
}

class _ReportarMantenimientoScreenState
    extends State<ReportarMantenimientoScreen> {

  final observacionCtrl = TextEditingController();

  String tipo = "Preventivo";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reportar Mantenimiento"),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Equipo",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Monitor Multiparámetro",
              ),
              enabled: false,
            ),

            const SizedBox(height: 20),

            const Text(
              "Tipo de mantenimiento",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            RadioListTile(
              value: "Preventivo",
              groupValue: tipo,
              title: const Text("Preventivo"),
              onChanged: (value) {
                setState(() {
                  tipo = value.toString();
                });
              },
            ),

            RadioListTile(
              value: "Correctivo",
              groupValue: tipo,
              title: const Text("Correctivo"),
              onChanged: (value) {
                setState(() {
                  tipo = value.toString();
                });
              },
            ),

            const SizedBox(height: 15),

            const Text(
              "Observaciones",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: observacionCtrl,
              maxLines: 6,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Describa el mantenimiento realizado...",
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 55,

              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text("Guardar Reporte"),
                onPressed: () {

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Reporte guardado correctamente",
                      ),
                    ),
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