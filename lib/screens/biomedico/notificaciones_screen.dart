import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../config/app_colors.dart';

// ═══════════════════════════════════════════════════════════════════════
//  NOTIFICACIONES
// ═══════════════════════════════════════════════════════════════════════
class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  static const _demo = [
    {
      'titulo': 'Nueva incidencia asignada',
      'cuerpo': 'Monitor Cardíaco XR-200 — UCI, requiere atención.',
      'tipo': 'asignacion',
      'leido': false,
      'horaTexto': 'Hace 5 min',
    },
    {
      'titulo': 'Mensaje de Enfermería',
      'cuerpo': 'La enfermera García pregunta sobre el estado del ventilador.',
      'tipo': 'mensaje',
      'leido': false,
      'horaTexto': 'Hace 20 min',
    },
    {
      'titulo': 'Mantenimiento preventivo',
      'cuerpo': 'Desfibrilador DEF-003 programa mantenimiento para mañana.',
      'tipo': 'mantenimiento',
      'leido': true,
      'horaTexto': 'Ayer 14:30',
    },
    {
      'titulo': 'Solicitud aceptada',
      'cuerpo': 'Has aceptado la solicitud #INC-0047 correctamente.',
      'tipo': 'sistema',
      'leido': true,
      'horaTexto': 'Ayer 10:15',
    },
    {
      'titulo': 'Equipo reparado',
      'cuerpo': 'Bomba de Infusión BIF-012 marcada como Operativa.',
      'tipo': 'estado',
      'leido': true,
      'horaTexto': '12/06/2026',
    },
  ];

  Future<void> _marcarTodosLeidos() async {
    if (_uid.isEmpty) return;
    final snap = await FirebaseFirestore.instance
        .collection('notificaciones')
        .doc(_uid)
        .collection('items')
        .where('leido', isEqualTo: false)
        .get();
    for (final doc in snap.docs) {
      await doc.reference.update({'leido': true});
    }
  }

  Future<void> _marcarLeido(String docId) async {
    if (_uid.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('notificaciones')
        .doc(_uid)
        .collection('items')
        .doc(docId)
        .update({'leido': true});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Notificaciones',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _marcarTodosLeidos,
            icon: const Icon(Icons.done_all, color: Colors.white, size: 18),
            label: const Text('Todas leídas',
                style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
      body: _uid.isEmpty
          ? _buildDemoList()
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('notificaciones')
                  .doc(_uid)
                  .collection('items')
                  .orderBy('timestamp', descending: true)
                  .limit(50)
                  .snapshots(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) return _buildDemoList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final data  = docs[i].data();
                    final leido = data['leido'] as bool? ?? false;
                    final ts    = data['timestamp'] as Timestamp?;
                    final hora  = ts != null ? _formatFecha(ts.toDate()) : '';
                    return _NotifTile(
                      titulo:    data['titulo']  ?? '',
                      cuerpo:    data['cuerpo']  ?? '',
                      tipo:      data['tipo']    ?? 'sistema',
                      leido:     leido,
                      horaTexto: hora,
                      onTap: leido ? null : () => _marcarLeido(docs[i].id),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildDemoList() => ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _demo.length,
        itemBuilder: (_, i) {
          final n = _demo[i];
          return _NotifTile(
            titulo:    n['titulo'] as String,
            cuerpo:    n['cuerpo'] as String,
            tipo:      n['tipo']   as String,
            leido:     n['leido']  as bool,
            horaTexto: n['horaTexto'] as String,
          );
        },
      );

  String _formatFecha(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24)   return 'Hace ${diff.inHours}h';
    if (diff.inDays == 1)    return 'Ayer ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
    return '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
  }
}

// ── Tile de notificación ──────────────────────────────────────────────
class _NotifTile extends StatelessWidget {
  final String titulo, cuerpo, tipo, horaTexto;
  final bool leido;
  final VoidCallback? onTap;

  const _NotifTile({
    required this.titulo,
    required this.cuerpo,
    required this.tipo,
    required this.leido,
    required this.horaTexto,
    this.onTap,
  });

  IconData get _icon {
    switch (tipo) {
      case 'asignacion':    return Icons.assignment_turned_in_outlined;
      case 'mensaje':       return Icons.chat_bubble_outline;
      case 'mantenimiento': return Icons.build_outlined;
      case 'estado':        return Icons.check_circle_outline;
      default:              return Icons.notifications_outlined;
    }
  }

  Color get _color {
    switch (tipo) {
      case 'asignacion':    return AppColors.primary;
      case 'mensaje':       return AppColors.accent;
      case 'mantenimiento': return AppColors.pending;
      case 'estado':        return AppColors.resolved;
      default:              return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: leido
                ? Colors.transparent
                : AppColors.primary.withOpacity(0.04),
            border: Border(
              bottom: BorderSide(color: AppColors.divider, width: 0.5),
              left: BorderSide(
                  color: leido ? Colors.transparent : _color,
                  width: 3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(_icon, color: _color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(titulo,
                              style: TextStyle(
                                  fontWeight: leido
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.textPrimary)),
                        ),
                        if (!leido)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                                color: _color, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(cuerpo,
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(horaTexto,
                        style: const TextStyle(
                            color: AppColors.textLight, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
