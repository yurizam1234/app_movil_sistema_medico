import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../config/app_colors.dart';
import '../../models/user_model.dart';

// ═══════════════════════════════════════════════════════════════════════
//  PERFIL BIOMÉDICO — Editable, actualiza Firestore
// ═══════════════════════════════════════════════════════════════════════
class PerfilBiomedicoScreen extends StatefulWidget {
  const PerfilBiomedicoScreen({super.key});

  @override
  State<PerfilBiomedicoScreen> createState() => _PerfilBiomedicoScreenState();
}

class _PerfilBiomedicoScreenState extends State<PerfilBiomedicoScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _editando  = false;
  bool _guardando = false;

  // Controladores
  late TextEditingController _nombreCtrl;
  late TextEditingController _telefonoCtrl;
  late TextEditingController _hospitalCtrl;
  late TextEditingController _especialidadCtrl;
  late TextEditingController _experienciaCtrl;

  UserModel? _usuario;
  bool _cargando = true;

  // KPIs del perfil
  int _totalResueltas = 0;
  int _totalEquipos   = 0;
  double _calificacion = 4.8;

  @override
  void initState() {
    super.initState();
    _nombreCtrl       = TextEditingController();
    _telefonoCtrl     = TextEditingController();
    _hospitalCtrl     = TextEditingController();
    _especialidadCtrl = TextEditingController();
    _experienciaCtrl  = TextEditingController();
    _cargarPerfil();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _hospitalCtrl.dispose();
    _especialidadCtrl.dispose();
    _experienciaCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarPerfil() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) { setState(() => _cargando = false); return; }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get();

      final user = doc.exists ? UserModel.fromFirestore(doc) : null;

      // KPIs
      final mantSnap = await FirebaseFirestore.instance
          .collection('mantenimientos')
          .where('tecnicoId', isEqualTo: uid)
          .get();
      final incSnap = await FirebaseFirestore.instance
          .collection('incidencias')
          .where('tecnicoId', isEqualTo: uid)
          .where('estado', whereIn: ['Resuelta', 'Cerrada'])
          .get();

      if (mounted) {
        setState(() {
          _usuario        = user;
          _totalResueltas = incSnap.docs.length;
          _totalEquipos   = mantSnap.docs.length;
          _calificacion   = (doc.data()?['calificacion'] as num?)?.toDouble() ?? 4.8;

          _nombreCtrl.text       = user?.nombre        ?? '';
          _telefonoCtrl.text     = user?.telefono       ?? '';
          _hospitalCtrl.text     = user?.hospital       ?? '';
          _especialidadCtrl.text = doc.data()?['especialidad'] ?? user?.cargo ?? 'Biomédico';
          _experienciaCtrl.text  = doc.data()?['experiencia']  ?? '';

          _cargando = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .update({
        'nombre':       _nombreCtrl.text.trim(),
        'telefono':     _telefonoCtrl.text.trim(),
        'hospital':     _hospitalCtrl.text.trim(),
        'especialidad': _especialidadCtrl.text.trim(),
        'experiencia':  _experienciaCtrl.text.trim(),
        'cargo':        _especialidadCtrl.text.trim(),
      });
    }

    if (mounted) {
      setState(() {
        _guardando = false;
        _editando  = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Perfil actualizado correctamente'),
        backgroundColor: AppColors.resolved,
        behavior: SnackBarBehavior.floating,
      ));
      _cargarPerfil();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Mi Perfil',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          if (!_editando)
            TextButton.icon(
              onPressed: () => setState(() => _editando = true),
              icon: const Icon(Icons.edit_outlined,
                  color: Colors.white, size: 18),
              label: const Text('Editar',
                  style: TextStyle(color: Colors.white)),
            )
          else
            TextButton.icon(
              onPressed: _guardando ? null : _guardar,
              icon: _guardando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check, color: Colors.white, size: 18),
              label: const Text('Guardar',
                  style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Avatar + datos básicos ─────────────────────────
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 52,
                              backgroundColor:
                                  AppColors.primary.withOpacity(0.15),
                              backgroundImage: _usuario?.photoUrl.isNotEmpty == true
                                  ? NetworkImage(_usuario!.photoUrl)
                                  : null,
                              child: _usuario?.photoUrl.isNotEmpty != true
                                  ? Text(
                                      (_usuario?.nombre ?? 'B')
                                          .substring(0, 1)
                                          .toUpperCase(),
                                      style: const TextStyle(
                                          fontSize: 38,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold))
                                  : null,
                            ),
                            if (_editando)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle),
                                  child: const Icon(Icons.camera_alt_rounded,
                                      color: Colors.white, size: 16),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(_nombreCtrl.text.isNotEmpty
                            ? _nombreCtrl.text
                            : 'Biomédico',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        Text(_especialidadCtrl.text,
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 14)),
                        Text(_hospitalCtrl.text,
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── KPIs del perfil ───────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _KpiItem(
                            valor: '$_totalResueltas',
                            label: 'Resueltas',
                            color: AppColors.resolved),
                        Container(
                            width: 1, height: 40, color: AppColors.divider),
                        _KpiItem(
                            valor: '$_totalEquipos',
                            label: 'Mantenimientos',
                            color: AppColors.accent),
                        Container(
                            width: 1, height: 40, color: AppColors.divider),
                        _KpiItem(
                            valor: _calificacion.toStringAsFixed(1),
                            label: 'Calificación',
                            color: const Color(0xFFF59E0B),
                            icon: Icons.star_rounded),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Formulario de edición ─────────────────────────
                  _CampoSeccion(
                    titulo: 'Información personal',
                    campos: [
                      _CampoData(
                          ctrl:     _nombreCtrl,
                          label:    'Nombre completo',
                          icon:     Icons.person_outlined,
                          editable: _editando,
                          validator: (v) => (v?.isEmpty ?? true)
                              ? 'Requerido' : null),
                      _CampoData(
                          ctrl:     _telefonoCtrl,
                          label:    'Teléfono',
                          icon:     Icons.phone_outlined,
                          editable: _editando,
                          tipo:     TextInputType.phone),
                      _CampoData(
                          ctrl:     _especialidadCtrl,
                          label:    'Especialidad / Cargo',
                          icon:     Icons.medical_services_outlined,
                          editable: _editando,
                          validator: (v) => (v?.isEmpty ?? true)
                              ? 'Requerido' : null),
                    ],
                  ),

                  const SizedBox(height: 16),

                  _CampoSeccion(
                    titulo: 'Institución',
                    campos: [
                      _CampoData(
                          ctrl:     _hospitalCtrl,
                          label:    'Hospital / Clínica',
                          icon:     Icons.local_hospital_outlined,
                          editable: _editando),
                      _CampoData(
                          ctrl:     _experienciaCtrl,
                          label:    'Años de experiencia',
                          icon:     Icons.work_outline,
                          editable: _editando,
                          tipo:     TextInputType.number),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Correo (no editable)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2))
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Cuenta',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.email_outlined,
                                color: AppColors.textSecondary, size: 18),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Correo electrónico',
                                    style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11)),
                                Text(
                                    FirebaseAuth.instance.currentUser?.email ??
                                        _usuario?.email ?? '—',
                                    style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}

