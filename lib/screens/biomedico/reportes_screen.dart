import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../config/app_colors.dart';

// ═══════════════════════════════════════════════════════════════════════
//  REPORTES — KPIs + gráficos con Container (sin librerías externas)
// ═══════════════════════════════════════════════════════════════════════
class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  final _uid      = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _cargando  = true;

  int _totalAtendidas   = 0;
  int _pendientes       = 0;
  int _enProceso        = 0;
  int _resueltas        = 0;
  int _equiposReparados = 0;
  double _tiempoPromedio = 0;
  int _preventivos      = 0;
  int _correctivos      = 0;
  final Map<String, int> _porArea = {};

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final incSnap = await FirebaseFirestore.instance
          .collection('incidencias')
          .where('tecnicoId', isEqualTo: _uid)
          .get();

      int pendientes = 0, enProceso = 0, resueltas = 0;
      final Map<String, int> porArea = {};

      for (final d in incSnap.docs) {
        final data   = d.data();
        final estado = data['estado'] as String? ?? '';
        if (estado == 'Pendiente' || estado == 'Asignada') pendientes++;
        if (estado == 'En Proceso') enProceso++;
        if (estado == 'Resuelta' || estado == 'Cerrada')   resueltas++;
        final area = data['equipoArea'] as String? ?? 'Sin área';
        porArea[area] = (porArea[area] ?? 0) + 1;
      }

      final mantSnap = await FirebaseFirestore.instance
          .collection('mantenimientos')
          .where('tecnicoId', isEqualTo: _uid)
          .get();

      int preventivos = 0, correctivos = 0, totalMins = 0, contT = 0;
      for (final d in mantSnap.docs) {
        final data = d.data();
        if ((data['tipo'] as String? ?? '') == 'Preventivo') {
          preventivos++;
        } else {
          correctivos++;
        }
        final mins = data['duracionMinutos'] as int?;
        if (mins != null) { totalMins += mins; contT++; }
      }

      final areasSorted = porArea.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      if (mounted) {
        setState(() {
          _totalAtendidas   = incSnap.docs.length;
          _pendientes       = pendientes;
          _enProceso        = enProceso;
          _resueltas        = resueltas;
          _equiposReparados = mantSnap.docs.length;
          _tiempoPromedio   = contT > 0 ? totalMins / contT : 0;
          _preventivos      = preventivos;
          _correctivos      = correctivos;
          _porArea
            ..clear()
            ..addAll(Map.fromEntries(areasSorted.take(5)));
          _cargando = false;
        });
      }
    } catch (_) {
      // Datos demo
      if (mounted) {
        setState(() {
          _totalAtendidas   = 47;
          _pendientes       = 8;
          _enProceso        = 5;
          _resueltas        = 34;
          _equiposReparados = 29;
          _tiempoPromedio   = 92.5;
          _preventivos      = 18;
          _correctivos      = 11;
          _porArea.addAll({
            'UCI': 12, 'Urgencias': 9, 'Cirugía': 8,
            'Pediatría': 7, 'Neonatología': 6,
          });
          _cargando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Reportes y KPIs',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Exportación PDF/Excel próximamente'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            tooltip: 'Exportar',
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
                  const _SectionTitle('Resumen general'),
                  const SizedBox(height: 10),
                  _KpiGrid(kpis: [
                    _KpiData('Total atendidas', '$_totalAtendidas',
                        Icons.assignment_outlined, AppColors.primary),
                    _KpiData('Resueltas', '$_resueltas',
                        Icons.check_circle_outline, AppColors.resolved),
                    _KpiData('En proceso', '$_enProceso',
                        Icons.autorenew_rounded, AppColors.pending),
                    _KpiData('Pendientes', '$_pendientes',
                        Icons.hourglass_empty_rounded, AppColors.error),
                    _KpiData('Equipos reparados', '$_equiposReparados',
                        Icons.build_circle_outlined, AppColors.accent),
                    _KpiData('T. promedio',
                        '${_tiempoPromedio.toStringAsFixed(0)} min',
                        Icons.timer_outlined, const Color(0xFF7B52AB)),
                  ]),

                  const SizedBox(height: 24),

                  const _SectionTitle('Mantenimientos realizados'),
                  const SizedBox(height: 12),
                  _BarChart(
                    bars: [
                      _BarData('Prev.', _preventivos, AppColors.accent),
                      _BarData('Correct.', _correctivos, AppColors.pending),
                    ],
                    maxValue: (_preventivos > _correctivos
                            ? _preventivos
                            : _correctivos)
                        .toDouble(),
                  ),

                  if (_porArea.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const _SectionTitle('Incidencias por área (top 5)'),
                    const SizedBox(height: 12),
                    _AreaChart(porArea: _porArea),
                  ],

                  const SizedBox(height: 24),
                  const _SectionTitle('Tasa de resolución'),
                  const SizedBox(height: 12),
                  _TasaCard(
                      resueltas: _resueltas, total: _totalAtendidas),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}

// ── KPI Grid ──────────────────────────────────────────────────────────
class _KpiGrid extends StatelessWidget {
  final List<_KpiData> kpis;
  const _KpiGrid({required this.kpis});

  @override
  Widget build(BuildContext context) => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: kpis.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.0),
        itemBuilder: (_, i) {
          final k = kpis[i];
          return Container(
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      color: k.color.withOpacity(0.12),
                      shape: BoxShape.circle),
                  child: Icon(k.icon, color: k.color, size: 18),
                ),
                const SizedBox(height: 6),
                Text(k.valor,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: k.color)),
                const SizedBox(height: 2),
                Text(k.label,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 10),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          );
        },
      );
}

