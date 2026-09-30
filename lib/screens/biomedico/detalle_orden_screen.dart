import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../config/app_colors.dart';
import '../../widgets/status_chip.dart';
import 'registro_mantenimiento_screen.dart';
import 'chat_enfermeria_screen.dart';
import 'historial_equipo_screen.dart';

// ═══════════════════════════════════════════════════════════════════════
//  DETALLE DE SOLICITUD / ORDEN
// ═══════════════════════════════════════════════════════════════════════
class DetalleOrdenScreen extends StatefulWidget {
  final String incidenciaId;
  final Map<String, dynamic>? data;

  const DetalleOrdenScreen({
    super.key,
    required this.incidenciaId,
    this.data,
  });

  @override
  State<DetalleOrdenScreen> createState() => _DetalleOrdenScreenState();
}

class _DetalleOrdenScreenState extends State<DetalleOrdenScreen> {
  final _comentCtrl = TextEditingController();
  bool _enviandoComent = false;

  @override
  void dispose() {
    _comentCtrl.dispose();
    super.dispose();
  }

  // ── Cambiar estado de la incidencia ─────────────────────────────
  Future<void> _cambiarEstado(
      BuildContext ctx, String incId, String nuevoEstado) async {
    final uid   = FirebaseAuth.instance.currentUser?.uid ?? '';
    final ahora = DateTime.now();

    await FirebaseFirestore.instance
        .collection('incidencias')
        .doc(incId)
        .update({
      'estado':    nuevoEstado,
      'fechaActualizacion': Timestamp.fromDate(ahora),
      'historial': FieldValue.arrayUnion([
        {
          'fecha':       Timestamp.fromDate(ahora),
          'descripcion': 'Estado cambiado a $nuevoEstado',
          'estado':      nuevoEstado,
          'autor':       uid,
        }
      ]),
    });

    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Text('Estado actualizado: $nuevoEstado'),
        backgroundColor: AppColors.resolved,
        behavior: SnackBarBehavior.floating,
      ));
      Navigator.pop(ctx);
    }
  }

  // ── Agregar comentario / observación ────────────────────────────
  Future<void> _agregarComentario(
      String incId, String texto) async {
    if (texto.trim().isEmpty) return;
    setState(() => _enviandoComent = true);

    final uid   = FirebaseAuth.instance.currentUser?.uid ?? '';
    final ahora = DateTime.now();

    try {
      await FirebaseFirestore.instance
          .collection('incidencias')
          .doc(incId)
          .update({
        'comentarios': FieldValue.arrayUnion([
          {
            'texto':     texto.trim(),
            'autor':     uid,
            'timestamp': Timestamp.fromDate(ahora),
          }
        ]),
        'historial': FieldValue.arrayUnion([
          {
            'fecha':       Timestamp.fromDate(ahora),
            'descripcion': 'Observación agregada por biomédico',
            'estado':      null,
            'autor':       uid,
          }
        ]),
      });
      _comentCtrl.clear();
    } catch (_) {}

    if (mounted) setState(() => _enviandoComent = false);
  }

  // ── Mostrar selector de estado ──────────────────────────────────
  void _mostrarCambioEstado(BuildContext ctx, String incId, String estadoActual) {
    const estados = [
      'Asignada',
      'En Proceso',
      'Resuelta',
      'Cerrada',
    ];
    showModalBottomSheet<void>(
      context: ctx,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Column(
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
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('Cambiar estado',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
          ),
          const SizedBox(height: 8),
          ...estados.map((e) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: StatusChip.colorFor(e).withOpacity(0.15),
                  radius: 18,
                  child: Icon(Icons.circle,
                      size: 10, color: StatusChip.colorFor(e)),
                ),
                title: Text(e),
                trailing: estadoActual == e
                    ? const Icon(Icons.check, color: AppColors.resolved)
                    : null,
                onTap: () => _cambiarEstado(ctx, incId, e),
              )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('incidencias')
          .doc(widget.incidenciaId)
          .snapshots(),
      builder: (ctx, snap) {
        final Map<String, dynamic> data =
            snap.data?.data() ?? widget.data ?? {};
        final bool loading =
            snap.connectionState == ConnectionState.waiting && widget.data == null;

        if (loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final equipo    = data['equipoNombre']  ?? 'Equipo';
        final estado    = data['estado']         ?? 'Pendiente';
        final tipo      = data['tipo']            ?? '—';
        final desc      = data['descripcion']     ?? '—';
        final area      = data['equipoArea']      ?? data['equipo']?['area'] ?? '—';
        final marca     = data['equipo']?['marca']  ?? '—';
        final modelo    = data['equipo']?['modelo'] ?? '—';
        final serie     = data['equipo']?['serie']  ?? '—';
        final codigo    = data['equipo']?['id']     ?? data['equipoId'] ?? '—';
        final enfNombre = data['enfermeraNombre']    ?? 'Enfermera';
        final fotos     = List<String>.from(data['fotos'] ?? []);
        final historial = List<Map<String, dynamic>>.from(
            (data['historial'] ?? []).map((h) => Map<String, dynamic>.from(h)));
        final comentarios = List<Map<String, dynamic>>.from(
            (data['comentarios'] ?? []).map((c) => Map<String, dynamic>.from(c)));

        final ts = data['fechaCreacion'] as Timestamp?;
        final fecha = ts != null
            ? _fmt(ts.toDate())
            : '—';

        final uid = FirebaseAuth.instance.currentUser?.uid;
        final esAsignado = data['tecnicoId'] == uid;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              // ── SliverAppBar ────────────────────────────────────
              SliverAppBar(
                pinned: true,
                expandedHeight: 180,
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primary, AppColors.primaryLight],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        CircleAvatar(
                          radius: 38,
                          backgroundColor: Colors.white.withOpacity(0.15),
                          child: const Icon(Icons.medical_services_outlined,
                              color: Colors.white, size: 36),
                        ),
                        const SizedBox(height: 8),
                        Text(equipo,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        StatusChip(estado: estado, small: true),
                      ],
                    ),
                  ),
                  title: Text(equipo,
                      style: const TextStyle(fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ),

              // ── Cuerpo ─────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Info del equipo ────────────────────────────
                    _Section(
                      titulo: 'Información del Equipo',
                      icon: Icons.medical_services_outlined,
                      child: Column(
                        children: [
                          _InfoRow('Código',     codigo),
                          _InfoRow('Marca',      marca),
                          _InfoRow('Modelo',     modelo),
                          _InfoRow('N.º Serie',  serie),
                          _InfoRow('Área',       area),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── Info de la incidencia ──────────────────────
                    _Section(
                      titulo: 'Información de la Incidencia',
                      icon: Icons.info_outline,
                      child: Column(
                        children: [
                          _InfoRow('Fecha',       fecha),
                          _InfoRow('Reportado',   enfNombre),
                          _InfoRow('Tipo',        tipo),
                          const SizedBox(height: 8),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Descripción',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12)),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(desc,
                                style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                    height: 1.45)),
                          ),
                        ],
                      ),
                    ),

                    // ── Fotografías ────────────────────────────────
                    if (fotos.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _Section(
                        titulo: 'Fotografías',
                        icon: Icons.photo_library_outlined,
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8),
                          itemCount: fotos.length,
                          itemBuilder: (_, i) => ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(fotos[i],
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                    color: AppColors.background,
                                    child: const Icon(Icons.broken_image,
                                        color: AppColors.textSecondary))),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),

                    // ── Timeline ───────────────────────────────────
                    _Section(
                      titulo: 'Historial / Timeline',
                      icon: Icons.timeline_outlined,
                      child: historial.isEmpty
                          ? const Text('Sin eventos registrados',
                              style: TextStyle(color: AppColors.textSecondary))
                          : Column(
                              children: historial.reversed
                                  .toList()
                                  .asMap()
                                  .entries
                                  .map((e) => _TimelineItem(
                                        isLast: e.key ==
                                            historial.length - 1,
                                        item: e.value,
                                      ))
                                  .toList(),
                            ),
                    ),

                    const SizedBox(height: 14),

                    // ── Comentarios ────────────────────────────────
                    _Section(
                      titulo: 'Comentarios',
                      icon: Icons.comment_outlined,
                      child: Column(
                        children: [
                          ...comentarios.map((c) => _ComentarioTile(c)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _comentCtrl,
                                  decoration: InputDecoration(
                                    hintText: 'Agregar observación...',
                                    filled: true,
                                    fillColor: AppColors.background,
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        borderSide: BorderSide.none),
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 10),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _enviandoComent
                                  ? const SizedBox(
                                      width: 40, height: 40,
                                      child: CircularProgressIndicator())
                                  : IconButton(
                                      onPressed: () => _agregarComentario(
                                          widget.incidenciaId,
                                          _comentCtrl.text),
                                      icon: const Icon(Icons.send_rounded),
                                      style: IconButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Acciones ───────────────────────────────────
                    _Section(
                      titulo: 'Acciones',
                      icon: Icons.flash_on_outlined,
                      child: Column(
                        children: [
                          // Aceptar
                          if (data['tecnicoId'] == null ||
                              data['estado'] == 'Pendiente')
                            _AccionBtn(
                              icon: Icons.check_circle_outline,
                              label: 'Aceptar solicitud',
                              color: AppColors.resolved,
                              onTap: () async {
                                final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
                                final ahora = DateTime.now();
                                await FirebaseFirestore.instance
                                    .collection('incidencias')
                                    .doc(widget.incidenciaId)
                                    .update({
                                  'estado':    'Asignada',
                                  'tecnicoId': uid,
                                  'fechaActualizacion': Timestamp.fromDate(ahora),
                                  'historial': FieldValue.arrayUnion([
                                    {
                                      'fecha':       Timestamp.fromDate(ahora),
                                      'descripcion': 'Solicitud aceptada',
                                      'estado':      'Asignada',
                                      'autor':       uid,
                                    }
                                  ]),
                                });
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                    content: Text('Solicitud aceptada'),
                                    backgroundColor: AppColors.resolved,
                                    behavior: SnackBarBehavior.floating,
                                  ));
                                }
                              },
                            ),

                          // Cambiar estado
                          _AccionBtn(
                            icon: Icons.sync_alt_rounded,
                            label: 'Cambiar estado',
                            color: AppColors.assigned,
                            onTap: () => _mostrarCambioEstado(
                                context, widget.incidenciaId, estado),
                          ),

                          // Iniciar mantenimiento
                          if (esAsignado || data['tecnicoId'] == null)
                            _AccionBtn(
                              icon: Icons.build_outlined,
                              label: 'Iniciar mantenimiento',
                              color: AppColors.inProcess,
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => RegistroMantenimientoScreen(
                                            incidenciaId: widget.incidenciaId,
                                            equipoNombre: equipo,
                                            equipoData: Map<String, dynamic>.from(
                                                data['equipo'] ?? {}),
                                          ))),
                            ),

                          // Historial del equipo
                          _AccionBtn(
                            icon: Icons.history_outlined,
                            label: 'Historial del equipo',
                            color: AppColors.primary,
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => HistorialEquipoScreen(
                                          equipoId: data['equipoId'] ?? '',
                                          equipoNombre: equipo,
                                          equipoData: Map<String, dynamic>.from(
                                              data['equipo'] ?? {}),
                                        ))),
                          ),

                          // Chat con enfermera
                          _AccionBtn(
                            icon: Icons.chat_bubble_outline_rounded,
                            label: 'Chat con enfermería',
                            color: AppColors.accent,
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => ChatEnfermeriaScreen(
                                          incidenciaId: widget.incidenciaId,
                                          titulo: 'Chat — $equipo',
                                        ))),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

// ════════════════════════════════════════════════════════════════════
//  WIDGETS
// ════════════════════════════════════════════════════════════════════

class _Section extends StatelessWidget {
  final String titulo;
  final IconData icon;
  final Widget child;
  const _Section({required this.titulo, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) => Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(titulo,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                ],
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 88,
              child: Text(label,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ),
          ],
        ),
      );
}