// ── KPI item ─────────────────────────────────────────────────────────
class _KpiItem extends StatelessWidget {
  final String valor, label;
  final Color color;
  final IconData? icon;
  const _KpiItem(
      {required this.valor, required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null)
                Icon(icon, color: color, size: 16),
              Text(valor,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color)),
            ],
          ),
          const SizedBox(height: 3),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11)),
        ],
      );
}

// ── Sección de campos ─────────────────────────────────────────────────
class _CampoSeccion extends StatelessWidget {
  final String titulo;
  final List<_CampoData> campos;
  const _CampoSeccion({required this.titulo, required this.campos});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 14),
          ...campos.map((c) => _Campo(data: c)),
        ],
      ),
    );
  }
}

class _CampoData {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final bool editable;
  final TextInputType tipo;
  final String? Function(String?)? validator;

  const _CampoData({
    required this.ctrl,
    required this.label,
    required this.icon,
    required this.editable,
    this.tipo = TextInputType.text,
    this.validator,
  });
}

class _Campo extends StatelessWidget {
  final _CampoData data;
  const _Campo({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller:     data.ctrl,
        readOnly:       !data.editable,
        keyboardType:   data.tipo,
        validator:      data.validator,
        style: TextStyle(
            color: data.editable
                ? AppColors.textPrimary
                : AppColors.textSecondary,
            fontSize: 14),
        decoration: InputDecoration(
          labelText: data.label,
          prefixIcon: Icon(data.icon,
              color: data.editable
                  ? AppColors.primary
                  : AppColors.textSecondary,
              size: 20),
          filled: true,
          fillColor: data.editable
              ? AppColors.background
              : const Color(0xFFF8F9FC),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: data.editable
                  ? const BorderSide(color: AppColors.divider)
                  : BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}