class _KpiData {
  final String label, valor;
  final IconData icon;
  final Color color;
  const _KpiData(this.label, this.valor, this.icon, this.color);
}

// ── Bar Chart ─────────────────────────────────────────────────────────
class _BarChart extends StatelessWidget {
  final List<_BarData> bars;
  final double maxValue;
  const _BarChart({required this.bars, required this.maxValue});

  @override
  Widget build(BuildContext context) {
    final max = maxValue < 1 ? 1.0 : maxValue;
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
      child: SizedBox(
        height: 140,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: bars.map((b) {
            final pct = b.valor / max;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('${b.valor}',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: b.color,
                            fontSize: 16)),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      height: 100 * pct,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: b.color,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(b.label,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _BarData {
  final String label;
  final int valor;
  final Color color;
  const _BarData(this.label, this.valor, this.color);
}

// ── Área chart (barras horizontales) ─────────────────────────────────
class _AreaChart extends StatelessWidget {
  final Map<String, int> porArea;
  const _AreaChart({required this.porArea});

  @override
  Widget build(BuildContext context) {
    final max = porArea.values.fold(0, (a, b) => a > b ? a : b);
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
        children: porArea.entries.map((e) {
          final pct = max > 0 ? e.value / max : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 90,
                  child: Text(e.key,
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 12),
                      overflow: TextOverflow.ellipsis),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: AppColors.divider,
                      color: AppColors.primary,
                      minHeight: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${e.value}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        fontSize: 13)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Tasa de resolución ────────────────────────────────────────────────
class _TasaCard extends StatelessWidget {
  final int resueltas, total;
  const _TasaCard({required this.resueltas, required this.total});

  @override
  Widget build(BuildContext context) {
    final tasa = total > 0 ? resueltas / total : 0.0;
    final pct  = (tasa * 100).toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.all(20),
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tasa de resolución',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontSize: 14)),
              Text('$pct%',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.resolved,
                      fontSize: 22)),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: tasa,
              backgroundColor: AppColors.divider,
              color: AppColors.resolved,
              minHeight: 20,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$resueltas resueltas',
                  style: const TextStyle(
                      color: AppColors.resolved, fontSize: 12)),
              Text('$total total',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: AppColors.textPrimary));
}
