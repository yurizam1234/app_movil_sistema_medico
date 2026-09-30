import 'package:flutter/material.dart';

class DashboardGerenteScreen extends StatelessWidget {
  const DashboardGerenteScreen({super.key});

  Widget buildCard(
    String titulo,
    IconData icono,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icono),
        title: Text(titulo),
        trailing: const Icon(Icons.arrow_forward_ios),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard Gerente"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            buildCard(
              "Indicadores",
              Icons.analytics,
            ),
            buildCard(
              "Equipos Críticos",
              Icons.medical_services,
            ),
            buildCard(
              "Reportes",
              Icons.bar_chart,
            ),
            buildCard(
              "Personal Técnico",
              Icons.people,
            ),
          ],
        ),
      ),
    );
  }
}