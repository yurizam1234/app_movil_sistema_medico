import 'package:flutter/material.dart';
import 'detalle_orden_screen.dart';

class MantenimientoScreen extends StatefulWidget {
  const MantenimientoScreen({super.key});

  @override
  State<MantenimientoScreen> createState() =>
      _MantenimientoScreenState();
}

class _MantenimientoScreenState
    extends State<MantenimientoScreen> {

  final TextEditingController diagnosticoController =
      TextEditingController();

  final TextEditingController actividadesController =
      TextEditingController();

  final TextEditingController observacionesController =
      TextEditingController();

  String estadoFinal = "Operativo";

  final List<String> repuestos = [];

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Mantenimiento"),
      ),

      body: SingleChildScrollView(

        padding: const EdgeInsets.all(16),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            const Text(
              "Información del Equipo",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(

                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: const [

                    Text("Equipo: Monitor Multiparámetro"),

                    SizedBox(height: 8),

                    Text("Código: EQ-00125"),

                    SizedBox(height: 8),

                    Text("Serie: MP-985214"),

                    SizedBox(height: 8),

                    Text("Área: UCI"),

                    SizedBox(height: 8),

                    Text("Estado: Pendiente"),

                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              "Diagnóstico",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: diagnosticoController,
              maxLines: 5,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText:
                    "Escriba el diagnóstico...",
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              "Actividades Realizadas",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: actividadesController,
              maxLines: 6,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText:
                    "Describa las actividades...",
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              "Repuestos Utilizados",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton.icon(

              onPressed: () {

                setState(() {

                  repuestos.add("Cable ECG");

                });

              },

              icon: const Icon(Icons.add),

              label: const Text("Agregar Repuesto"),

            ),

            const SizedBox(height: 10),

            ListView.builder(

              shrinkWrap: true,

              physics:
                  const NeverScrollableScrollPhysics(),

              itemCount: repuestos.length,

              itemBuilder: (context, index) {

                return Card(

                  child: ListTile(

                    leading: const Icon(Icons.build),

                    title: Text(repuestos[index]),

                    trailing: IconButton(

                      icon: const Icon(Icons.delete),

                      onPressed: () {

                        setState(() {

                          repuestos.removeAt(index);

                        });

                      },

                    ),

                  ),

                );

              },

            ),

            const SizedBox(height: 25),

            const Text(
              "Fotografías",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Row(

              children: [

                Expanded(

                  child: ElevatedButton.icon(

                    onPressed: () {},

                    icon: const Icon(Icons.camera_alt),

                    label: const Text("Tomar Foto"),

                  ),

                ),

                const SizedBox(width: 10),

                Expanded(

                  child: ElevatedButton.icon(

                    onPressed: () {},

                    icon: const Icon(Icons.photo),

                    label: const Text("Galería"),

                  ),

                ),

              ],

            ),

            const SizedBox(height: 25),

            const Text(
              "Estado Final",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            DropdownButtonFormField(

              value: estadoFinal,

              items: const [

                DropdownMenuItem(
                  value: "Operativo",
                  child: Text("Operativo"),
                ),

                DropdownMenuItem(
                  value: "En Observación",
                  child: Text("En Observación"),
                ),

                DropdownMenuItem(
                  value: "Fuera de Servicio",
                  child: Text("Fuera de Servicio"),
                ),

                DropdownMenuItem(
                  value: "Requiere Repuesto",
                  child: Text("Requiere Repuesto"),
                ),

              ],

              onChanged: (value) {

                setState(() {

                  estadoFinal = value!;

                });

              },

            ),

            const SizedBox(height: 25),

            const Text(
              "Observaciones",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            TextField(

              controller: observacionesController,

              maxLines: 5,

              decoration: const InputDecoration(

                border: OutlineInputBorder(),

              ),

            ),

            const SizedBox(height: 30),

            SizedBox(

              width: double.infinity,

              height: 50,

              child: ElevatedButton.icon(

                icon: const Icon(Icons.save),

                label: const Text("Guardar Borrador"),

                onPressed: () {

                  ScaffoldMessenger.of(context).showSnackBar(

                    const SnackBar(

                      content:
                          Text("Borrador guardado"),

                    ),

                  );

                },

              ),

            ),

            const SizedBox(height: 15),

            SizedBox(

              width: double.infinity,

              height: 55,

              child: ElevatedButton.icon(

                style: ElevatedButton.styleFrom(

                  backgroundColor: Colors.green,

                  foregroundColor: Colors.white,

                ),

                icon: const Icon(Icons.check_circle),

                label: const Text("Finalizar Orden"),

                onPressed: () {

                  showDialog(

                    context: context,

                    builder: (_) {

                      return AlertDialog(

                        title:
                            const Text("Orden Finalizada"),

                        content: const Text(
                          "El mantenimiento fue registrado correctamente.",
                        ),

                        actions: [

                          TextButton(

                            onPressed: () {

                              Navigator.pop(context);

                              Navigator.pop(context);

                            },

                            child: const Text("Aceptar"),

                          ),

                        ],

                      );

                    },

                  );

                },

              ),

            ),

            const SizedBox(height: 20),

          ],

        ),

      ),

    );

  }
}