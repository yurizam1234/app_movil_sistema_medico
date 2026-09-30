import 'package:flutter/material.dart';
import 'equipo_detalle_screen.dart';

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  final TextEditingController searchCtrl = TextEditingController();

  final List<Map<String, String>> equipos = [
    {
      'equipo': 'Servicio',
      'area': 'UCI',
      'solicitante': 'Juan Pérez',
    },
    {
      'equipo': 'Electrocardiógrafo',
      'area': 'Emergencias',
      'solicitante': 'María López',
    },
    {
      'equipo': 'Desfibrilador',
      'area': 'Quirófano',
      'solicitante': 'Carlos Rojas',
    },
    {
      'equipo':'Bomba Infucion',
      'area':'urgencias',
      'solicitante':'maria Gomes',
    },
  ];

  List<Map<String, String>> equiposFiltrados = [];

  @override
  void initState() {
    super.initState();
    equiposFiltrados = equipos;
  }

  void filtrarEquipos(String query) {
    setState(() {
      equiposFiltrados = equipos.where((equipo) {
        final texto = query.toLowerCase();
        return equipo['equipo']!.toLowerCase().contains(texto) ||
            equipo['area']!.toLowerCase().contains(texto) ||
            equipo['solicitante']!.toLowerCase().contains(texto);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Inventario de Equipos")),
      body: Column(
        children: [
          // 🔍 BUSCADOR
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: searchCtrl,
              onChanged: filtrarEquipos,
              decoration: InputDecoration(
                hintText: 'Buscar equipo, área o solicitante',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // 📋 LISTA
          Expanded(
            child: ListView.builder(
              itemCount: equiposFiltrados.length,
              itemBuilder: (context, index) {
                final equipo = equiposFiltrados[index];

                return Card(
                  child: ListTile(
                    title: Text(equipo['equipo']!),
                    subtitle: Text(
                      'Área: ${equipo['area']}\n Solicitante: ${equipo['solicitante']} \n fecha: ${equipo['fecha']}',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EquipoDetalleScreen(
                            nombreEquipo: equipo['equipo']!,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
