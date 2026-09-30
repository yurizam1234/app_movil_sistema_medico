import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/app_colors.dart';

// ═══════════════════════════════════════════════════════════════════════
//  GESTIÓN DE HOSPITALES
// ═══════════════════════════════════════════════════════════════════════
class GestionHospitalesScreen extends StatefulWidget {
  const GestionHospitalesScreen({super.key});

  @override
  State<GestionHospitalesScreen> createState() =>
      _GestionHospitalesScreenState();
}

class _GestionHospitalesScreenState extends State<GestionHospitalesScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _abrirFormulario({Map<String, dynamic>? data, String? docId}) {
    final nombreCtrl       = TextEditingController(text: data?['nombre']       ?? '');
    final direccionCtrl    = TextEditingController(text: data?['direccion']    ?? '');
    final ciudadCtrl       = TextEditingController(text: data?['ciudad']       ?? '');
    final departamentoCtrl = TextEditingController(text: data?['departamento'] ?? '');
    final telefonoCtrl     = TextEditingController(text: data?['telefono']     ?? '');
    final responsableCtrl  = TextEditingController(text: data?['responsable']  ?? '');
    final formKey          = GlobalKey<FormState>();
    bool guardando         = false;

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
            child: SingleChildScrollView(
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
                  Text(docId == null ? 'Nuevo hospital' : 'Editar hospital',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 20),

                  _campo(nombreCtrl,      'Nombre del hospital', Icons.local_hospital_outlined, (v) => v?.isEmpty == true ? 'Requerido' : null),
                  _campo(responsableCtrl, 'Responsable',         Icons.person_outline,         null),
                  _campo(direccionCtrl,   'Dirección',           Icons.location_on_outlined,   null),
                  _campo(ciudadCtrl,      'Ciudad',              Icons.location_city_outlined,  null),
                  _campo(departamentoCtrl,'Departamento',        Icons.map_outlined,            null),
                  _campo(telefonoCtrl,    'Teléfono',            Icons.phone_outlined,          null, tipo: TextInputType.phone),

                  const SizedBox(height: 20),

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
                                  'nombre':       nombreCtrl.text.trim(),
                                  'responsable':  responsableCtrl.text.trim(),
                                  'direccion':    direccionCtrl.text.trim(),
                                  'ciudad':       ciudadCtrl.text.trim(),
                                  'departamento': departamentoCtrl.text.trim(),
                                  'telefono':     telefonoCtrl.text.trim(),
                                };
                                if (docId == null) {
                                  d['fechaCreacion'] = DateTime.now().toIso8601String();
                                  await FirebaseFirestore.instance
                                      .collection('hospitales')
                                      .add(d);
                                } else {
                                  await FirebaseFirestore.instance
                                      .collection('hospitales')
                                      .doc(docId)
                                      .update(d);
                                }
                                if (ctx2.mounted) Navigator.pop(ctx2);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(docId == null
                                          ? 'Hospital creado'
                                          : 'Hospital actualizado'),
                                      backgroundColor: AppColors.resolved,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
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
                          : Text(
                              docId == null ? 'Crear hospital' : 'Guardar cambios',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _campo(
    TextEditingController ctrl,
    String label,
    IconData icon,
    String? Function(String?)? validator, {
    TextInputType tipo = TextInputType.text,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          controller:   ctrl,
          keyboardType: tipo,
          validator:    validator,
          decoration: InputDecoration(
            labelText:  label,
            prefixIcon: Icon(icon, size: 20, color: AppColors.primary),
            filled:     true,
            fillColor:  AppColors.background,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.divider)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      );

  void _confirmarEliminar(String docId, String nombre) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar hospital'),
        content: Text('¿Eliminar "$nombre"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance
                  .collection('hospitales')
                  .doc(docId)
                  .delete();
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Eliminar',
                style: TextStyle(color: Colors.white)),
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
          title: const Text('Hospitales',
              style: TextStyle(fontWeight: FontWeight.bold)),
          elevation: 0,
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _abrirFormulario(),
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Nuevo hospital',
              style: TextStyle(color: Colors.white)),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Buscar hospital...',
                  prefixIcon: const Icon(Icons.search,
                      color: AppColors.textSecondary),
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
                    .collection('hospitales')
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
                          Icon(Icons.local_hospital_outlined,
                              size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          const Text('No hay hospitales registrados',
                              style: TextStyle(
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final data  = docs[i].data();
                      final id    = docs[i].id;
                      return _HospitalCard(
                        data:       data,
                        onEditar:   () => _abrirFormulario(data: data, docId: id),
                        onEliminar: () => _confirmarEliminar(id, data['nombre'] ?? ''),
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

class _HospitalCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onEditar, onEliminar;
  const _HospitalCard(
      {required this.data, required this.onEditar, required this.onEliminar});

  @override
  Widget build(BuildContext context) {
    final nombre       = data['nombre']       ?? 'Hospital';
    final ciudad       = data['ciudad']       ?? '—';
    final departamento = data['departamento'] ?? '';
    final responsable  = data['responsable']  ?? '—';
    final telefono     = data['telefono']     ?? '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.local_hospital_outlined,
                      color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nombre,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.textPrimary)),
                      Text('$ciudad${departamento.isNotEmpty ? ' · $departamento' : ''}',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert,
                      color: AppColors.textSecondary),
                  onSelected: (v) {
                    if (v == 'editar')   onEditar();
                    if (v == 'eliminar') onEliminar();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'editar',
                        child: Row(children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ])),
                    const PopupMenuItem(
                        value: 'eliminar',
                        child: Row(children: [
                          Icon(Icons.delete_outline,
                              size: 18, color: AppColors.error),
                          SizedBox(width: 8),
                          Text('Eliminar',
                              style: TextStyle(color: AppColors.error)),
                        ])),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _InfoRow(
                      Icons.person_outline, 'Responsable', responsable),
                ),
                Expanded(
                  child: _InfoRow(
                      Icons.phone_outlined, 'Teléfono', telefono),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 10)),
                Text(value,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      );
}
