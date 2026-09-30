import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/app_colors.dart';

// ═══════════════════════════════════════════════════════════════════════
//  GESTIÓN DE ÁREAS
// ═══════════════════════════════════════════════════════════════════════
class GestionAreasScreen extends StatefulWidget {
  const GestionAreasScreen({super.key});

  @override
  State<GestionAreasScreen> createState() => _GestionAreasScreenState();
}

class _GestionAreasScreenState extends State<GestionAreasScreen> {
  final _searchCtrl = TextEditingController();
  String _query     = '';
  String? _hospital; // hospital seleccionado para filtrar

  static const _areasDefault = [
    'Emergencias', 'UCI', 'Quirófano', 'Laboratorio',
    'Rayos X', 'Consulta Externa', 'Hospitalización',
    'Pediatría', 'Neonatología', 'Cardiología',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _abrirFormulario({Map<String, dynamic>? data, String? docId}) {
    final nombreCtrl = TextEditingController(text: data?['nombre'] ?? '');
    String? hospitalSel = data?['hospitalId'] ?? data?['hospital'];
    bool guardando = false;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 16, 24,
              MediaQuery.of(ctx2).viewInsets.bottom + 24),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(docId == null ? 'Nueva área' : 'Editar área',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 20),

                // Nombre del área
                TextFormField(
                  controller: nombreCtrl,
                  validator: (v) => v?.isEmpty == true ? 'Requerido' : null,
                  decoration: InputDecoration(
                    labelText: 'Nombre del área',
                    prefixIcon: const Icon(Icons.grid_view_outlined,
                        size: 20, color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.divider)),
                  ),
                ),

                const SizedBox(height: 10),

                // Sugerencias rápidas
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _areasDefault.map((a) => ActionChip(
                    label: Text(a,
                        style: const TextStyle(fontSize: 12)),
                    onPressed: () => nombreCtrl.text = a,
                    backgroundColor: AppColors.background,
                  )).toList(),
                ),

                const SizedBox(height: 16),

                // Hospital asociado
                const Text('Hospital',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 8),
                FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  future: FirebaseFirestore.instance
                      .collection('hospitales')
                      .orderBy('nombre')
                      .get(),
                  builder: (_, snap) {
                    final hosp = snap.data?.docs ?? [];
                    if (hosp.isEmpty) {
                      return const Text(
                          'No hay hospitales registrados',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12));
                    }
                    return DropdownButtonFormField<String>(
                      value: hospitalSel,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: AppColors.divider)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                      hint: const Text('Seleccionar hospital'),
                      items: hosp
                          .map((d) => DropdownMenuItem(
                                value: d.id,
                                child: Text(d.data()['nombre'] ?? d.id),
                              ))
                          .toList(),
                      onChanged: (v) => setModal(() => hospitalSel = v),
                    );
                  },
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: guardando
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setModal(() => guardando = true);
                            try {
                              final d = {
                                'nombre':     nombreCtrl.text.trim(),
                                'hospitalId': hospitalSel ?? '',
                              };
                              if (docId == null) {
                                await FirebaseFirestore.instance
                                    .collection('areas')
                                    .add(d);
                              } else {
                                await FirebaseFirestore.instance
                                    .collection('areas')
                                    .doc(docId)
                                    .update(d);
                              }
                              if (ctx2.mounted) Navigator.pop(ctx2);
                            } catch (_) {
                              setModal(() => guardando = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: guardando
                        ? const CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2)
                        : Text(docId == null ? 'Crear área' : 'Guardar',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _eliminar(String docId, String nombre) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar área'),
        content: Text('¿Eliminar el área "$nombre"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance.collection('areas').doc(docId).delete();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          title: const Text('Áreas',
              style: TextStyle(fontWeight: FontWeight.bold)),
          elevation: 0,
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _abrirFormulario(),
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Nueva área', style: TextStyle(color: Colors.white)),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Buscar área...',
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.textSecondary),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 16),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('areas')
                    .orderBy('nombre')
                    .snapshots(),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = (snap.data?.docs ?? []).where((d) {
                    final n = (d.data()['nombre'] ?? '').toString().toLowerCase();
                    return _query.isEmpty || n.contains(_query);
                  }).toList();

                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.grid_view_outlined,
                              size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          const Text('No hay áreas registradas',
                              style: TextStyle(color: AppColors.textSecondary)),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () => _abrirFormulario(),
                            icon: const Icon(Icons.add),
                            label: const Text('Crear primera área'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final data = docs[i].data();
                      final id   = docs[i].id;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        tileColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.grid_view_outlined,
                              color: AppColors.accent, size: 20),
                        ),
                        title: Text(data['nombre'] ?? 'Área',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary)),
                        subtitle: data['hospitalId'] != null
                            ? FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                                future: FirebaseFirestore.instance
                                    .collection('hospitales')
                                    .doc(data['hospitalId'] as String)
                                    .get(),
                                builder: (_, s) => Text(
                                    s.data?.data()?['nombre'] ?? '—',
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12)),
                              )
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  color: AppColors.primary, size: 20),
                              onPressed: () =>
                                  _abrirFormulario(data: data, docId: id),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: AppColors.error, size: 20),
                              onPressed: () =>
                                  _eliminar(id, data['nombre'] ?? ''),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
}
