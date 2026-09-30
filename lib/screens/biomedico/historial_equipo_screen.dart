import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/app_colors.dart';

// ═══════════════════════════════════════════════════════════════════════
//  HISTORIAL DEL EQUIPO
// ═══════════════════════════════════════════════════════════════════════
class HistorialEquipoScreen extends StatelessWidget {
  final String equipoId;
  final String equipoNombre;
  final Map<String, dynamic>? equipoData;

  const HistorialEquipoScreen({
    super.key,
    required this.equipoId,
    this.equipoNombre = 'Equipo',
    this.equipoData,
  });

  static final _demoMants = [
    {
      'tipo': 'Correctivo',
      'fechaInicio': '10/06/2026 08:30',
      'fechaFin': '10/06/2026 11:45',
      'tecnicoNombre': 'Carlos Quispe',
      'diagnostico': 'Falla en fuente de alimentación. Capacitor quemado.',
      'accionesRealizadas': 'Reemplazo de capacitor y prueba de funcionamiento.',
      'estadoFinal': 'Operativo',
      'repuestosUsados': [
        {'nombre': 'Capacitor 470µF 25V', 'cantidad': 2},
      ],
      'fotosAntes': <String>[],
      'fotosDurante': <String>[],
      'fotosDespues': <String>[],
    },
    {
      'tipo': 'Preventivo',
      'fechaInicio': '15/03/2026 09:00',
      'fechaFin': '15/03/2026 10:30',
      'tecnicoNombre': 'Carlos Quispe',
      'diagnostico': 'Revisión programada trimestral. Sin anomalías.',
      'accionesRealizadas': 'Limpieza interna, calibración de sensores, firmware.',
      'estadoFinal': 'Operativo',
      'repuestosUsados': <Map<String, dynamic>>[],
      'fotosAntes': <String>[],
      'fotosDurante': <String>[],
      'fotosDespues': <String>[],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Historial del Equipo',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text(equipoNombre,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                overflow: TextOverflow.ellipsis),
          ],
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          if (equipoData != null) _EquipoInfoCard(data: equipoData!),
          Expanded(
            child: equipoId.isEmpty
                ? _buildDemoList()
                : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('mantenimientos')
                        .where('equipoId', isEqualTo: equipoId)
                        .orderBy('fechaCreacion', descending: true)
                        .snapshots(),
                    builder: (ctx, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final docs = snap.data?.docs ?? [];
                      if (docs.isEmpty) return _buildDemoList();
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: docs.length,
                        itemBuilder: (_, i) =>
                            _MantenimientoCard(data: docs[i].data()),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoList() => ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: _demoMants.length,
        itemBuilder: (_, i) => _MantenimientoCard(data: _demoMants[i]),
      );
}

// ── Info del equipo ───────────────────────────────────────────────────
class _EquipoInfoCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _EquipoInfoCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final area   = data['area']   ?? data['equipoArea'] ?? '—';
    final serie  = data['serie']  ?? '—';
    final marca  = data['marca']  ?? '—';
    final estado = data['estado'] ?? '—';

    Color estadoColor = AppColors.resolved;
    if (estado == 'En mantenimiento')   estadoColor = AppColors.pending;
    if (estado == 'Fuera de servicio')  estadoColor = AppColors.error;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.medical_services_outlined,
                color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$marca · S/N: $serie',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 3),
                Row(children: [
                  const Icon(Icons.location_on_outlined,
                      size: 12, color: AppColors.textSecondary),
                  const SizedBox(width: 3),
                  Text(area,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ]),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: estadoColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(estado,
                style: TextStyle(
                    color: estadoColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ── Tarjeta de mantenimiento ──────────────────────────────────────────
class _MantenimientoCard extends StatefulWidget {
  final Map<String, dynamic> data;
  const _MantenimientoCard({required this.data});

  @override
  State<_MantenimientoCard> createState() => _MantenimientoCardState();
}

class _MantenimientoCardState extends State<_MantenimientoCard> {
  bool _expandido = false;

  Color get _tipoColor => widget.data['tipo'] == 'Preventivo'
      ? AppColors.accent
      : AppColors.pending;

  @override
  Widget build(BuildContext context) {
    final d         = widget.data;
    final tipo      = d['tipo']              ?? 'Correctivo';
    final fechaIni  = d['fechaInicio']       ?? '—';
    final tecnico   = d['tecnicoNombre']     ?? '—';
    final estadoFin = d['estadoFinal']       ?? '—';
    final diagnostico = d['diagnostico']     ?? '';
    final acciones  = d['accionesRealizadas'] ?? '';
    final repuestos = (d['repuestosUsados'] as List<dynamic>?) ?? [];
    final fotosAntes   = (d['fotosAntes']   as List<dynamic>?) ?? [];
    final fotosDurante = (d['fotosDurante'] as List<dynamic>?) ?? [];
    final fotosDespues = (d['fotosDespues'] as List<dynamic>?) ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expandido = !_expandido),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _tipoColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(tipo,
                        style: TextStyle(
                            color: _tipoColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(fechaIni,
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600)),
                        Text('Técnico: $tecnico',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: estadoFin == 'Operativo'
                          ? AppColors.resolved.withOpacity(0.1)
                          : AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(estadoFin,
                        style: TextStyle(
                            color: estadoFin == 'Operativo'
                                ? AppColors.resolved
                                : AppColors.error,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _expandido ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          if (_expandido) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (diagnostico.isNotEmpty) ...[
                    const _SubTitulo('Diagnóstico'),
                    const SizedBox(height: 4),
                    Text(diagnostico,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            height: 1.4)),
                    const SizedBox(height: 12),
                  ],
                  if (acciones.isNotEmpty) ...[
                    const _SubTitulo('Acciones realizadas'),
                    const SizedBox(height: 4),
                    Text(acciones,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            height: 1.4)),
                    const SizedBox(height: 12),
                  ],
                  if (repuestos.isNotEmpty) ...[
                    const _SubTitulo('Repuestos utilizados'),
                    const SizedBox(height: 6),
                    ...repuestos.map((r) {
                      final rep = r as Map<String, dynamic>;
                      return Row(
                        children: [
                          const Icon(Icons.circle,
                              size: 6, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(rep['nombre'] ?? '',
                                style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13)),
                          ),
                          Text('x${rep['cantidad'] ?? 1}',
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12)),
                        ],
                      );
                    }),
                    const SizedBox(height: 12),
                  ],
                  if (fotosAntes.isNotEmpty)
                    _FotosRow(titulo: 'Antes', urls: fotosAntes),
                  if (fotosDurante.isNotEmpty)
                    _FotosRow(titulo: 'Durante', urls: fotosDurante),
                  if (fotosDespues.isNotEmpty)
                    _FotosRow(titulo: 'Después', urls: fotosDespues),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SubTitulo extends StatelessWidget {
  final String text;
  const _SubTitulo(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: AppColors.textSecondary));
}

class _FotosRow extends StatelessWidget {
  final String titulo;
  final List<dynamic> urls;
  const _FotosRow({required this.titulo, required this.urls});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SubTitulo('Fotos — $titulo'),
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: urls.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    urls[i] as String,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 80,
                      height: 80,
                      color: AppColors.divider,
                      child: const Icon(Icons.broken_image_outlined,
                          color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      );
}
