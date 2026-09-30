import 'package:flutter/material.dart';
import '../../config/routes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Widget buildCard(
    BuildContext context,
    String titulo,
    IconData icono,
    String ruta,
  ) {
    return Expanded(
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, ruta),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 25,
              horizontal: 10,
            ),
            child: Column(
              children: [
                Icon(
                  icono,
                  size: 40,
                  color: const Color(0xFF0D2D6C),
                ),
                const SizedBox(height: 10),
                Text(
                  titulo,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: const Text("MedControl"),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Image.asset(
              'assets/images/medico.webp',
              height: 130,
            ),

            const SizedBox(height: 15),

            const Text(
              "Hola, Usuario 👋",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D2D6C),
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              "Bienvenido a MedControl",
              style: TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 25),

            Row(
              children: [
                buildCard(
                  context,
                  "Inventario",
                  Icons.inventory,
                  AppRoutes.inventario,
                ),
                const SizedBox(width: 10),

                buildCard(
                    context,
                    "Registrar Incidencia",
                    Icons.warning_amber,
                    AppRoutes.incidencia,
                  ),

                const SizedBox(width: 10),
                buildCard(
                  context,
                  "Órdenes",
                  Icons.build,
                  AppRoutes.ordenes,
                ),
                buildCard(
                  context,
                  "Mis Solicitudes",
                  Icons.list_alt,
                  AppRoutes.solicitudes,
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                buildCard(
                  context,
                  "Recorrido",
                  Icons.checklist,
                  AppRoutes.recorrido,
                ),
                const SizedBox(width: 10),
                buildCard(
                  context,
                  "Agenda",
                  Icons.calendar_month,
                  AppRoutes.agenda,
                ),
              ],
            ),

            const SizedBox(height: 25),

            Card(
              color: const Color(0xFFE8F4FD),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.smart_toy,
                      size: 50,
                      color: Color(0xFF0D2D6C),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Asistente MedControl",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      "¿Necesita ayuda con un equipo médico?",
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}