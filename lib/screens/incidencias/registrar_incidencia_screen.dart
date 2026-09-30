import 'package:flutter/material.dart';

class RegistrarIncidenciaScreen extends StatefulWidget {
  const RegistrarIncidenciaScreen({super.key});

  @override
  State<RegistrarIncidenciaScreen> createState() =>
      _RegistrarIncidenciaScreenState();
}

class _RegistrarIncidenciaScreenState
    extends State<RegistrarIncidenciaScreen> {

  String? equipo;
  String? tipoIncidencia;
  String? nivelUrgencia;

  final descripcionCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Registrar Incidencia"),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [

            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: "Equipo Médico",
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: "Monitor Multiparámetro",
                  child: Text("Monitor Multiparámetro"),
                ),
                DropdownMenuItem(
                  value: "Desfibrilador",
                  child: Text("Desfibrilador"),
                ),
                DropdownMenuItem(
                  value: "Electrocardiógrafo",
                  child: Text("Electrocardiógrafo"),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  equipo = value;
                });
              },
            ),

            const SizedBox(height: 15),

            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: "Tipo de Incidencia",
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: "Falla Eléctrica",
                  child: Text("Falla Eléctrica"),
                ),
                DropdownMenuItem(
                  value: "Daño Físico",
                  child: Text("Daño Físico"),
                ),
                DropdownMenuItem(
                  value: "Calibración",
                  child: Text("Calibración"),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  tipoIncidencia = value;
                });
              },
            ),

            const SizedBox(height: 15),

            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: "Nivel de Urgencia",
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: "Alta",
                  child: Text("Alta"),
                ),
                DropdownMenuItem(
                  value: "Media",
                  child: Text("Media"),
                ),
                DropdownMenuItem(
                  value: "Baja",
                  child: Text("Baja"),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  nivelUrgencia = value;
                });
              },
            ),

            const SizedBox(height: 15),

            TextField(
              controller: descripcionCtrl,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: "Descripción del problema",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            OutlinedButton.icon(
              onPressed: () {
                // Luego conectaremos cámara
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text(
                "Adjuntar Fotografía",
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 55,

              child: ElevatedButton.icon(
                onPressed: () {

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Incidencia registrada correctamente",
                      ),
                    ),
                  );

                },
                icon: const Icon(Icons.send),
                label: const Text(
                  "Enviar Solicitud",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}