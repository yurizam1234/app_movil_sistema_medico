import 'package:flutter/material.dart';
import '../../config/routes.dart';

class DevelopmentScreen extends StatelessWidget {
  const DevelopmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FA),
      appBar: AppBar(
        title: const Text("Modo Desarrollo"),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Módulos",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 1.15,
              children: [

                _card(
                  context,
                  icon: Icons.local_hospital,
                  title: "Enfermera",
                  color: Colors.green,
                  route: AppRoutes.dashboardEnfermera,
                ),

              ],
            ),

            const SizedBox(height: 35),

            const Text(
              "Pantallas disponibles",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            _button(
              context,
              "Registrar Incidencia",
              Icons.report_problem,
              AppRoutes.incidencia,
            ),

            _button(
              context,
              "Mis Solicitudes",
              Icons.assignment,
              AppRoutes.solicitudes,
            ),

            _button(
              context,
              "Inventario",
              Icons.inventory,
              AppRoutes.inventario,
            ),

            _button(
              context,
              "Agenda",
              Icons.calendar_month,
              AppRoutes.agenda,
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required String route,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.pushNamed(context, route);
      },
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            CircleAvatar(
              radius: 28,
              backgroundColor: color.withOpacity(.15),
              child: Icon(
                icon,
                color: color,
                size: 32,
              ),
            ),

            const SizedBox(height: 15),

            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _button(
    BuildContext context,
    String title,
    IconData icon,
    String route,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 55),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
        ),
        onPressed: () {
          Navigator.pushNamed(context, route);
        },
        icon: Icon(icon),
        label: Text(title),
      ),
    );
  }
}