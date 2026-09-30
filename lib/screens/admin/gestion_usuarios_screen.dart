import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../config/app_colors.dart';

// ═══════════════════════════════════════════════════════════════════════
//  GESTIÓN DE USUARIOS
// ═══════════════════════════════════════════════════════════════════════
class GestionUsuariosScreen extends StatefulWidget {
  const GestionUsuariosScreen({super.key});

  @override
  State<GestionUsuariosScreen> createState() => _GestionUsuariosScreenState();
}

class _GestionUsuariosScreenState extends State<GestionUsuariosScreen> {
  final _searchCtrl = TextEditingController();
  String _query  = '';
  String _filtro = 'Todos';

  static const _filtros = [
    'Todos', 'Administrador', 'Biomédico', 'Enfermera',
  ];

  static const _roles = ['administrador', 'biomedico', 'enfermera'];
  static const _rolesLabel = ['Administrador', 'Biomédico', 'Enfermera'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Crear o editar usuario ──────────────────────────────────────────
  void _abrirFormulario({Map<String, dynamic>? data, String? docId}) {
    final nombreCtrl   = TextEditingController(text: data?['nombre'] ?? '');
    final correoCtrl   = TextEditingController(text: data?['correo'] ?? data?['email'] ?? '');
    final telefonoCtrl = TextEditingController(text: data?['telefono'] ?? '');
    final hospitalCtrl = TextEditingController(text: data?['hospital'] ?? '');
    String rolSel      = data?['rol'] ?? 'enfermera';
    String estadoSel   = data?['estado'] ?? 'activo';
    final formKey      = GlobalKey<FormState>();
    bool guardando     = false;

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

                  Text(docId == null ? 'Crear usuario' : 'Editar usuario',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 20),

                  _campo(nombreCtrl,   'Nombre completo', Icons.person_outline, (v) => v?.isEmpty == true ? 'Requerido' : null),
                  if (docId == null)
                    _campo(correoCtrl, 'Correo electrónico', Icons.email_outlined, (v) {
                      if (v?.isEmpty == true) return 'Requerido';
                      if (!v!.contains('@')) return 'Correo inválido';
                      return null;
                    }, tipo: TextInputType.emailAddress),
                  _campo(telefonoCtrl,'Teléfono', Icons.phone_outlined, null, tipo: TextInputType.phone),
                  _campo(hospitalCtrl,'Hospital / Clínica', Icons.local_hospital_outlined, null),

                  // Rol
                  const Text('Rol',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: List.generate(_roles.length, (i) {
                      final sel = rolSel == _roles[i];
                      return ChoiceChip(
                        label: Text(_rolesLabel[i]),
                        selected: sel,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                            color: sel ? Colors.white : AppColors.textPrimary,
                            fontSize: 13),
                        onSelected: (_) => setModal(() => rolSel = _roles[i]),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),

                  // Estado
                  Row(
                    children: [
                      const Text('Estado: ',
                          style: TextStyle(color: AppColors.textSecondary)),
                      Switch(
                        value: estadoSel == 'activo',
                        onChanged: (v) =>
                            setModal(() => estadoSel = v ? 'activo' : 'inactivo'),
                        activeColor: AppColors.resolved,
                      ),
                      Text(estadoSel == 'activo' ? 'Activo' : 'Inactivo',
                          style: TextStyle(
                              color: estadoSel == 'activo'
                                  ? AppColors.resolved
                                  : AppColors.error,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),

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
                                final dataToSave = {
                                  'nombre':   nombreCtrl.text.trim(),
                                  'telefono': telefonoCtrl.text.trim(),
                                  'hospital': hospitalCtrl.text.trim(),
                                  'rol':      rolSel,
                                  'cargo':    _rolesLabel[_roles.indexOf(rolSel)],
                                  'estado':   estadoSel,
                                };
                                if (docId == null) {
                                  dataToSave['correo'] = correoCtrl.text.trim();
                                  dataToSave['email']  = correoCtrl.text.trim();
                                  dataToSave['fechaCreacion'] = DateTime.now().toIso8601String();
                                  await FirebaseFirestore.instance
                                      .collection('usuarios')
                                      .add(dataToSave);
                                } else {
                                  await FirebaseFirestore.instance
                                      .collection('usuarios')
                                      .doc(docId)
                                      .update(dataToSave);
                                }
                                if (ctx2.mounted) Navigator.pop(ctx2);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(docId == null
                                          ? 'Usuario creado exitosamente'
                                          : 'Usuario actualizado'),
                                      backgroundColor: AppColors.resolved,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              } catch (_) {
                                setModal(() => guardando = false);
                                if (ctx2.mounted) {
                                  ScaffoldMessenger.of(ctx2).showSnackBar(
                                    const SnackBar(
                                        content: Text('Error al guardar'),
                                        backgroundColor: AppColors.error,
                                        behavior: SnackBarBehavior.floating),
                                  );
                                }
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
                              docId == null ? 'Crear usuario' : 'Guardar cambios',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
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

  // ── Confirmar eliminación ───────────────────────────────────────────
  void _confirmarEliminar(String docId, String nombre) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: Text('¿Eliminar a "$nombre"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance
                  .collection('usuarios')
                  .doc(docId)
                  .delete();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Usuario eliminado'),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Eliminar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Toggle estado ───────────────────────────────────────────────────
  Future<void> _toggleEstado(String docId, String estadoActual) async {
    final nuevoEstado = estadoActual == 'activo' ? 'inactivo' : 'activo';
    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(docId)
        .update({'estado': nuevoEstado});
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Gestión de Usuarios',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add_outlined, color: Colors.white),
        label: const Text('Nuevo usuario',
            style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          // Buscador
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o correo...',
                prefixIcon: const Icon(Icons.search,
                    color: AppColors.textSecondary),
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

          // Filtros por rol
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: sel ? AppColors.primary : AppColors.divider),
                    ),
                    child: Text(f,
                        style: TextStyle(
                            color: sel ? Colors.white : AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: sel
                                ? FontWeight.bold
                                : FontWeight.normal)),
                  ),
                );
              },
            ),
          ),

          // Lista
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('usuarios')
                  .orderBy('nombre')
                  .snapshots(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = (snap.data?.docs ?? []).where((d) {
                  final data    = d.data();
                  final nombre  = (data['nombre']  ?? '').toString().toLowerCase();
                  final correo  = (data['correo']  ?? data['email'] ?? '').toString().toLowerCase();
                  final rol     = (data['rol']     ?? '').toString().toLowerCase();
                  final matchQ  = _query.isEmpty ||
                      nombre.contains(_query) ||
                      correo.contains(_query);
                  final matchF  = _filtro == 'Todos' ||
                      rol.contains(_filtro.toLowerCase());
                  return matchQ && matchF;
                }).toList();

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text('No se encontraron usuarios',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 15)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final data  = docs[i].data();
                    final id    = docs[i].id;
                    final esYo  = id == myUid;
                    return _UsuarioCard(
                      data:       data,
                      docId:      id,
                      esYo:       esYo,
                      onEditar:   () => _abrirFormulario(data: data, docId: id),
                      onEliminar: () => _confirmarEliminar(id, data['nombre'] ?? ''),
                      onToggle:   () => _toggleEstado(id, data['estado'] ?? 'activo'),
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
}

// ── Tarjeta de usuario ────────────────────────────────────────────────
class _UsuarioCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final bool esYo;
  final VoidCallback onEditar, onEliminar, onToggle;

  const _UsuarioCard({
    required this.data,
    required this.docId,
    required this.esYo,
    required this.onEditar,
    required this.onEliminar,
    required this.onToggle,
  });

  Color get _rolColor {
    final r = (data['rol'] ?? '').toString().toLowerCase();
    if (r.contains('admin'))     return const Color(0xFF7C3AED);
    if (r.contains('biomedico')) return AppColors.primary;
    return AppColors.accent;
  }

  String get _rolLabel {
    final r = (data['rol'] ?? '').toString().toLowerCase();
    if (r.contains('admin'))     return 'Administrador';
    if (r.contains('biomedico')) return 'Biomédico';
    return 'Enfermera';
  }

  @override
  Widget build(BuildContext context) {
    final nombre  = data['nombre']  ?? 'Usuario';
    final correo  = data['correo']  ?? data['email'] ?? '—';
    final hospital= data['hospital'] ?? '—';
    final estado  = data['estado']   ?? 'activo';
    final activo  = estado == 'activo';
    final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U';

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
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: _rolColor.withOpacity(0.15),
                  backgroundImage: data['fotoPerfil'] != null &&
                          (data['fotoPerfil'] as String).isNotEmpty
                      ? NetworkImage(data['fotoPerfil'] as String)
                      : null,
                  child: data['fotoPerfil'] == null ||
                          (data['fotoPerfil'] as String).isEmpty
                      ? Text(inicial,
                          style: TextStyle(
                              color: _rolColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 20))
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: activo ? AppColors.resolved : Colors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(nombre,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.textPrimary)),
                      ),
                      if (esYo)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Tú',
                              style: TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(correo,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Rol badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _rolColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(_rolLabel,
                            style: TextStyle(
                                color: _rolColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.local_hospital_outlined,
                          size: 11, color: AppColors.textSecondary),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(hospital,
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Acciones
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
              onSelected: (v) {
                if (v == 'editar')   onEditar();
                if (v == 'toggle')   onToggle();
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
                PopupMenuItem(
                    value: 'toggle',
                    child: Row(children: [
                      Icon(
                          activo ? Icons.person_off_outlined : Icons.person_outlined,
                          size: 18),
                      const SizedBox(width: 8),
                      Text(activo ? 'Desactivar' : 'Activar'),
                    ])),
                if (!esYo)
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
      ),
    );
  }
}
