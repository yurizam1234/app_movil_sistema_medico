import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../config/app_colors.dart';
import '../../models/mantenimiento.dart';

// ═══════════════════════════════════════════════════════════════════════
//  REGISTRO DE MANTENIMIENTO 2.0
// ═══════════════════════════════════════════════════════════════════════
class RegistroMantenimientoScreen extends StatefulWidget {
  final String incidenciaId;
  final String equipoNombre;
  final Map<String, dynamic> equipoData;

  const RegistroMantenimientoScreen({
    super.key,
    required this.incidenciaId,
    required this.equipoNombre,
    required this.equipoData,
  });

  @override
  State<RegistroMantenimientoScreen> createState() =>
      _RegistroMantenimientoScreenState();
}

class _RegistroMantenimientoScreenState
    extends State<RegistroMantenimientoScreen> {
  final _formKey       = GlobalKey<FormState>();
  final _diagCtrl      = TextEditingController();
  final _accionesCtrl  = TextEditingController();
  final _obsCtrl       = TextEditingController();
  final _picker        = ImagePicker();

  // ── Tiempo ────────────────────────────────────────────────────────
  DateTime _horaInicio = DateTime.now();
  DateTime _horaFin    = DateTime.now().add(const Duration(hours: 1));

  // ── Tipo y estado final ────────────────────────────────────────────
  String _tipo         = 'Correctivo';
  String _estadoFinal  = 'Operativo';

  // ── Fotos por sección ──────────────────────────────────────────────
  final List<File> _fotosAntes    = [];
  final List<File> _fotosDurante  = [];
  final List<File> _fotosDespues  = [];

  // ── Repuestos utilizados ───────────────────────────────────────────
  final List<RepuestoUsado> _repuestos = [];

  bool _guardando = false;

  @override
  void dispose() {
    _diagCtrl.dispose();
    _accionesCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  // ── Agregar foto a una sección ─────────────────────────────────────
  void _agregarFoto(List<File> lista) {
    if (lista.length >= 3) {
      _snack('Máximo 3 fotos por sección');
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
                _pickImage(ImageSource.camera, lista);
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                  backgroundColor: AppColors.accent,
                  child: Icon(Icons.photo_library_rounded, color: Colors.white)),
              title: const Text('Elegir de galería'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery, lista);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source, List<File> lista) async {
    final xfile = await _picker.pickImage(
        source: source, imageQuality: 80, maxWidth: 1280);
    if (xfile == null) return;
    setState(() => lista.add(File(xfile.path)));
  }

  // ── Subir fotos a Storage ──────────────────────────────────────────
  Future<List<String>> _subirFotos(
      List<File> files, String mantId, String seccion) async {
    final urls = <String>[];
    for (var i = 0; i < files.length; i++) {
      final ref = FirebaseStorage.instance
          .ref('mantenimientos/$mantId/${seccion}_$i.jpg');
      final task = await ref.putFile(
          files[i], SettableMetadata(contentType: 'image/jpeg'));
      urls.add(await task.ref.getDownloadURL());
    }
    return urls;
  }

  // ── Agregar repuesto desde selector ───────────────────────────────
  void _abrirSelectorRepuestos() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => const _SelectorRepuestosSheet(),
    );

    if (result != null) {
      // Pedir cantidad
      final cant = await _pedirCantidad(context, result['nombre'] ?? '');
      if (cant != null && cant > 0) {
        setState(() {
          _repuestos.add(RepuestoUsado(
            repuestoId: result['id'] ?? '',
            nombre:     result['nombre'] ?? '',
            codigo:     result['codigo'] ?? '',
            cantidad:   cant,
          ));
        });
      }
    }
  }

  Future<int?> _pedirCantidad(BuildContext ctx, String nombre) async {
    int cantidad = 1;
    return showDialog<int>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text('Cantidad: $nombre'),
        content: StatefulBuilder(
          builder: (_, set) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed:
                    cantidad > 1 ? () => set(() => cantidad--) : null,
              ),
              Text('$cantidad',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => set(() => cantidad++),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, cantidad),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  // ── Guardar mantenimiento ─────────────────────────────────────────
  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_horaFin.isBefore(_horaInicio)) {
      _snack('La hora de fin debe ser posterior a la de inicio');
      return;
    }

    setState(() => _guardando = true);

    try {
      final uid      = FirebaseAuth.instance.currentUser!.uid;
      final docRef   = FirebaseFirestore.instance.collection('mantenimientos').doc();
      final mantId   = docRef.id;
      final ahora    = DateTime.now();

      // Subir fotos
      final urlsAntes   = _fotosAntes.isNotEmpty
          ? await _subirFotos(_fotosAntes,   mantId, 'antes')
          : <String>[];
      final urlsDurante = _fotosDurante.isNotEmpty
          ? await _subirFotos(_fotosDurante, mantId, 'durante')
          : <String>[];
      final urlsDespues = _fotosDespues.isNotEmpty
          ? await _subirFotos(_fotosDespues, mantId, 'despues')
          : <String>[];

      // Descontar repuestos del inventario
      for (final r in _repuestos) {
        if (r.repuestoId.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('repuestos')
              .doc(r.repuestoId)
              .update({
            'cantidad': FieldValue.increment(-r.cantidad),
            'movimientos': FieldValue.arrayUnion([
              {
                'tipo':        'Salida',
                'cantidad':    r.cantidad,
                'mantenimientoId': mantId,
                'equipoNombre':    widget.equipoNombre,
                'fecha':           Timestamp.fromDate(ahora),
                'biomedicoId':     uid,
              }
            ]),
          });
        }
      }

      // Guardar mantenimiento
      final mantenimiento = Mantenimiento(
        id:                mantId,
        equipoId:          widget.equipoData['id'] ?? widget.incidenciaId,
        equipoNombre:      widget.equipoNombre,
        equipoArea:        widget.equipoData['area'] ?? '',
        incidenciaId:      widget.incidenciaId,
        biomedicoId:       uid,
        tipo:              _tipo,
        diagnostico:       _diagCtrl.text.trim(),
        accionesRealizadas:_accionesCtrl.text.trim(),
        observaciones:     _obsCtrl.text.trim(),
        estadoFinal:       _estadoFinal,
        horaInicio:        _horaInicio,
        horaFin:           _horaFin,
        fotosAntes:        urlsAntes,
        fotosDurante:      urlsDurante,
        fotosDespues:      urlsDespues,
        repuestosUsados:   _repuestos,
        fechaCreacion:     ahora,
      );

      await docRef.set(mantenimiento.toJson());

      // Actualizar incidencia
      final nuevoEstado =
          _estadoFinal == 'Operativo' ? 'Resuelta' : 'Cerrada';
      await FirebaseFirestore.instance
          .collection('incidencias')
          .doc(widget.incidenciaId)
          .update({
        'estado':    nuevoEstado,
        'mantenimientoId': mantId,
        'fechaActualizacion': Timestamp.fromDate(ahora),
        'historial': FieldValue.arrayUnion([
          {
            'fecha':       Timestamp.fromDate(ahora),
            'descripcion':
                'Mantenimiento $_tipo completado. Estado final: $_estadoFinal',
            'estado':      nuevoEstado,
            'autor':       uid,
          }
        ]),
      });

      // Actualizar equipo
      if (widget.equipoData['id'] != null &&
          widget.equipoData['id'] != 'OTRO') {
        await FirebaseFirestore.instance
            .collection('equipos')
            .doc(widget.equipoData['id'] as String)
            .update({
          'estado': _estadoFinal,
          'ultimoMantenimiento': Timestamp.fromDate(ahora),
        });
      }

      if (!mounted) return;
      setState(() => _guardando = false);
      _mostrarExito();
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      _snack('Error: ${e.toString()}');
    }
  }

  void _mostrarExito() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
            const Text('¡Mantenimiento registrado!',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text(
              'El historial del equipo y el estado de la incidencia han sido actualizados.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 13, height: 1.45),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);  // cerrar dialog
                Navigator.pop(context);  // volver al detalle
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));

  // ── Seleccionar hora ──────────────────────────────────────────────
  Future<void> _pickTime(bool esInicio) async {
    final now = esInicio ? _horaInicio : _horaFin;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );
    if (picked == null) return;
    final date = DateTime(now.year, now.month, now.day,
        picked.hour, picked.minute);
    setState(() => esInicio ? _horaInicio = date : _horaFin = date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Registro de Mantenimiento',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Info del equipo ─────────────────────────────────────
            _Card(
              child: Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.medical_services_outlined,
                        color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.equipoNombre,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.textPrimary)),
                        Text(widget.equipoData['area'] ?? '—',
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── 1. Tipo ─────────────────────────────────────────────
            _SectionHeader('1. Tipo de mantenimiento', Icons.category_outlined),
            const SizedBox(height: 10),
            _Card(
              child: Row(
                children: ['Preventivo', 'Correctivo'].map((t) {
                  final sel = _tipo == t;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _tipo = t),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: sel ? AppColors.primary : AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: sel ? AppColors.primary : AppColors.divider),
                        ),
                        child: Text(t,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: sel ? Colors.white : AppColors.textPrimary,
                                fontWeight: sel
                                    ? FontWeight.bold
                                    : FontWeight.normal)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // ── 2. Tiempo ───────────────────────────────────────────
            _SectionHeader('2. Horas de trabajo', Icons.schedule_outlined),
            const SizedBox(height: 10),
            _Card(
              child: Row(
                children: [
                  Expanded(
                    child: _TimeSelector(
                      label:  'Inicio',
                      time:   _horaInicio,
                      onTap:  () => _pickTime(true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.arrow_forward, color: AppColors.textSecondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TimeSelector(
                      label:  'Fin',
                      time:   _horaFin,
                      onTap:  () => _pickTime(false),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── 3. Diagnóstico ──────────────────────────────────────
            _SectionHeader('3. Diagnóstico técnico', Icons.biotech_outlined),
            const SizedBox(height: 10),
            _Card(
              child: TextFormField(
                controller: _diagCtrl,
                maxLines: 3,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
                decoration: _inputDeco(
                    'Describe el diagnóstico técnico...',
                    Icons.notes_rounded),
              ),
            ),

            const SizedBox(height: 16),

            // ── 4. Acciones ─────────────────────────────────────────
            _SectionHeader('4. Acciones realizadas', Icons.build_outlined),
            const SizedBox(height: 10),
            _Card(
              child: TextFormField(
                controller: _accionesCtrl,
                maxLines: 3,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
                decoration:
                    _inputDeco('Describe las acciones realizadas...', Icons.list_rounded),
              ),
            ),

            const SizedBox(height: 16),

            // ── 5. Fotos Antes ──────────────────────────────────────
            _SectionHeader('5. Fotografías', Icons.photo_camera_outlined),
            const SizedBox(height: 10),
            _FotoSeccion(
              titulo:  'Antes del mantenimiento',
              color:   AppColors.pending,
              fotos:   _fotosAntes,
              onAdd:   () => _agregarFoto(_fotosAntes),
              onRemove:(i) => setState(() => _fotosAntes.removeAt(i)),
            ),
            const SizedBox(height: 10),
            _FotoSeccion(
              titulo:  'Durante el mantenimiento',
              color:   AppColors.inProcess,
              fotos:   _fotosDurante,
              onAdd:   () => _agregarFoto(_fotosDurante),
              onRemove:(i) => setState(() => _fotosDurante.removeAt(i)),
            ),
            const SizedBox(height: 10),
            _FotoSeccion(
              titulo:  'Después del mantenimiento',
              color:   AppColors.resolved,
              fotos:   _fotosDespues,
              onAdd:   () => _agregarFoto(_fotosDespues),
              onRemove:(i) => setState(() => _fotosDespues.removeAt(i)),
            ),

            const SizedBox(height: 16),

            // ── 6. Repuestos ────────────────────────────────────────
            _SectionHeader('6. Repuestos utilizados', Icons.inventory_2_outlined),
            const SizedBox(height: 10),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_repuestos.isNotEmpty) ...[
                    ..._repuestos.asMap().entries.map((e) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                            radius: 16,
                            backgroundColor: Color(0xFFEEF2FF),
                            child: Icon(Icons.build_outlined,
                                color: AppColors.primary, size: 14),
                          ),
                          title: Text(e.value.nombre,
                              style: const TextStyle(fontSize: 13)),
                          subtitle: Text(
                              '${e.value.codigo} · Cant: ${e.value.cantidad}',
                              style: const TextStyle(fontSize: 11)),
                          trailing: IconButton(
                            icon: const Icon(Icons.close,
                                color: AppColors.error, size: 18),
                            onPressed: () =>
                                setState(() => _repuestos.removeAt(e.key)),
                          ),
                        )),
                    const Divider(),
                  ],
                  OutlinedButton.icon(
                    onPressed: _abrirSelectorRepuestos,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Agregar repuesto'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      minimumSize: const Size(double.infinity, 40),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── 7. Estado final del equipo ──────────────────────────
            _SectionHeader('7. Estado final del equipo', Icons.verified_outlined),
            const SizedBox(height: 10),
            _Card(
              child: DropdownButtonFormField<String>(
                value: _estadoFinal,
                decoration: _inputDeco(
                    'Estado final', Icons.check_circle_outline),
                items: const [
                  DropdownMenuItem(value: 'Operativo',      child: Text('Operativo')),
                  DropdownMenuItem(value: 'En observación', child: Text('En observación')),
                  DropdownMenuItem(value: 'Fuera de servicio', child: Text('Fuera de servicio')),
                  DropdownMenuItem(value: 'Pendiente repuesto', child: Text('Pendiente de repuesto')),
                ],
                onChanged: (v) => setState(() => _estadoFinal = v!),
              ),
            ),

            const SizedBox(height: 16),

            // ── 8. Observaciones ────────────────────────────────────
            _SectionHeader('8. Observaciones', Icons.comment_outlined),
            const SizedBox(height: 10),
            _Card(
              child: TextFormField(
                controller: _obsCtrl,
                maxLines: 3,
                decoration: _inputDeco(
                    'Observaciones adicionales (opcional)',
                    Icons.notes_rounded),
              ),
            ),

            const SizedBox(height: 28),

            // ── Guardar ─────────────────────────────────────────────
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _guardando ? null : _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 3,
                ),
                child: _guardando
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white),
                          ),
                          SizedBox(width: 12),
                          Text('Guardando...', style: TextStyle(fontSize: 16)),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save_outlined, size: 20),
                          SizedBox(width: 8),
                          Text('Guardar Mantenimiento',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

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
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
        ],
      );
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      );
}

