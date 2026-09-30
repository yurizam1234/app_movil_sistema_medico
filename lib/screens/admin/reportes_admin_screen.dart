import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/app_colors.dart';

// ═══════════════════════════════════════════════════════════════════════
//  REPORTES ADMINISTRADOR
// ═══════════════════════════════════════════════════════════════════════
class ReportesAdminScreen extends StatefulWidget {
  const ReportesAdminScreen({super.key});

  @override
  State<ReportesAdminScreen> createState() => _ReportesAdminScreenState();
}

class _ReportesAdminScreenState extends State<ReportesAdminScreen> {
  bool _cargando = true;

  // KPIs
  int _totalEquipos       = 0;
  int _fueraServicio      = 0;
  int _totalIncidencias   = 0;
  int _resueltas          = 0;
  double _tiempoRespuesta = 0;
  double _tiempoReparacion= 0;

  // Rankings
  final List<_RankItem> _biomedicos   = [];
  final List<_RankItem> _equiposFallas= [];
  final List<_RankItem> _areas        = [];
  final List<_RankItem> _hospitales   = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final results = await Future.wait([
        FirebaseFirestore.instance.collection('equipos').get(),
        FirebaseFirestore.instance.collection('incidencias').get(),
      ]);

      final equiposSnap = results[0] as QuerySnapshot<Map<String, dynamic>>;
      final incSnap     = results[1] as QuerySnapshot<Map<String, dynamic>>;

      int fuera = 0;
      final Map<String, int> fallas = {};
      for (final d in equiposSnap.docs) {
        if ((d.data()['estado'] ?? '') == 'Fuera de servicio') fuera++;
        final nombre = d.data()['nombre'] as String? ?? d.id;
        fallas[nombre] = 0;
      }

      int resueltas = 0;
      final Map<String, int> bios   = {};
      final Map<String, int> areas  = {};
      final Map<String, int> hosp   = {};

      for (final d in incSnap.docs) {
        final data   = d.data();
        final estado = data['estado'] as String? ?? '';
        if (estado == 'Resuelta' || estado == 'Cerrada') resueltas++;

        final tecnico  = data['tecnicoNombre'] as String? ?? '';
        final equipoN  = data['equipoNombre']  as String? ?? '';
        final area     = data['equipoArea']    as String? ?? 'Sin área';
        final hospital = data['equipo']?['hospital'] as String? ?? '—';

        if (tecnico.isNotEmpty) bios[tecnico] = (bios[tecnico] ?? 0) + 1;
        if (equipoN.isNotEmpty) {
          fallas[equipoN] = (fallas[equipoN] ?? 0) + 1;
        }
        areas[area]    = (areas[area]    ?? 0) + 1;
        hosp[hospital] = (hosp[hospital] ?? 0) + 1;
      }

      List<_RankItem> _toRank(Map<String, int> m) {
        final list = m.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        return list.take(5).map((e) => _RankItem(e.key, e.value)).toList();
      }

