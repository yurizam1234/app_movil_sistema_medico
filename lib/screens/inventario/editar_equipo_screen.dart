import 'package:flutter/material.dart';
import '../../models/equipo.dart';

class EditarEquipoScreen extends StatefulWidget {
  final Equipo equipo;

  const EditarEquipoScreen({super.key, required this.equipo});

  @override
  State<EditarEquipoScreen> createState() => _EditarEquipoScreenState();
}

class _EditarEquipoScreenState extends State<EditarEquipoScreen> {
  late TextEditingController nombreCtrl;
  late TextEditingController areaCtrl;
  late TextEditingController solicitanteCtrl;

  @override
  void initState() {
    super.initState();
    nombreCtrl = TextEditingController(text: widget.equipo.nombre);
    areaCtrl = TextEditingController(text: widget.equipo.area);
    solicitanteCtrl =
        TextEditingController(text: widget.equipo.solicitante);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Editar Equipo")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: nombreCtrl),
            TextField(controller: areaCtrl),
            TextField(controller: solicitanteCtrl),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                widget.equipo.nombre = nombreCtrl.text;
                widget.equipo.area = areaCtrl.text;
                widget.equipo.solicitante = solicitanteCtrl.text;
                Navigator.pop(context);
              },
              child: const Text("Guardar Cambios"),
            )
          ],
        ),
      ),
    );
  }
}
