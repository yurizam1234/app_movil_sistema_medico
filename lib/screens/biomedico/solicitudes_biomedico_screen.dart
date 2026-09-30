import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../config/app_colors.dart';
import '../../models/incidencia.dart';
import '../../widgets/status_chip.dart';
import 'detalle_orden_screen.dart';

// ═══════════════════════════════════════════════════════════════════════
//  SOLICITUDES — TODAS LAS INCIDENCIAS DEL HOSPITAL
// ═══════════════════════════════════════════════════════════════════════
class SolicitudesBiomedicoScreen extends StatefulWidget {
  const SolicitudesBiomedicoScreen({super.key});

  @override
  State<SolicitudesBiomedicoScreen> createState() =>
      _SolicitudesBiomedicoScreenState();
}

class _SolicitudesBiomedicoScreenState
    extends State<SolicitudesBiomedicoScreen> {
  final _searchCtrl = TextEditingController();
  String _query     = '';
  String _filtro    = 'Todas';

  static const _filtros = [
    'Todas', 'Pendiente', 'Asignada', 'En Proceso', 'Resuelta', 'Cerrada',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Aceptar solicitud (asignar al biomédico actual) ─────────────
  Future<void> _aceptarSolicitud(
      BuildContext ctx, String incidenciaId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final ahora = DateTime.now();
    await FirebaseFirestore.instance
        .collection('incidencias')
        .doc(incidenciaId)
        .update({
      'estado':    'Asignada',
      'tecnicoId': uid,
      'fechaActualizacion': Timestamp.fromDate(ahora),
      'historial': FieldValue.arrayUnion([
        {
          'fecha':       Timestamp.fromDate(ahora),
          'descripcion': 'Solicitud aceptada y asignada al biomédico',
          'estado':      'Asignada',
          'autor':       uid,
        }
      ]),
    });

    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
        content: Text('Solicitud aceptada y asignada a ti'),
        backgroundColor: AppColors.resolved,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Solicitudes',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Buscador ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Buscar equipo, código, área, hospital...',
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
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
            ),
          ),

          // ── Filtros ───────────────────────────────────────────────
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _filtros.length,
              itemBuilder: (_, i) {
                final f = _filtros[i];
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

          // ── Lista ─────────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _buildQuery(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snap.data?.docs ?? [];

                // Filtrar por búsqueda en memoria
                final filtrados = _query.isEmpty
                    ? docs
                    : docs.where((d) {
                        final data = d.data();
                        final q = _query;
                        return (data['equipoNombre'] ?? '')
                                .toString()
                                .toLowerCase()
                                .contains(q) ||
                            (data['equipoArea'] ?? '')
                                .toString()
                                .toLowerCase()
                                .contains(q) ||
                            (data['equipo']?['serie'] ?? '')
                                .toString()
                                .toLowerCase()
                                .contains(q);
                      }).toList();

                if (filtrados.isEmpty) {
                  return _EmptyState(_filtro);
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: filtrados.length,
                  itemBuilder: (_, i) {
                    final data = filtrados[i].data();
                    final id   = filtrados[i].id;
                    return _SolicitudCard(
                      id:     id,
                      data:   data,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => DetalleOrdenScreen(
                                  incidenciaId: id, data: data))),
                      onAceptar: data['estado'] == 'Pendiente'
                          ? () => _aceptarSolicitud(context, id)
                          : null,
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

  Stream<QuerySnapshot<Map<String, dynamic>>> _buildQuery() {
    Query<Map<String, dynamic>> q = FirebaseFirestore.instance
        .collection('incidencias')
        .orderBy('fechaCreacion', descending: true);

    if (_filtro != 'Todas') {
      q = q.where('estado', isEqualTo: _filtro);
    }

    return q.limit(50).snapshots();
  }
}

// ── Tarjeta de solicitud ──────────────────────────────────────────
class _SolicitudCard extends StatelessWidget {
  final String id;
  final Map<String, dynamic> data;
  final VoidCallback onTap;
  final VoidCallback? onAceptar;

  const _SolicitudCard({
    required this.id,
    required this.data,
    required this.onTap,
    this.onAceptar,
  });

  @override
  Widget build(BuildContext context) {
    final equipo  = data['equipoNombre'] ?? 'Equipo';
    final area    = data['equipoArea']   ?? data['equipo']?['area'] ?? '—';
    final estado  = data['estado']       ?? 'Pendiente';
    final tipo    = data['tipo']         ?? '—';
    final ts      = data['fechaCreacion'] as Timestamp?;
    final fecha   = ts != null ? _fmt(ts.toDate()) : '—';
    final enfName = data['enfermeraNombre'] ?? 'Enfermera';

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.medical_services_outlined,
                        color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(equipo,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 12, color: AppColors.textSecondary),
                            const SizedBox(width: 3),
                            Text(area,
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  StatusChip(estado: estado, small: true),
                ],
              ),

              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),

              Row(
                children: [
                  _MetaDato(Icons.category_outlined, tipo),
                  const SizedBox(width: 16),
                  _MetaDato(Icons.calendar_today_outlined, fecha),
                ],
              ),
              const SizedBox(height: 6),
              _MetaDato(Icons.person_outline, 'Reportado por: $enfName'),

              if (onAceptar != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: ElevatedButton.icon(
                    onPressed: onAceptar,
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Aceptar solicitud',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class _MetaDato extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaDato(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(text,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
        ],
      );
}

class _EmptyState extends StatelessWidget {
  final String filtro;
  const _EmptyState(this.filtro);

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              filtro == 'Todas'
                  ? 'No hay solicitudes registradas'
                  : 'No hay solicitudes "$filtro"',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 15),
            ),
          ],
        ),
      );
}