class _TimelineItem extends StatelessWidget {
  final bool isLast;
  final Map<String, dynamic> item;
  const _TimelineItem({required this.isLast, required this.item});

  @override
  Widget build(BuildContext context) {
    final estado = item['estado'] as String? ?? '';
    final desc   = item['descripcion'] as String? ?? '';
    final ts     = item['fecha'] as Timestamp?;
    final fecha  = ts != null
        ? '${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}'
        : '';
    final color  = estado.isNotEmpty
        ? StatusChip.colorFor(estado)
        : AppColors.textSecondary;

    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                    shape: BoxShape.circle, color: color),
              ),
              if (!isLast)
                Expanded(
                    child: Container(
                        width: 2,
                        color: AppColors.divider)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(desc,
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500)),
                  if (estado.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    StatusChip(estado: estado, small: true),
                  ],
                  const SizedBox(height: 2),
                  Text(fecha,
                      style: const TextStyle(
                          color: AppColors.textLight, fontSize: 11)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComentarioTile extends StatelessWidget {
  final Map<String, dynamic> c;
  const _ComentarioTile(this.c);

  @override
  Widget build(BuildContext context) {
    final ts = c['timestamp'] as Timestamp?;
    final fecha = ts != null
        ? '${ts.toDate().day}/${ts.toDate().month} ${ts.toDate().hour}:${ts.toDate().minute.toString().padLeft(2, '0')}'
        : '';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(c['texto'] as String? ?? '',
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 13)),
          const SizedBox(height: 4),
          Text(fecha,
              style: const TextStyle(
                  color: AppColors.textLight, fontSize: 11)),
        ],
      ),
    );
  }
}

class _AccionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _AccionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton.icon(
            onPressed: onTap,
            icon: Icon(icon, size: 20, color: color),
            label: Text(label,
                style: TextStyle(color: color, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: color.withOpacity(0.5)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      );
}
