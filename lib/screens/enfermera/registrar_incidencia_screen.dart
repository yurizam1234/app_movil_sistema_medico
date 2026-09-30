import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../config/app_colors.dart';
import '../../models/incidencia.dart';

// ═══════════════════════════════════════════════════════════════════════
//  REGISTRAR INCIDENCIA — MÓDULO ENFERMERA
// ═══════════════════════════════════════════════════════════════════════
class RegistrarIncidenciaEnfermeraScreen extends StatefulWidget {
  const RegistrarIncidenciaEnfermeraScreen({super.key});

  @override
  State<RegistrarIncidenciaEnfermeraScreen> createState() =>
      _RegistrarIncidenciaEnfermeraScreenState();
}

class _RegistrarIncidenciaEnfermeraScreenState
    extends State<RegistrarIncidenciaEnfermeraScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();

  // ── Equipo seleccionado ─────────────────────────────────────────────
  Map<String, dynamic>? _equipoSeleccionado;
  bool _usarOtroEquipo = false;

  // Campos de "Otro equipo"
  final _otroNombreCtrl    = TextEditingController();
  final _otroCategoriaCtrl = TextEditingController();
  final _otroMarcaCtrl     = TextEditingController();
  final _otroModeloCtrl    = TextEditingController();
  final _otroSerieCtrl     = TextEditingController();
  final _otroAreaCtrl      = TextEditingController();
  final _otroObsCtrl       = TextEditingController();

  // ── Tipo de incidencia ──────────────────────────────────────────────
  static const _tipos = [
    'Falla eléctrica',
    'Falla mecánica',
    'Error de software',
    'Calibración',
    'Daño físico',
    'Mantenimiento preventivo',
    'Solicitud de revisión',
    'Otro',
  ];
  String? _tipoSeleccionado;
  final _otroTipoCtrl = TextEditingController();

  // ── Fotos ───────────────────────────────────────────────────────────
  final List<File> _fotos = [];
  final _picker = ImagePicker();
  static const _maxFotos = 4;

  // ── Estado de envío ─────────────────────────────────────────────────
  bool _enviando   = false;
  bool _argsLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && !_argsLoaded) {
      _argsLoaded = true;
      if (args['usarOtroEquipo'] == true) {
        setState(() => _usarOtroEquipo = true);
      } else if (args['equipoPreseleccionado'] != null) {
        setState(() =>
            _equipoSeleccionado = args['equipoPreseleccionado'] as Map<String, dynamic>);
      }
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _otroNombreCtrl.dispose();
    _otroCategoriaCtrl.dispose();
    _otroMarcaCtrl.dispose();
    _otroModeloCtrl.dispose();
    _otroSerieCtrl.dispose();
    _otroAreaCtrl.dispose();
    _otroObsCtrl.dispose();
    _otroTipoCtrl.dispose();
    super.dispose();
  }

  // ── Agregar foto ────────────────────────────────────────────────────
  void _agregarFoto() {
    if (_fotos.length >= _maxFotos) {
      _snack('Máximo $_maxFotos fotos permitidas');
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.camera_alt_rounded, color: Colors.white)),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                  backgroundColor: AppColors.accent,
                  child: Icon(Icons.photo_library_rounded, color: Colors.white)),
              title: const Text('Elegir de galería'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final xfile = await _picker.pickImage(
        source: source, imageQuality: 80, maxWidth: 1280);
    if (xfile == null) return;
    setState(() => _fotos.add(File(xfile.path)));
  }

  // ── Firebase Storage ────────────────────────────────────────────────
  Future<List<String>> _subirFotos(String incidenciaId) async {
    final urls = <String>[];
    for (var i = 0; i < _fotos.length; i++) {
      final ref = FirebaseStorage.instance
          .ref('incidencias/$incidenciaId/foto_$i.jpg');
      final task = await ref.putFile(
          _fotos[i], SettableMetadata(contentType: 'image/jpeg'));
      urls.add(await task.ref.getDownloadURL());
    }
    return urls;
  }

  // ── Guardar en Firestore ────────────────────────────────────────────
  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_usarOtroEquipo && _equipoSeleccionado == null) {
      _snack('Selecciona un equipo o elige "Otro equipo"');
      return;
    }
    if (_tipoSeleccionado == null) {
      _snack('Selecciona el tipo de incidencia');
      return;
    }

    setState(() => _enviando = true);

    try {
      final uid  = FirebaseAuth.instance.currentUser!.uid;
      final tipo = _tipoSeleccionado == 'Otro'
          ? _otroTipoCtrl.text.trim()
          : _tipoSeleccionado!;

      final equipoData = _usarOtroEquipo
          ? {
              'id':        'OTRO',
              'nombre':    _otroNombreCtrl.text.trim(),
              'categoria': _otroCategoriaCtrl.text.trim(),
              'marca':     _otroMarcaCtrl.text.trim(),
              'modelo':    _otroModeloCtrl.text.trim(),
              'serie':     _otroSerieCtrl.text.trim(),
              'area':      _otroAreaCtrl.text.trim(),
              'esOtro':    true,
            }
          : _equipoSeleccionado!;

      final docRef = FirebaseFirestore.instance.collection('incidencias').doc();
      final id     = docRef.id;
      final urls   = _fotos.isNotEmpty ? await _subirFotos(id) : <String>[];
      final ahora  = DateTime.now();

      await docRef.set({
        'equipoId':           equipoData['id'],
        'equipoNombre':       equipoData['nombre'],
        'equipoArea':         equipoData['area'] ?? '',
        'equipo':             equipoData,
        'tipo':               tipo,
        'descripcion':        _descCtrl.text.trim(),
        'observaciones':      _usarOtroEquipo ? _otroObsCtrl.text.trim() : '',
        'estado':             'Pendiente',
        'enfermeraId':        uid,
        'tecnicoId':          null,
        'fotos':              urls,
        'fechaCreacion':      Timestamp.fromDate(ahora),
        'fechaActualizacion': Timestamp.fromDate(ahora),
        'historial': [
          HistorialItem(
            fecha:       ahora,
            descripcion: 'Incidencia registrada por enfermera',
            estado:      'Pendiente',
            autor:       uid,
          ).toJson()
        ],
        'esOtroEquipo': _usarOtroEquipo,
      });

      if (!mounted) return;
      setState(() => _enviando = false);
      _mostrarExito(id);
    } catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      _snack('Error al guardar: ${e.toString()}');
    }
  }

  void _mostrarExito(String id) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: const BoxDecoration(
                  color: Color(0xFFECFDF5), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded,
                  color: AppColors.resolved, size: 40),
            ),
            const SizedBox(height: 20),
            const Text('¡Incidencia registrada!',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(
              'Folio: #${id.substring(0, 8).toUpperCase()}\nSe ha notificado al equipo de biomédica.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14, height: 1.5),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Aceptar'),
            ),
          ),
        ],
      ),
    );
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.error,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));

  void _seleccionarEquipo() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _EquipoSelectorSheet(
        onSeleccionado: (eq) => setState(() {
          _equipoSeleccionado = eq;
          _usarOtroEquipo     = false;
        }),
        onOtroEquipo: () => setState(() {
          _usarOtroEquipo     = true;
          _equipoSeleccionado = null;
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Registrar Incidencia',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── 1. Equipo ───────────────────────────────────────────
            _SectionHeader('1. Equipo médico', Icons.medical_services_outlined),
            const SizedBox(height: 10),
            _EquipoSelector(
              equipoSeleccionado: _equipoSeleccionado,
              usarOtroEquipo:     _usarOtroEquipo,
              onTap:              _seleccionarEquipo,
            ),

            if (_usarOtroEquipo) ...[
              const SizedBox(height: 14),
              _buildCard(
                child: Column(
                  children: [
                    _buildField(_otroNombreCtrl,    'Nombre del equipo *',         required: true),
                    _buildField(_otroCategoriaCtrl, 'Categoría / Tipo',            required: false),
                    _buildField(_otroMarcaCtrl,     'Marca',                       required: false),
                    _buildField(_otroModeloCtrl,    'Modelo',                      required: false),
                    _buildField(_otroSerieCtrl,     'N.º de serie',                required: false),
                    _buildField(_otroAreaCtrl,      'Área / Servicio *',           required: true),
                    _buildField(_otroObsCtrl,       'Observaciones del equipo',
                        required: false, maxLines: 2),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // ── 2. Tipo ─────────────────────────────────────────────
            _SectionHeader('2. Tipo de incidencia', Icons.category_outlined),
            const SizedBox(height: 10),
            _buildCard(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tipos.map((t) => _TipoChip(
                  label:    t,
                  selected: _tipoSeleccionado == t,
                  onTap:    () => setState(() => _tipoSeleccionado = t),
                )).toList(),
              ),
            ),

            if (_tipoSeleccionado == 'Otro') ...[
              const SizedBox(height: 12),
              _buildCard(
                child: TextFormField(
                  controller: _otroTipoCtrl,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Describe el tipo de incidencia'
                      : null,
                  decoration:
                      _inputDeco('Especifica el tipo *', Icons.edit_outlined),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // ── 3. Descripción ──────────────────────────────────────
            _SectionHeader('3. Descripción', Icons.description_outlined),
            const SizedBox(height: 10),
            _buildCard(
              child: TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Describe la incidencia';
                  }
                  if (v.trim().length < 10) return 'Mínimo 10 caracteres';
                  return null;
                },
                decoration: _inputDeco(
                    'Describe el problema detalladamente...',
                    Icons.notes_rounded),
              ),
            ),

            const SizedBox(height: 20),

            // ── 4. Fotos ────────────────────────────────────────────
            _SectionHeader(
                '4. Fotos (${_fotos.length}/$_maxFotos)',
                Icons.photo_camera_outlined),
            const SizedBox(height: 10),
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_fotos.isNotEmpty) ...[
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8),
                      itemCount: _fotos.length,
                      itemBuilder: (_, i) => Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(_fotos[i],
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 4, right: 4,
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _fotos.removeAt(i)),
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.close,
                                    color: Colors.white, size: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (_fotos.length < _maxFotos)
                    OutlinedButton.icon(
                      onPressed: _agregarFoto,
                      icon: const Icon(Icons.add_a_photo_outlined, size: 20),
                      label: const Text('Agregar foto'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side:
                            const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        minimumSize: const Size(double.infinity, 44),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Botón enviar ────────────────────────────────────────
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _enviando ? null : _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 3,
                ),
                child: _enviando
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white),
                          ),
                          SizedBox(width: 12),
                          Text('Enviando...', style: TextStyle(fontSize: 16)),
                        ],
                      )
                    : const Text('Registrar Incidencia',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) => Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      );

  Widget _buildField(TextEditingController ctrl, String label,
      {required bool required, int maxLines = 1}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          validator: required
              ? (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null
              : null,
          decoration: _inputDeco(label, Icons.edit_outlined),
        ),
      );

  InputDecoration _inputDeco(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: AppColors.background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      );
}

