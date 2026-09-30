import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../models/incidencia.dart';
import '../../widgets/status_chip.dart';
import 'detalle_solicitud_screen.dart';

// ═══════════════════════════════════════════════════════════════════════
//  MIS SOLICITUDES — MÓDULO ENFERMERA
// ═══════════════════════════════════════════════════════════════════════
class SolicitudesEnfermeraScreen extends StatefulWidget {
  const SolicitudesEnfermeraScreen({super.key});

  @override
  State<SolicitudesEnfermeraScreen> createState() =>
      _SolicitudesEnfermeraScreenState();
}

class _SolicitudesEnfermeraScreenState
    extends State<SolicitudesEnfermeraScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _filtroEstado = 'Todas';

  // Demo data — TODO: cargar desde Firestore con StreamBuilder
  final List<Incidencia> _todas = IncidenciaDemo.lista;

  static const _estados = [
    'Todas',
    'Pendiente',
    'Asignada',
    'En Proceso',
    'Resuelta',
  ];

  List<Incidencia> get _filtradas {
    return _todas.where((inc) {
      final matchEstado =
          _filtroEstado == 'Todas' || inc.estado == _filtroEstado;
      final matchQuery = _query.isEmpty ||
          inc.equipoNombre.toLowerCase().contains(_query.toLowerCase()) ||
          inc.tipoIncidencia.toLowerCase().contains(_query.toLowerCase()) ||
          inc.area.toLowerCase().contains(_query.toLowerCase()) ||
          inc.id.toLowerCase().contains(_query.toLowerCase());
      return matchEstado && matchQuery;
    }).toList();
  }

  Map<String, int> get _contadores {
    return {
      'Todas': _todas.length,
      'Pendiente':
          _todas.where((i) => i.estado == 'Pendiente').length,
      'Asignada':
          _todas.where((i) => i.estado == 'Asignada').length,
      'En Proceso':
          _todas.where((i) => i.estado == 'En Proceso').length,
      'Resuelta':
          _todas.where((i) => i.estado == 'Resuelta').length,
    };
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lista = _filtradas;
    final cont = _contadores;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Mis Solicitudes')),
      body: Column(
        children: [
          // ── Buscador ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Buscar por equipo, tipo, área o ID...',
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
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // ── Filtros por estado ────────────────────────────────────
          SizedBox(
            height: 52,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: _estados.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final e = _estados[i];
                final sel = _filtroEstado == e;
                final count = cont[e] ?? 0;

                return GestureDetector(
                  onTap: () => setState(() => _filtroEstado = e),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: sel ? AppColors.primary : AppColors.divider,
                          width: sel ? 0 : 1.5),
                      boxShadow: sel
                          ? [
                              BoxShadow(
                                  color: AppColors.primary.withOpacity(0.25),
                                  blurRadius: 6)
                            ]
                          : [],
                    ),
                    child: Row(
                      children: [
                        Text(e,
                            style: TextStyle(
                                color: sel ? Colors.white : AppColors.textSecondary,
                                fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                                fontSize: 13)),
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: sel
                                ? Colors.white.withOpacity(0.25)
                                : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              color: sel ? Colors.white : AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Lista de solicitudes ──────────────────────────────────
          Expanded(
            child: lista.isEmpty
                ? _buildEmpty()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: lista.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _SolicitudCard(
                      incidencia: lista[i],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetalleSolicitudEnfermeraScreen(
                            incidencia: lista[i],
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _query.isNotEmpty ? Icons.search_off : Icons.assignment_outlined,
            size: 72,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            _query.isNotEmpty
                ? 'Sin resultados para "$_query"'
                : 'No tienes solicitudes\n$_filtroEstado${_filtroEstado == 'Todas' ? '' : 's'}',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 15, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  CARD DE SOLICITUD
// ═══════════════════════════════════════════════════════════════════════
class _SolicitudCard extends StatelessWidget {
  final Incidencia incidencia;
  final VoidCallback onTap;

  const _SolicitudCard({required this.incidencia, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final inc = incidencia;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ],
        ),
        child: Column(
          children: [
            // ── Cabecera ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: AppColors.divider, width: 0.8)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _iconColor(inc.tipoIncidencia).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _iconFor(inc.tipoIncidencia),
                      color: _iconColor(inc.tipoIncidencia),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          inc.equipoNombre,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 11,
                                color: AppColors.textSecondary),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                inc.area,
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  StatusChip(estado: inc.estado, small: true),
                ],
              ),
            ),

            // ── Cuerpo ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Row(
                children: [
                  // Tipo
                  _InfoPill(
                    icon: Icons.label_outline,
                    text: inc.tipoIncidencia,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 8),
                  // Fecha
                  _InfoPill(
                    icon: Icons.calendar_today_outlined,
                    text: _formatFecha(inc.fechaCreacion),
                    color: AppColors.textSecondary,
                  ),
                  const Spacer(),
                  // Técnico asignado
                  _TecnicoIndicator(tieneTecnico: inc.tieneTecnico),
                ],
              ),
            ),

            // ── ID y flecha ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(6)),
                    child: Text('# ${inc.id}',
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500)),
                  ),
                  const Spacer(),
                  const Text('Ver detalle',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_ios,
                      size: 12, color: AppColors.primary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatFecha(DateTime fecha) {
    final diff = DateTime.now().difference(fecha);
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours}h';
    if (diff.inDays == 1) return 'ayer';
    if (diff.inDays < 7) return 'hace ${diff.inDays} días';
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }

  IconData _iconFor(String tipo) {
    switch (tipo) {
      case 'Avería':
      case 'Fallo eléctrico':
        return Icons.power_off_outlined;
      case 'Calibración':
        return Icons.tune;
      case 'Mantenimiento preventivo':
      case 'Revisión periódica':
        return Icons.build_outlined;
      case 'Alarma persistente':
        return Icons.notification_important_outlined;
      case 'Accidente':
        return Icons.warning_amber_outlined;
      default:
        return Icons.report_problem_outlined;
    }
  }

  Color _iconColor(String tipo) {
    switch (tipo) {
      case 'Avería':
      case 'Fallo eléctrico':
        return AppColors.error;
      case 'Calibración':
        return AppColors.secondary;
      case 'Mantenimiento preventivo':
      case 'Revisión periódica':
        return AppColors.resolved;
      case 'Alarma persistente':
        return AppColors.pending;
      case 'Accidente':
        return AppColors.error;
      default:
        return AppColors.inProcess;
    }
  }
}

// ─── Indicador de técnico asignado ───────────────────────────────────
class _TecnicoIndicator extends StatelessWidget {
  final bool tieneTecnico;
  const _TecnicoIndicator({required this.tieneTecnico});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tieneTecnico
            ? AppColors.resolved.withOpacity(0.1)
            : AppColors.pending.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: tieneTecnico
              ? AppColors.resolved.withOpacity(0.3)
              : AppColors.pending.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.engineering_outlined,
            size: 13,
            color: tieneTecnico ? AppColors.resolved : AppColors.pending,
          ),
          const SizedBox(width: 4),
          Text(
            'Técnico: ${tieneTecnico ? 'Asignado' : 'Sin asignar'}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: tieneTecnico ? AppColors.resolved : AppColors.pending,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info pill ────────────────────────────────────────────────────────
class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoPill(
      {required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(text,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
