import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/app_colors.dart';
import 'detalle_repuesto_screen.dart';

// ═══════════════════════════════════════════════════════════════════════
//  INVENTARIO DE REPUESTOS
// ═══════════════════════════════════════════════════════════════════════
class InventarioRepuestosScreen extends StatefulWidget {
  const InventarioRepuestosScreen({super.key});

  @override
  State<InventarioRepuestosScreen> createState() =>
      _InventarioRepuestosScreenState();
}

class _InventarioRepuestosScreenState
    extends State<InventarioRepuestosScreen> {
  final _searchCtrl = TextEditingController();
  String _query     = '';
  String _filtro    = 'Todos';

  static const _filtros = [
    'Todos', 'Disponible', 'Bajo stock', 'Agotado',
  ];

  // Demo data para cuando Firestore está vacío
  static const _demo = [
    {'id': 'REP001', 'codigo': 'REP-001', 'nombre': 'Cable ECG 10 derivaciones', 'categoria': 'Eléctrico',    'cantidad': 15, 'cantidadMinima': 5,  'ubicacion': 'Almacén A', 'estado': 'Disponible'},
    {'id': 'REP002', 'codigo': 'REP-002', 'nombre': 'Sensor SpO2 adulto',         'categoria': 'Sensores',    'cantidad': 8,  'cantidadMinima': 5,  'ubicacion': 'Almacén B', 'estado': 'Disponible'},
    {'id': 'REP003', 'codigo': 'REP-003', 'nombre': 'Batería Monitor 7.4V',       'categoria': 'Eléctrico',   'cantidad': 4,  'cantidadMinima': 5,  'ubicacion': 'Almacén A', 'estado': 'Bajo stock'},
    {'id': 'REP004', 'codigo': 'REP-004', 'nombre': 'Fuente de Alimentación 12V', 'categoria': 'Eléctrico',   'cantidad': 0,  'cantidadMinima': 2,  'ubicacion': 'Almacén C', 'estado': 'Agotado'},
    {'id': 'REP005', 'codigo': 'REP-005', 'nombre': 'Fusible 3A 250V',            'categoria': 'Eléctrico',   'cantidad': 40, 'cantidadMinima': 10, 'ubicacion': 'Almacén G', 'estado': 'Disponible'},
    {'id': 'REP006', 'codigo': 'REP-006', 'nombre': 'Manguito presión adulto',    'categoria': 'Accesorios',  'cantidad': 12, 'cantidadMinima': 5,  'ubicacion': 'Almacén B', 'estado': 'Disponible'},
    {'id': 'REP007', 'codigo': 'REP-007', 'nombre': 'Pantalla LCD 7"',            'categoria': 'Electrónico', 'cantidad': 2,  'cantidadMinima': 2,  'ubicacion': 'Almacén C', 'estado': 'Bajo stock'},
    {'id': 'REP008', 'codigo': 'REP-008', 'nombre': 'Electrodo adhesivo ECG',     'categoria': 'Accesorios',  'cantidad': 200,'cantidadMinima': 50, 'ubicacion': 'Almacén G', 'estado': 'Disponible'},
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Inventario de Repuestos',
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
                hintText: 'Buscar repuesto, código...',
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
                final f   = _filtros[i];
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
              stream: FirebaseFirestore.instance
                  .collection('repuestos')
                  .orderBy('nombre')
                  .snapshots(),
              builder: (ctx, snap) {
                final docs = snap.data?.docs ?? [];

                if (docs.isEmpty) {
                  // Usar demo data
                  var items = _demo.where((r) {
                    final matchQ = _query.isEmpty ||
                        (r['nombre'] as String).toLowerCase().contains(_query) ||
                        (r['codigo'] as String).toLowerCase().contains(_query);
                    final matchF = _filtro == 'Todos' || r['estado'] == _filtro;
                    return matchQ && matchF;
                  }).toList();

                  return _buildList(
                    items.map((d) {
                      final cant    = (d['cantidad'] as int);
                      final minCant = (d['cantidadMinima'] as int);
                      return RepuestoCardData(
                        id:        d['id'] as String,
                        codigo:    d['codigo'] as String,
                        nombre:    d['nombre'] as String,
                        categoria: d['categoria'] as String,
                        cantidad:  cant,
                        minima:    minCant,
                        ubicacion: d['ubicacion'] as String,
                        estado:    d['estado'] as String,
                        data:      Map<String, dynamic>.from(d),
                      );
                    }).toList(),
                    context,
                  );
                }

                // Datos reales de Firestore
                final items = docs.where((d) {
                  final data = d.data();
                  final matchQ = _query.isEmpty ||
                      (data['nombre'] ?? '').toString().toLowerCase().contains(_query) ||
                      (data['codigo'] ?? '').toString().toLowerCase().contains(_query);
                  final cant    = (data['cantidad'] ?? 0) as int;
                  final minCant = (data['cantidadMinima'] ?? 0) as int;
                  final estadoReal = cant <= 0 ? 'Agotado'
                      : cant <= minCant ? 'Bajo stock'
                      : 'Disponible';
                  final matchF = _filtro == 'Todos' || estadoReal == _filtro;
                  return matchQ && matchF;
                }).toList();

                return _buildList(
                  items.map((d) {
                    final data    = d.data();
                    final cant    = (data['cantidad'] ?? 0) as int;
                    final minCant = (data['cantidadMinima'] ?? 0) as int;
                    final estado  = cant <= 0 ? 'Agotado'
                        : cant <= minCant ? 'Bajo stock'
                        : 'Disponible';
                    return RepuestoCardData(
                      id:        d.id,
                      codigo:    data['codigo'] ?? '',
                      nombre:    data['nombre'] ?? '',
                      categoria: data['categoria'] ?? '',
                      cantidad:  cant,
                      minima:    minCant,
                      ubicacion: data['ubicacion'] ?? '',
                      estado:    estado,
                      data:      Map<String, dynamic>.from(data)..['id'] = d.id,
                    );
                  }).toList(),
                  context,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<RepuestoCardData> items, BuildContext ctx) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('No se encontraron repuestos',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 15)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: items.length,
      itemBuilder: (_, i) => _RepuestoCard(
        item:  items[i],
        onTap: () => Navigator.push(
          ctx,
          MaterialPageRoute(
              builder: (_) => DetalleRepuestoScreen(data: items[i].data)),
        ),
      ),
    );
  }
}

class RepuestoCardData {
  final String id, codigo, nombre, categoria, ubicacion, estado;
  final int cantidad, minima;
  final Map<String, dynamic> data;
  const RepuestoCardData({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.categoria,
    required this.cantidad,
    required this.minima,
    required this.ubicacion,
    required this.estado,
    required this.data,
  });
}

class _RepuestoCard extends StatelessWidget {
  final RepuestoCardData item;
  final VoidCallback onTap;
  const _RepuestoCard({required this.item, required this.onTap});

  Color get _color {
    switch (item.estado) {
      case 'Agotado':    return AppColors.error;
      case 'Bajo stock': return AppColors.pending;
      default:           return AppColors.resolved;
    }
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
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
            child: Row(
              children: [
                // Ícono con color de estado
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.build_outlined, color: _color, size: 22),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.nombre,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.textPrimary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Text('${item.codigo} · ${item.categoria}',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: 3),
                          Text(item.ubicacion,
                              style: const TextStyle(
                                  color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // Stock + estado
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${item.cantidad}',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: _color)),
                    const Text('unidades',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 10)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(item.estado,
                          style: TextStyle(
                              color: _color,
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}