// ══════════════════════════════════════════════════════════════════════
//  WIDGETS AUXILIARES
// ══════════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader(this.title, this.icon);

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
        ],
      );
}

class _TipoChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TipoChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color:  selected ? AppColors.primary : Colors.white,
            border: Border.all(
                color: selected ? AppColors.primary : AppColors.divider,
                width: 1.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label,
              style: TextStyle(
                  color: selected ? Colors.white : AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight:
                      selected ? FontWeight.bold : FontWeight.normal)),
        ),
      );
}

class _EquipoSelector extends StatelessWidget {
  final Map<String, dynamic>? equipoSeleccionado;
  final bool usarOtroEquipo;
  final VoidCallback onTap;
  const _EquipoSelector({
    required this.equipoSeleccionado,
    required this.usarOtroEquipo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (usarOtroEquipo) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.accent, width: 1.5),
          ),
          child: const Row(
            children: [
              Icon(Icons.device_unknown_outlined,
                  color: AppColors.accent, size: 28),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Otro equipo',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            fontSize: 15)),
                    Text('Completa los datos del equipo abajo',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      );
    }

    if (equipoSeleccionado != null) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.medical_services_outlined,
                    color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(equipoSeleccionado!['nombre'] ?? 'Equipo',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            fontSize: 15)),
                    Text(
                      '${equipoSeleccionado!['marca'] ?? ''} · ${equipoSeleccionado!['area'] ?? equipoSeleccionado!['ubicacion'] ?? ''}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: AppColors.textSecondary),
            ],
          ),
        ),
      );
    }

    // Sin selección
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider, width: 1.5),
        ),
        child: const Row(
          children: [
            Icon(Icons.add_circle_outline, color: AppColors.primary, size: 28),
            SizedBox(width: 14),
            Expanded(
              child: Text('Seleccionar equipo médico',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 15)),
            ),
            Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ── Selector de equipo (BottomSheet) ────────────────────────────────
class _EquipoSelectorSheet extends StatefulWidget {
  final void Function(Map<String, dynamic>) onSeleccionado;
  final VoidCallback onOtroEquipo;
  const _EquipoSelectorSheet(
      {required this.onSeleccionado, required this.onOtroEquipo});

  @override
  State<_EquipoSelectorSheet> createState() => _EquipoSelectorSheetState();
}

class _EquipoSelectorSheetState extends State<_EquipoSelectorSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      builder: (ctx, scrollCtrl) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Seleccionar equipo',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchCtrl,
                  onChanged: (v) =>
                      setState(() => _query = v.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Buscar equipo...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            })
                        : null,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Opción "Otro equipo"
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ListTile(
              onTap: () {
                Navigator.pop(ctx);
                widget.onOtroEquipo();
              },
              tileColor: AppColors.accent.withOpacity(0.08),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              leading: const Icon(Icons.device_unknown_outlined,
                  color: AppColors.accent),
              title: const Text('Otro equipo (no registrado)',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: AppColors.accent)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            ),
          ),

          const SizedBox(height: 8),
          const Divider(indent: 20, endIndent: 20),

          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('equipos')
                  .orderBy('nombre')
                  .snapshots(),
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return _DemoEquipos(
                    query:          _query,
                    onSeleccionado: (eq) {
                      Navigator.pop(ctx);
                      widget.onSeleccionado(eq);
                    },
                  );
                }

                final filtrados = _query.isEmpty
                    ? docs
                    : docs.where((d) {
                        final data = d.data();
                        return (data['nombre'] ?? '')
                                .toString()
                                .toLowerCase()
                                .contains(_query) ||
                            (data['area'] ?? '')
                                .toString()
                                .toLowerCase()
                                .contains(_query);
                      }).toList();

                return ListView.builder(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 4),
                  itemCount: filtrados.length,
                  itemBuilder: (_, i) {
                    final data = Map<String, dynamic>.from(filtrados[i].data())
                      ..['id'] = filtrados[i].id;
                    return ListTile(
                      onTap: () {
                        Navigator.pop(ctx);
                        widget.onSeleccionado(data);
                      },
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFEEF2FF),
                        child: Icon(Icons.medical_services_outlined,
                            color: AppColors.primary, size: 20),
                      ),
                      title: Text(data['nombre'] ?? ''),
                      subtitle: Text(
                          '${data['marca'] ?? ''} · ${data['area'] ?? ''}',
                          style: const TextStyle(fontSize: 12)),
                      trailing:
                          const Icon(Icons.arrow_forward_ios, size: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
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

/// Demo cuando Firestore no tiene equipos registrados aún
class _DemoEquipos extends StatelessWidget {
  final String query;
  final void Function(Map<String, dynamic>) onSeleccionado;

  static const _lista = [
    {'id': 'EQ001', 'nombre': 'Monitor de Signos Vitales', 'marca': 'Mindray', 'modelo': 'MEC-1200',   'serie': 'SV2024001', 'area': 'UCI'},
    {'id': 'EQ002', 'nombre': 'Desfibrilador',             'marca': 'Zoll',    'modelo': 'AED Plus',   'serie': 'DF2024002', 'area': 'Urgencias'},
    {'id': 'EQ003', 'nombre': 'Ventilador Mecánico',       'marca': 'Dräger',  'modelo': 'Evita 4',    'serie': 'VM2024003', 'area': 'UCI'},
    {'id': 'EQ004', 'nombre': 'Bomba de Infusión',         'marca': 'BD',      'modelo': 'Alaris 8015','serie': 'BI2024004', 'area': 'Medicina Interna'},
    {'id': 'EQ005', 'nombre': 'Electrocardiógrafo',        'marca': 'GE',      'modelo': 'MAC 5500',   'serie': 'EC2024005', 'area': 'Cardiología'},
    {'id': 'EQ006', 'nombre': 'Ecógrafo',                  'marca': 'Philips', 'modelo': 'Affiniti 50','serie': 'US2024006', 'area': 'Radiología'},
    {'id': 'EQ007', 'nombre': 'Incubadora Neonatal',       'marca': 'Dräger',  'modelo': 'Caleo',      'serie': 'IN2024007', 'area': 'Neonatología'},
    {'id': 'EQ008', 'nombre': 'Mesa Quirúrgica',           'marca': 'Trumpf',  'modelo': 'TruSystem',  'serie': 'MQ2024008', 'area': 'Quirófano'},
    {'id': 'EQ009', 'nombre': 'Lámpara Quirúrgica',        'marca': 'Maquet',  'modelo': 'LED 150',    'serie': 'LQ2024009', 'area': 'Quirófano'},
    {'id': 'EQ010', 'nombre': 'Aspirador Quirúrgico',      'marca': 'Medela',  'modelo': 'Dominant',   'serie': 'AS2024010', 'area': 'Quirófano'},
  ];

  const _DemoEquipos({required this.query, required this.onSeleccionado});

  @override
  Widget build(BuildContext context) {
    final filtrados = query.isEmpty
        ? _lista
        : _lista.where((e) =>
            e['nombre']!.toLowerCase().contains(query) ||
            e['area']!.toLowerCase().contains(query)).toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      itemCount: filtrados.length,
      itemBuilder: (_, i) {
        final eq = filtrados[i];
        return ListTile(
          onTap: () => onSeleccionado(Map<String, dynamic>.from(eq)),
          leading: const CircleAvatar(
            backgroundColor: Color(0xFFEEF2FF),
            child: Icon(Icons.medical_services_outlined,
                color: AppColors.primary, size: 20),
          ),
          title: Text(eq['nombre']!),
          subtitle: Text('${eq['marca']} · ${eq['area']}',
              style: const TextStyle(fontSize: 12)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        );
      },
    );
  }
}