class _TimeSelector extends StatelessWidget {
  final String label;
  final DateTime time;
  final VoidCallback onTap;
  const _TimeSelector(
      {required this.label, required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11)),
              const SizedBox(height: 4),
              Text(
                '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20),
              ),
            ],
          ),
        ),
      );
}

class _FotoSeccion extends StatelessWidget {
  final String titulo;
  final Color color;
  final List<File> fotos;
  final VoidCallback onAdd;
  final void Function(int) onRemove;

  const _FotoSeccion({
    required this.titulo,
    required this.color,
    required this.fotos,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10, height: 10,
                    decoration:
                        BoxDecoration(shape: BoxShape.circle, color: color),
                  ),
                  const SizedBox(width: 8),
                  Text(titulo,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppColors.textPrimary)),
                ],
              ),
              const SizedBox(height: 10),
              if (fotos.isNotEmpty) ...[
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: fotos.length,
                    itemBuilder: (_, i) => Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(fotos[i],
                                width: 80, height: 80, fit: BoxFit.cover),
                          ),
                        ),
                        Positioned(
                          top: 2, right: 10,
                          child: GestureDetector(
                            onTap: () => onRemove(i),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                  color: AppColors.error,
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onAdd,
                      icon: const Icon(Icons.add_a_photo_outlined, size: 16),
                      label: const Text('Foto', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: color,
                        side: BorderSide(color: color.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}

// ── Selector de repuestos (BottomSheet con Firestore) ────────────────
class _SelectorRepuestosSheet extends StatefulWidget {
  const _SelectorRepuestosSheet();

  @override
  State<_SelectorRepuestosSheet> createState() =>
      _SelectorRepuestosSheetState();
}

class _SelectorRepuestosSheetState extends State<_SelectorRepuestosSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // Demo data para cuando Firestore no tiene repuestos
  static const _demo = [
    {'id': 'REP001', 'nombre': 'Cable ECG 10 derivaciones',  'codigo': 'REP-001', 'cantidad': 15, 'ubicacion': 'Almacén A'},
    {'id': 'REP002', 'nombre': 'Sensor SpO2 adulto',          'codigo': 'REP-002', 'cantidad': 8,  'ubicacion': 'Almacén B'},
    {'id': 'REP003', 'nombre': 'Batería Monitor 7.4V',        'codigo': 'REP-003', 'cantidad': 4,  'ubicacion': 'Almacén A'},
    {'id': 'REP004', 'nombre': 'Fuente de Alimentación 12V',  'codigo': 'REP-004', 'cantidad': 3,  'ubicacion': 'Almacén C'},
    {'id': 'REP005', 'nombre': 'Fusible 3A 250V',             'codigo': 'REP-005', 'cantidad': 40, 'ubicacion': 'Almacén General'},
    {'id': 'REP006', 'nombre': 'Manguito presión adulto',     'codigo': 'REP-006', 'cantidad': 12, 'ubicacion': 'Almacén B'},
    {'id': 'REP007', 'nombre': 'Pantalla LCD 7"',             'codigo': 'REP-007', 'cantidad': 2,  'ubicacion': 'Almacén C'},
  ];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.9,
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
                const Text('Seleccionar repuesto',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 10),
                TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Buscar repuesto...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('repuestos')
                  .orderBy('nombre')
                  .snapshots(),
              builder: (_, snap) {
                final docs = snap.data?.docs ?? [];

                if (docs.isEmpty) {
                  // Usar datos demo
                  final filtrados = _query.isEmpty
                      ? _demo
                      : _demo.where((r) => (r['nombre'] as String)
                          .toLowerCase()
                          .contains(_query)).toList();
                  return ListView.builder(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    itemCount: filtrados.length,
                    itemBuilder: (_, i) => _RepuestoTile(
                      data: Map<String, dynamic>.from(filtrados[i]),
                      onTap: () =>
                          Navigator.pop(ctx, Map<String, dynamic>.from(filtrados[i])),
                    ),
                  );
                }

                final filtrados = _query.isEmpty
                    ? docs
                    : docs.where((d) => (d.data()['nombre'] ?? '')
                        .toString()
                        .toLowerCase()
                        .contains(_query)).toList();

                return ListView.builder(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  itemCount: filtrados.length,
                  itemBuilder: (_, i) {
                    final data = Map<String, dynamic>.from(filtrados[i].data())
                      ..['id'] = filtrados[i].id;
                    return _RepuestoTile(
                      data:  data,
                      onTap: () => Navigator.pop(ctx, data),
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

class _RepuestoTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;
  const _RepuestoTile({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cantidad = (data['cantidad'] ?? 0) as int;
    return ListTile(
      onTap: cantidad > 0 ? onTap : null,
      leading: CircleAvatar(
        backgroundColor: cantidad > 0
            ? AppColors.primary.withOpacity(0.1)
            : Colors.grey.shade100,
        child: Icon(Icons.build_outlined,
            color: cantidad > 0 ? AppColors.primary : Colors.grey,
            size: 20),
      ),
      title: Text(data['nombre'] ?? '',
          style: TextStyle(
              fontSize: 14,
              color:
                  cantidad > 0 ? AppColors.textPrimary : AppColors.textSecondary)),
      subtitle: Text('${data['codigo']} · Stock: $cantidad',
          style: const TextStyle(fontSize: 12)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: cantidad > 0
              ? AppColors.resolved.withOpacity(0.1)
              : AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          cantidad > 0 ? 'Disponible' : 'Agotado',
          style: TextStyle(
              fontSize: 11,
              color: cantidad > 0 ? AppColors.resolved : AppColors.error,
              fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
