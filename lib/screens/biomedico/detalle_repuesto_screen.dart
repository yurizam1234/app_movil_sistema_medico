import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/app_colors.dart';

// ═══════════════════════════════════════════════════════════════════════
//  DETALLE DE REPUESTO
// ═══════════════════════════════════════════════════════════════════════
class DetalleRepuestoScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const DetalleRepuestoScreen({super.key, required this.data});

  String get _estadoReal {
    final c  = (data['cantidad'] ?? 0) as int;
    final cm = (data['cantidadMinima'] ?? 0) as int;
    if (c <= 0)  return 'Agotado';
    if (c <= cm) return 'Bajo stock';
    return 'Disponible';
  }

  Color get _colorEstado {
    switch (_estadoReal) {
      case 'Agotado':    return AppColors.error;
      case 'Bajo stock': return AppColors.pending;
      default:           return AppColors.resolved;
    }
  }

  @override
  Widget build(BuildContext context) {
    final id        = data['id'] as String? ?? '';
    final codigo    = data['codigo']          ?? '—';
    final nombre    = data['nombre']          ?? 'Repuesto';
    final categoria = data['categoria']       ?? '—';
    final cantidad  = (data['cantidad'] ?? 0) as int;
    final minima    = (data['cantidadMinima'] ?? 0) as int;
    final ubicacion = data['ubicacion']       ?? '—';
    final marca     = data['marca']           ?? '—';
    final modelo    = data['modeloCompatible'] ?? '—';
    final proveedor = data['proveedor']       ?? '—';
    final precio    = data['precio'];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── SliverAppBar ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, Color(0xFF1A4F9E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
                    child: Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.build_rounded,
                              color: Colors.white, size: 30),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(nombre,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                  maxLines: 2),
                              const SizedBox(height: 4),
                              Text(codigo,
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Stock card ────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StockItem(
                          label: 'En stock',
                          valor: '$cantidad',
                          color: _colorEstado),
                      Container(
                          width: 1, height: 50, color: AppColors.divider),
                      _StockItem(
                          label: 'Stock mínimo',
                          valor: '$minima',
                          color: AppColors.textSecondary),
                      Container(
                          width: 1, height: 50, color: AppColors.divider),
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _colorEstado.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(_estadoReal,
                                style: TextStyle(
                                    color: _colorEstado,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                          ),
                          const SizedBox(height: 4),
                          const Text('Estado',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Información ───────────────────────────────────────
                _Seccion(
                  titulo: 'Información del repuesto',
                  items: [
                    _InfoFila('Categoría', categoria),
                    _InfoFila('Marca', marca),
                    _InfoFila('Modelo compatible', modelo),
                    _InfoFila('Ubicación', ubicacion),
                    if (precio != null)
                      _InfoFila('Precio unitario',
                          '\$${precio.toStringAsFixed(2)}'),
                    _InfoFila('Proveedor', proveedor),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Historial de uso ──────────────────────────────────
                if (id.isNotEmpty) ...[
                  _HistorialUsoSection(repuestoId: id),
                  const SizedBox(height: 24),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stock Item ────────────────────────────────────────────────────────
class _StockItem extends StatelessWidget {
  final String label, valor;
  final Color color;
  const _StockItem(
      {required this.label, required this.valor, required this.color});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(valor,
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11)),
        ],
      );
}

// ── Sección ───────────────────────────────────────────────────────────
class _Seccion extends StatelessWidget {
  final String titulo;
  final List<_InfoFila> items;
  const _Seccion({required this.titulo, required this.items});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 10),
            ...items,
          ],
        ),
      );
}

// ── Info Fila ─────────────────────────────────────────────────────────
class _InfoFila extends StatelessWidget {
  final String label, value;
  const _InfoFila(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 140,
              child: Text(label,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
}

// ── Historial de uso ──────────────────────────────────────────────────
class _HistorialUsoSection extends StatelessWidget {
  final String repuestoId;
  const _HistorialUsoSection({required this.repuestoId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('repuestos')
          .doc(repuestoId)
          .get(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const SizedBox.shrink();

        final movimientos =
            (snap.data?.data()?['movimientos'] as List<dynamic>?) ?? [];

        if (movimientos.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(16),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Historial de uso',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),
              ...movimientos.reversed.take(10).map((m) {
                final mov  = m as Map<String, dynamic>;
                final cant = (mov['cantidad'] ?? 0) as int;
                final ts   = mov['fecha'] as Timestamp?;
                final fecha = ts != null
                    ? '${ts.toDate().day.toString().padLeft(2, '0')}/${ts.toDate().month.toString().padLeft(2, '0')}/${ts.toDate().year}'
                    : '—';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.remove,
                            size: 16, color: AppColors.error),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(mov['descripcion'] ?? 'Uso en mantenimiento',
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textPrimary)),
                            Text(fecha,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      Text('-$cant ud.',
                          style: const TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
