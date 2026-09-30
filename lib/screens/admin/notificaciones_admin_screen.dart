import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../config/app_colors.dart';

// ═══════════════════════════════════════════════════════════════════════
//  NOTIFICACIONES ADMIN
// ═══════════════════════════════════════════════════════════════════════
class NotificacionesAdminScreen extends StatefulWidget {
  const NotificacionesAdminScreen({super.key});

  @override
  State<NotificacionesAdminScreen> createState() =>
      _NotificacionesAdminScreenState();
}

class _NotificacionesAdminScreenState
    extends State<NotificacionesAdminScreen> {
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  static const _demo = [
    {'titulo': 'Incidencia crítica registrada', 'cuerpo': 'Ventilador VM-300 fuera de servicio en UCI', 'tipo': 'critico', 'leido': false, 'hora': 'Hace 3 min'},
    {'titulo': 'Nuevo usuario registrado',      'cuerpo': 'Enfermera Ana Torres se unió a Hospital Norte', 'tipo': 'sistema', 'leido': false, 'hora': 'Hace 15 min'},
    {'titulo': 'Bajo stock de repuesto',        'cuerpo': 'Batería Monitor 7.4V — 4 unidades restantes', 'tipo': 'warning', 'leido': false, 'hora': 'Hace 1h'},
    {'titulo': 'Equipo fuera de servicio',      'cuerpo': 'Desfibrilador DEF-003 inactivo por 72h', 'tipo': 'critico', 'leido': true, 'hora': 'Ayer 14:30'},
    {'titulo': 'Mantenimiento completado',      'cuerpo': 'Carlos Quispe finalizó mantenimiento en Monitor XR-200', 'tipo': 'info', 'leido': true, 'hora': 'Ayer 09:15'},
    {'titulo': 'Nueva incidencia',              'cuerpo': 'Bomba de Infusión BIF-012 — Área Neonatología', 'tipo': 'incidencia', 'leido': true, 'hora': '12/06/2026'},
  ];

  Future<void> _marcarTodas() async {
    if (_uid.isEmpty) return;
    final snap = await FirebaseFirestore.instance
        .collection('notificaciones')
        .doc(_uid)
        .collection('items')
        .where('leido', isEqualTo: false)
        .get();
    for (final d in snap.docs) {
      await d.reference.update({'leido': true});
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          title: const Text('Notificaciones',
              style: TextStyle(fontWeight: FontWeight.bold)),
          elevation: 0,
          actions: [
            TextButton.icon(
              onPressed: _marcarTodas,
              icon: const Icon(Icons.done_all, color: Colors.white, size: 18),
              label: const Text('Todas leídas',
                  style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ],
        ),
        body: _uid.isEmpty
            ? _demoList()
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
                  if (docs.isEmpty) return _demoList();

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final data  = docs[i].data();
                      final leido = data['leido'] as bool? ?? false;
                      final ts    = data['timestamp'] as Timestamp?;
                      final hora  = ts != null ? _fmt(ts.toDate()) : '';
                      return _NotifTile(
                        titulo: data['titulo'] ?? '',
                        cuerpo: data['cuerpo'] ?? '',
                        tipo:   data['tipo']   ?? 'info',
                        leido:  leido,
                        hora:   hora,
                        onTap:  leido
                            ? null
                            : () => docs[i].reference.update({'leido': true}),
                      );
                    },
                  );
                },
              ),
      );

  Widget _demoList() => ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _demo.length,
        itemBuilder: (_, i) => _NotifTile(
          titulo: _demo[i]['titulo'] as String,
          cuerpo: _demo[i]['cuerpo'] as String,
          tipo:   _demo[i]['tipo']   as String,
          leido:  _demo[i]['leido']  as bool,
          hora:   _demo[i]['hora']   as String,
        ),
      );

  String _fmt(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours   < 24) return 'Hace ${diff.inHours}h';
    if (diff.inDays    == 1) return 'Ayer ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
    return '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
  }
}

class _NotifTile extends StatelessWidget {
  final String titulo, cuerpo, tipo, hora;
  final bool leido;
  final VoidCallback? onTap;
  const _NotifTile({
    required this.titulo, required this.cuerpo,
    required this.tipo, required this.leido, required this.hora, this.onTap,
  });

  IconData get _icon {
    switch (tipo) {
      case 'critico':    return Icons.error_outline_rounded;
      case 'warning':    return Icons.warning_amber_rounded;
      case 'sistema':    return Icons.settings_outlined;
      case 'incidencia': return Icons.report_outlined;
      default:           return Icons.info_outline_rounded;
    }
  }

  Color get _color {
    switch (tipo) {
      case 'critico':    return AppColors.error;
      case 'warning':    return AppColors.pending;
      case 'incidencia': return AppColors.primary;
      default:           return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: leido ? Colors.transparent : _color.withOpacity(0.04),
            border: Border(
              bottom: BorderSide(color: AppColors.divider, width: 0.5),
              left: BorderSide(
                  color: leido ? Colors.transparent : _color, width: 3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                    color: _color.withOpacity(0.12), shape: BoxShape.circle),
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
                            width: 8, height: 8,
                            decoration: BoxDecoration(
                                color: _color, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(cuerpo,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Text(hora,
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
