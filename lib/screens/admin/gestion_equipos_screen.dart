import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../config/app_colors.dart';

// ═══════════════════════════════════════════════════════════════════════
//  GESTIÓN DE EQUIPOS MÉDICOS
// ═══════════════════════════════════════════════════════════════════════
class GestionEquiposScreen extends StatefulWidget {
  const GestionEquiposScreen({super.key});

  @override
  State<GestionEquiposScreen> createState() => _GestionEquiposScreenState();
}

class _GestionEquiposScreenState extends State<GestionEquiposScreen> {
  final _searchCtrl = TextEditingController();
  String _query  = '';
  String _filtro = 'Todos';

  static const _filtros = [
    'Todos', 'Operativo', 'En mantenimiento',
    'Fuera de servicio', 'En reparación',
  ];

  static const _estados = [
    'Operativo', 'En mantenimiento', 'Fuera de servicio', 'En reparación',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _mostrarQR(String equipoId, String nombre) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('QR — $nombre',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(
              data: equipoId,
              version: QrVersions.auto,
              size: 200,
              eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AppColors.primary),
              dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            Text('ID: $equipoId',
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11),
                textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cerrar')),
        ],
      ),
    );
  }

  void _cambiarEstado(String docId, String estadoActual) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text('Cambiar estado',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(height: 8),
          ..._estados.map((e) {
            final sel = e == estadoActual;
            return ListTile(
              leading: Container(
                width: 10, height: 10,
                decoration: BoxDecoration(
                    color: _colorEstado(e), shape: BoxShape.circle),
              ),
              title: Text(e,
                  style: TextStyle(
                      fontWeight: sel
                          ? FontWeight.bold
                          : FontWeight.normal)),
              trailing: sel
                  ? const Icon(Icons.check, color: AppColors.resolved)
                  : null,
              onTap: () async {
                Navigator.pop(ctx);
                await FirebaseFirestore.instance
                    .collection('equipos')
                    .doc(docId)
                    .update({'estado': e});
              },
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Color _colorEstado(String e) {
    switch (e) {
      case 'Operativo':          return AppColors.resolved;
      case 'En mantenimiento':   return AppColors.pending;
      case 'Fuera de servicio':  return AppColors.error;
      default:                   return AppColors.accent;
    }
  }

  void _abrirFormulario({Map<String, dynamic>? data, String? docId}) {
    final codigoCtrl    = TextEditingController(text: data?['codigo']   ?? '');
    final nombreCtrl    = TextEditingController(text: data?['nombre']   ?? '');
    final marcaCtrl     = TextEditingController(text: data?['marca']    ?? '');
    final modeloCtrl    = TextEditingController(text: data?['modelo']   ?? '');
    final serieCtrl     = TextEditingController(text: data?['serie']    ?? '');
    final areaCtrl      = TextEditingController(text: data?['area']     ?? '');
    final hospitalCtrl  = TextEditingController(text: data?['hospital'] ?? '');
    String estadoSel    = data?['estado'] ?? 'Operativo';
    final formKey       = GlobalKey<FormState>();
    bool guardando      = false;

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

                  Text(docId == null ? 'Nuevo equipo' : 'Editar equipo',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 20),

                  _campo(codigoCtrl, 'Código interno', Icons.qr_code, (v) => v?.isEmpty == true ? 'Requerido' : null),
                  _campo(nombreCtrl, 'Nombre del equipo', Icons.medical_services_outlined, (v) => v?.isEmpty == true ? 'Requerido' : null),
                  _campo(marcaCtrl,  'Marca',    Icons.branding_watermark_outlined, null),
                  _campo(modeloCtrl, 'Modelo',   Icons.precision_manufacturing_outlined, null),
                  _campo(serieCtrl,  'N° Serie', Icons.tag_outlined, null),
                  _campo(areaCtrl,   'Área',     Icons.grid_view_outlined, null),
                  _campo(hospitalCtrl,'Hospital',Icons.local_hospital_outlined, null),

                  const Text('Estado inicial',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _estados.map((e) {
                      final sel = estadoSel == e;
                      return ChoiceChip(
                        label: Text(e, style: const TextStyle(fontSize: 12)),
                        selected: sel,
                        selectedColor: _colorEstado(e),
                        labelStyle: TextStyle(
                            color: sel ? Colors.white : AppColors.textPrimary,
                            fontSize: 12),
                        onSelected: (_) => setModal(() => estadoSel = e),
                      );
                    }).toList(),
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
                                  'codigo':   codigoCtrl.text.trim(),
                                  'nombre':   nombreCtrl.text.trim(),
                                  'marca':    marcaCtrl.text.trim(),
                                  'modelo':   modeloCtrl.text.trim(),
                                  'serie':    serieCtrl.text.trim(),
                                  'area':     areaCtrl.text.trim(),
                                  'hospital': hospitalCtrl.text.trim(),
                                  'estado':   estadoSel,
                                };
                                if (docId == null) {
                                  d['fechaRegistro'] = DateTime.now().toIso8601String();
                                  // El ID del documento se usará como codigoQR
                                  final ref = await FirebaseFirestore.instance
                                      .collection('equipos')
                                      .add(d);
                                  // Guardar su propio ID como codigoQR
                                  await ref.update({'codigoQR': ref.id});
                                } else {
                                  await FirebaseFirestore.instance
                                      .collection('equipos')
                                      .doc(docId)
                                      .update(d);
                                }
                                if (ctx2.mounted) Navigator.pop(ctx2);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(docId == null
                                          ? 'Equipo registrado exitosamente'
                                          : 'Equipo actualizado'),
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
                              docId == null ? 'Registrar equipo' : 'Guardar cambios',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
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
    String? Function(String?)? validator,
  ) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          controller: ctrl,
          validator: validator,
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
        title: const Text('Eliminar equipo'),
        content: Text('¿Eliminar "$nombre"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance.collection('equipos').doc(docId).delete();
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
          title: const Text('Equipos Médicos',
              style: TextStyle(fontWeight: FontWeight.bold)),
          elevation: 0,
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _abrirFormulario(),
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Nuevo equipo', style: TextStyle(color: Colors.white)),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Buscar equipo, código, serie...',
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.textSecondary),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          })
                      : null,
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

            // Filtros por estado
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: _filtros.length,
                itemBuilder: (_, i) {
                  final f   = _filtros[i];
                  final sel = _filtro == f;
                  return GestureDetector(
                    onTap: () => setState(() => _filtro = f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: sel ? AppColors.primary : AppColors.divider),
                      ),
                      child: Text(f,
                          style: TextStyle(
                              color: sel ? Colors.white : AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: sel
                                  ? FontWeight.bold
                                  : FontWeight.normal)),
                    ),
                  );
                },
              ),
            ),

            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('equipos')
                    .orderBy('nombre')
                    .snapshots(),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = (snap.data?.docs ?? []).where((d) {
                    final data  = d.data();
                    final n     = (data['nombre']  ?? '').toString().toLowerCase();
                    final c     = (data['codigo']  ?? '').toString().toLowerCase();
                    final s     = (data['serie']   ?? '').toString().toLowerCase();
                    final matchQ = _query.isEmpty ||
                        n.contains(_query) ||
                        c.contains(_query) ||
                        s.contains(_query);
                    final matchF = _filtro == 'Todos' ||
                        (data['estado'] ?? '') == _filtro;
                    return matchQ && matchF;
                  }).toList();

                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.medical_services_outlined,
                              size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          const Text('No hay equipos registrados',
                              style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final data = docs[i].data();
                      final id   = docs[i].id;
                      return _EquipoCard(
                        data:          data,
                        docId:         id,
                        colorEstado:   _colorEstado(data['estado'] ?? 'Operativo'),
                        onEditar:      () => _abrirFormulario(data: data, docId: id),
                        onEliminar:    () => _confirmarEliminar(id, data['nombre'] ?? ''),
                        onQR:          () => _mostrarQR(id, data['nombre'] ?? 'Equipo'),
                        onCambiarEstado: () =>
                            _cambiarEstado(id, data['estado'] ?? 'Operativo'),
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

class _EquipoCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final Color colorEstado;
  final VoidCallback onEditar, onEliminar, onQR, onCambiarEstado;

  const _EquipoCard({
    required this.data,
    required this.docId,
    required this.colorEstado,
    required this.onEditar,
    required this.onEliminar,
    required this.onQR,
    required this.onCambiarEstado,
  });

  @override
  Widget build(BuildContext context) {
    final nombre  = data['nombre']  ?? 'Equipo';
    final codigo  = data['codigo']  ?? '—';
    final area    = data['area']    ?? '—';
    final hospital= data['hospital']?? '—';
    final estado  = data['estado']  ?? 'Operativo';
    final marca   = data['marca']   ?? '';
    final modelo  = data['modelo']  ?? '';

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
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: colorEstado.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.medical_services_outlined,
                      color: colorEstado, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nombre,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      if (marca.isNotEmpty || modelo.isNotEmpty)
                        Text('$marca $modelo',
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12),
                            maxLines: 1),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorEstado.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(estado,
                      style: TextStyle(
                          color: colorEstado,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),

            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),

            Row(
              children: [
                const Icon(Icons.qr_code_outlined,
                    size: 12, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(codigo,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(width: 12),
                const Icon(Icons.location_on_outlined,
                    size: 12, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text('$area · $hospital',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Acciones rápidas
            Row(
              children: [
                Expanded(
                  child: _AccionBtn(
                    icon: Icons.qr_code_2_rounded,
                    label: 'Ver QR',
                    onTap: onQR,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _AccionBtn(
                    icon: Icons.swap_vert_rounded,
                    label: 'Estado',
                    onTap: onCambiarEstado,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _AccionBtn(
                    icon: Icons.edit_outlined,
                    label: 'Editar',
                    onTap: onEditar,
                  ),
                ),
                const SizedBox(width: 8),
                _AccionBtn(
                  icon: Icons.delete_outline,
                  label: '',
                  onTap: onEliminar,
                  color: AppColors.error,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AccionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  const _AccionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              if (label.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(label,
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ],
            ],
          ),
        ),
      );
}