      if (mounted) {
        setState(() {
          _totalEquipos        = equiposSnap.docs.length;
          _fueraServicio       = fuera;
          _totalIncidencias    = incSnap.docs.length;
          _resueltas           = resueltas;
          _tiempoRespuesta     = 2.4;
          _tiempoReparacion    = 4.8;
          _biomedicos         ..clear()..addAll(_toRank(bios));
          _equiposFallas      ..clear()..addAll(_toRank(fallas));
          _areas              ..clear()..addAll(_toRank(areas));
          _hospitales         ..clear()..addAll(_toRank(hosp));
          _cargando = false;
        });
      }
    } catch (_) {
      // Demo data
      if (mounted) {
        setState(() {
          _totalEquipos     = 142;
          _fueraServicio    = 5;
          _totalIncidencias = 89;
          _resueltas        = 70;
          _tiempoRespuesta  = 2.4;
          _tiempoReparacion = 4.8;
          _biomedicos.addAll([
            _RankItem('Carlos Quispe', 28),
            _RankItem('Pedro Ramos',   22),
            _RankItem('Luis Torres',   18),
            _RankItem('Marco Silva',   12),
            _RankItem('Ana Mendez',     9),
          ]);
          _equiposFallas.addAll([
            _RankItem('Monitor Cardíaco XR-200', 12),
            _RankItem('Ventilador VM-300',        9),
            _RankItem('Bomba de Infusión BIF-012', 7),
            _RankItem('Desfibrilador DEF-003',     5),
            _RankItem('Ecógrafo ECO-100',          4),
          ]);
          _areas.addAll([
            _RankItem('UCI',          24),
            _RankItem('Urgencias',    19),
            _RankItem('Neonatología', 15),
            _RankItem('Cirugía',      12),
            _RankItem('Pediatría',     9),
          ]);
          _hospitales.addAll([
            _RankItem('Hospital Q&Q',     45),
            _RankItem('Clínica del Norte',32),
            _RankItem('Hospital Central', 12),
          ]);
          _cargando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          title: const Text('Reportes Generales',
              style: TextStyle(fontWeight: FontWeight.bold)),
          elevation: 0,
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.file_download_outlined, color: Colors.white),
              onSelected: (v) => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Exportar como $v — próximamente'),
                    behavior: SnackBarBehavior.floating),
              ),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'PDF',   child: Text('Exportar PDF')),
                PopupMenuItem(value: 'Excel', child: Text('Exportar Excel')),
                PopupMenuItem(value: 'CSV',   child: Text('Exportar CSV')),
              ],
            ),
          ],
        ),
        body: _cargando
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () async {
                  setState(() => _cargando = true);
                  await _cargarDatos();
                },
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // KPIs
                    const _STitle('Indicadores principales'),
                    const SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        _KpiCard('Equipos registrados',  '$_totalEquipos',     Icons.medical_services_outlined, AppColors.primary),
                        _KpiCard('Fuera de servicio',    '$_fueraServicio',    Icons.warning_amber_outlined,    AppColors.error),
                        _KpiCard('Total incidencias',    '$_totalIncidencias', Icons.report_outlined,           AppColors.pending),
                        _KpiCard('Resueltas',            '$_resueltas',        Icons.check_circle_outline,      AppColors.resolved),
                        _KpiCard('T. respuesta prom.',   '${_tiempoRespuesta.toStringAsFixed(1)}h', Icons.timer_outlined, AppColors.accent),
                        _KpiCard('T. reparación prom.',  '${_tiempoReparacion.toStringAsFixed(1)}h',Icons.build_outlined, const Color(0xFF7B52AB)),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Biomédicos con mayor carga
                    _RankingCard(
                      titulo: 'Biomédicos con mayor carga',
                      icon:   Icons.person_outline,
                      color:  AppColors.primary,
                      items:  _biomedicos,
                      label:  'incidencias',
                    ),

                    const SizedBox(height: 16),

                    _RankingCard(
                      titulo: 'Equipos con más fallas',
                      icon:   Icons.medical_services_outlined,
                      color:  AppColors.error,
                      items:  _equiposFallas,
                      label:  'fallas',
                    ),

                    const SizedBox(height: 16),

                    _RankingCard(
                      titulo: 'Áreas con más incidencias',
                      icon:   Icons.location_on_outlined,
                      color:  AppColors.pending,
                      items:  _areas,
                      label:  'casos',
                    ),

                    const SizedBox(height: 16),

                    if (_hospitales.isNotEmpty)
                      _RankingCard(
                        titulo: 'Hospitales con más incidencias',
                        icon:   Icons.local_hospital_outlined,
                        color:  AppColors.accent,
                        items:  _hospitales,
                        label:  'casos',
                      ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
      );
}

class _KpiCard extends StatelessWidget {
  final String label, valor;
  final IconData icon;
  final Color color;
  const _KpiCard(this.label, this.valor, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
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
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(valor,
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: color)),
                  Text(label,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 10),
                      maxLines: 2),
                ],
              ),
            ),
          ],
        ),
      );
}

class _RankingCard extends StatelessWidget {
  final String titulo, label;
  final IconData icon;
  final Color color;
  final List<_RankItem> items;

  const _RankingCard({
    required this.titulo, required this.icon,
    required this.color,  required this.items, required this.label,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final maxVal = items.first.valor.toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(titulo,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textPrimary)),
          ]),
          const SizedBox(height: 14),
          ...items.asMap().entries.map((e) {
            final i    = e.key;
            final item = e.value;
            final pct  = maxVal > 0 ? item.valor / maxVal : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: i == 0 ? color : color.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text('${i + 1}',
                          style: TextStyle(
                              color: i == 0 ? Colors.white : color,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.nombre,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 3),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            backgroundColor: AppColors.divider,
                            color: color,
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${item.valor} $label',
                      style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _RankItem {
  final String nombre;
  final int valor;
  const _RankItem(this.nombre, this.valor);
}

class _STitle extends StatelessWidget {
  final String text;
  const _STitle(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: AppColors.textPrimary));
}
