import 'package:flutter/material.dart';

class EquipoDetalleScreen extends StatelessWidget {
  final String nombreEquipo;

  const EquipoDetalleScreen({
    super.key,
    required this.nombreEquipo,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: Text(nombreEquipo),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Center(
              child: Image.asset(
                'assets/images/equipos.jpg',
                height: 180,
              ),
            ),

            const SizedBox(height: 20),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Text(
                      "Información General",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const Divider(),

                    _info("Código", "EQ-001"),
                    _info("Marca", "Philips"),
                    _info("Modelo", "IntelliVue MX550"),
                    _info("Serie", "MX550-2026"),
                    _info("Área", "UCI"),
                    _info("Estado", "Operativo"),

                  ],
                ),
              ),
            ),

            const SizedBox(height: 15),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Text(
                      "Biomédico Responsable",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const Divider(),

                    ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.person),
                      ),
                      title: const Text("Ing. Carlos Rojas"),
                      subtitle: const Text(
                        "Especialista en Equipos Críticos",
                      ),
                    ),

                  ],
                ),
              ),
            ),

            const SizedBox(height: 15),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Text(
                      "Mantenimiento",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const Divider(),

                    _info(
                      "Último mantenimiento",
                      "12/06/2026",
                    ),

                    _info(
                      "Próximo mantenimiento",
                      "12/12/2026",
                    ),

                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton.icon(
                onPressed: () {
                  // Luego iremos al historial
                },

                icon: const Icon(Icons.history),

                label: const Text(
                  "Ver Historial Completo",
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget _info(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              titulo,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Expanded(
            flex: 3,
            child: Text(valor),
          ),
        ],
      ),
    );
  }
}