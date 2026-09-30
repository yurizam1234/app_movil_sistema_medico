import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../config/app_colors.dart';
import '../../widgets/status_chip.dart';
import 'detalle_orden_screen.dart';

// ═══════════════════════════════════════════════════════════════════════
//  MIS ASIGNACIONES — Diseño MD3 con tabs, indicadores y chatbot
// ═══════════════════════════════════════════════════════════════════════
class MisAsignacionesScreen extends StatefulWidget {
  const MisAsignacionesScreen({super.key});
  @override
  State<MisAsignacionesScreen> createState() => _MisAsignacionesScreenState();
}

class _MisAsignacionesScreenState extends State<MisAsignacionesScreen>
    with SingleTickerProviderStateMixin {

  late final TabController _tabCtrl;
  final _searchCtrl = TextEditingController();

  String _query      = '';
  bool   _showBanner = true;

  // Contadores para badges y panel
  int _cntActivas     = 0;
  int _cntEspera      = 0;
  int _cntCompletadas = 0;
  int _cntSinAsignar  = 0;
  int _cntDiagnostico = 0;
  int _cntRepuesto    = 0;
  int _cntRechazadas  = 0;
  int _notifCount     = 0;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  // Estados por tab
  static const _tabEstados = [
    ['Asignada', 'En Proceso', 'En diagnóstico', 'Esperando repuesto'],
    ['Pendiente'],
    ['Resuelta', 'Cerrada', 'Rechazada'],
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _cargarContadores();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Carga contadores desde Firestore ─────────────────────────────────
  Future<void> _cargarContadores() async {
    if (_uid.isEmpty) return;
    try {
      final mySnap = await FirebaseFirestore.instance
          .collection('incidencias')
          .where('tecnicoId', isEqualTo: _uid)
          .get();

      final globalSnap = await FirebaseFirestore.instance
          .collection('incidencias')
          .where('estado', isEqualTo: 'Pendiente')
          .get();

      int notifCount = 0;
      try {
        final nSnap = await FirebaseFirestore.instance
            .collection('notificaciones')
            .doc(_uid)
            .collection('items')
            .where('leido', isEqualTo: false)
            .get();
        notifCount = nSnap.docs.length;
      } catch (_) {}

      int activas = 0, espera = 0, completadas = 0;
      int diagnostico = 0, repuesto = 0, rechazadas = 0;

      for (final doc in mySnap.docs) {
        final estado = doc.data()['estado'] as String? ?? '';
        if (['Asignada', 'En Proceso', 'En diagnóstico', 'Esperando repuesto']
            .contains(estado)) {
          activas++;
          if (estado == 'En diagnóstico')    diagnostico++;
          if (estado == 'Esperando repuesto') repuesto++;
        } else if (estado == 'Pendiente') {
          espera++;
        } else if (['Resuelta', 'Cerrada'].contains(estado)) {
          completadas++;
        } else if (estado == 'Rechazada') {
          rechazadas++;
          completadas++;
        }
      }

      if (!mounted) return;
      setState(() {
        _cntActivas     = activas;
        _cntEspera      = espera;
        _cntCompletadas = completadas;
        _cntSinAsignar  = globalSnap.docs.length;
        _cntDiagnostico = diagnostico;
        _cntRepuesto    = repuesto;
        _cntRechazadas  = rechazadas;
        _notifCount     = notifCount;
      });
    } catch (_) {
      // Demo fallback para contadores
      if (mounted) setState(() {
        _cntActivas = 3; _cntEspera = 1; _cntCompletadas = 8;
        _cntSinAsignar = 2; _cntDiagnostico = 1;
        _cntRepuesto = 1; _cntRechazadas = 0; _notifCount = 2;
      });
    }
  }

  // ── BUILD ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),
      body: Column(
        children: [
          // 1. Header con gradiente
          _buildHeader(context),
          // 2. Tabs
          _buildTabBar(),
          // 3. Buscador + Filtros
          _buildSearchRow(),
          // 4. Panel de indicadores
          _buildIndicadores(),
          // 5. Lista (expande)
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: List.generate(3, _buildTabLista),
            ),
          ),
          // 6. Banner informativo
          if (_showBanner) _buildBanner(),
        ],
      ),
    );
  }

  // ── 1. HEADER ─────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) => Container(
        padding: EdgeInsets.fromLTRB(
            20, MediaQuery.of(context).padding.top + 14, 20, 18),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end:   Alignment.centerRight,
            colors: [Color(0xFF0D2D6C), Color(0xFF5C35C0)],
          ),
          borderRadius: BorderRadius.only(
            bottomLeft:  Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
        ),
        child: Row(
          children: [
            // Botón volver
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mis Asignaciones',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3)),
                  SizedBox(height: 2),
                  Text('Gestión de incidencias asignadas',
                      style: TextStyle(color: Colors.white60, fontSize: 12)),
                ],
              ),
            ),
            // Notificaciones con badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/biomedico/notificaciones'),
                  icon: const Icon(Icons.notifications_outlined,
                      color: Colors.white, size: 26),
                ),
                if (_notifCount > 0)
                  Positioned(
                    top: 6, right: 6,
                    child: Container(
                      width: 18, height: 18,
                      decoration: const BoxDecoration(
                          color: Color(0xFFEF4444), shape: BoxShape.circle),
                      child: Center(
                        child: Text(
                          _notifCount > 9 ? '9+' : '$_notifCount',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );

  // ── 2. TABS ───────────────────────────────────────────────────────
  Widget _buildTabBar() => Container(
        color: Colors.white,
        child: TabBar(
          controller: _tabCtrl,
          labelColor:         AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor:     AppColors.primary,
          indicatorWeight:    3,
          labelPadding: EdgeInsets.zero,
          tabs: [
            _TabLabel('Activas',     _cntActivas),
            _TabLabel('En espera',   _cntEspera),
            _TabLabel('Completadas', _cntCompletadas),
          ],
        ),
      );

  // ── 3. BUSCADOR ───────────────────────────────────────────────────
  Widget _buildSearchRow() => Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 46,
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v.toLowerCase()),
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Buscar por equipo, ubicación o ID...',
                    hintStyle: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.textSecondary, size: 20),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded,
                                color: AppColors.textSecondary, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            })
                        : null,
                    filled:    true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Botón Filtros
            GestureDetector(
              onTap: _showFiltros,
              child: Container(
                height: 46,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.filter_list_rounded,
                        color: AppColors.primary, size: 18),
                    SizedBox(width: 5),
                    Text('Filtros',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  // ── 4. PANEL INDICADORES ─────────────────────────────────────────
  Widget _buildIndicadores() => Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _IndCard(
                label:  'Sin asignar',
                count:  _cntSinAsignar,
                icon:   Icons.inbox_outlined,
                bg:     const Color(0xFFFFF8E6),
                color:  const Color(0xFFF59E0B),
              ),
              const SizedBox(width: 8),
              _IndCard(
                label:  'En diagnóstico',
                count:  _cntDiagnostico,
                icon:   Icons.build_outlined,
                bg:     const Color(0xFFEFF6FF),
                color:  const Color(0xFF3B82F6),
              ),
              const SizedBox(width: 8),
              _IndCard(
                label:  'Esp. repuesto',
                count:  _cntRepuesto,
                icon:   Icons.inventory_2_outlined,
                bg:     const Color(0xFFF5F0FF),
                color:  const Color(0xFF8B5CF6),
              ),
              const SizedBox(width: 8),
              _IndCard(
                label:  'Completadas',
                count:  _cntCompletadas,
                icon:   Icons.check_circle_outline,
                bg:     const Color(0xFFECFDF5),
                color:  const Color(0xFF10B981),
              ),
              const SizedBox(width: 8),
              _IndCard(
                label:  'Rechazadas',
                count:  _cntRechazadas,
                icon:   Icons.cancel_outlined,
                bg:     const Color(0xFFFEF2F2),
                color:  const Color(0xFFEF4444),
              ),
            ],
          ),
        ),
      );

  // ── 5. LISTA POR TAB ─────────────────────────────────────────────
  Widget _buildTabLista(int tabIdx) {
    final estados = _tabEstados[tabIdx];

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _uid.isEmpty
          ? const Stream.empty()
          : FirebaseFirestore.instance
              .collection('incidencias')
              .where('tecnicoId', isEqualTo: _uid)
              .where('estado', whereIn: estados)
              .limit(50)
              .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Ordenar client-side para evitar índices compuestos
        final raw = snap.data?.docs ?? [];
        final sorted = List.of(raw)
          ..sort((a, b) {
            final tsA = a.data()['fechaCreacion'] as Timestamp?;
            final tsB = b.data()['fechaCreacion'] as Timestamp?;
            if (tsA == null) return 1;
            if (tsB == null) return -1;
            return tsB.compareTo(tsA);
          });

        // Filtro búsqueda
        final filtered = _query.isEmpty
            ? sorted
            : sorted.where((d) {
                final data   = d.data();
                final equipo = (data['equipoNombre']         ?? '').toLowerCase();
                final area   = (data['equipoArea']           ?? '').toLowerCase();
                final hosp   = (data['equipo']?['hospital']  ?? '').toLowerCase();
                return equipo.contains(_query) ||
                    area.contains(_query) ||
                    hosp.contains(_query) ||
                    d.id.toLowerCase().contains(_query);
              }).toList();

        // Demo fallback si no hay datos
        final demos  = (tabIdx == 0 && filtered.isEmpty && _query.isEmpty)
            ? _demoItems
            : <_DemoItem>[];
        final usaDemo = demos.isNotEmpty;
        final total   = usaDemo ? demos.length : filtered.length;

        if (total == 0) return _EmptyState(tabIdx: tabIdx);

        return RefreshIndicator(
          onRefresh: () async { await _cargarContadores(); },
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
            itemCount: total + 1,
            itemBuilder: (_, i) {
              // Encabezado de conteo
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Text(
                        '${usaDemo ? "Vista previa — " : ""}$total ${total == 1 ? "asignación" : "asignaciones"}',
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                      if (usaDemo) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.pending.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Datos de ejemplo',
                              style: TextStyle(
                                  color: AppColors.pending,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                );
              }

              final idx = i - 1;
              if (usaDemo) {
                final demo = demos[idx];
                return _AsignacionCard(
                  id:    'DEMO-$idx',
                  data:  demo.data,
                  onTap: null,
                );
              }

              final doc  = filtered[idx];
              return _AsignacionCard(
                id:    doc.id,
                data:  doc.data(),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetalleOrdenScreen(
                        incidenciaId: doc.id, data: doc.data()),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ── 6. BANNER ─────────────────────────────────────────────────────
  Widget _buildBanner() => Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D2D6C), Color(0xFF5C35C0)],
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Colors.white70, size: 18),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Mantén tus asignaciones actualizadas para un mejor control y seguimiento.',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 18),
              onPressed: () => setState(() => _showBanner = false),
            ),
          ],
        ),
      );

  // ── Panel de filtros (BottomSheet) ─────────────────────────────────
  void _showFiltros() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 18),
            const Text('Filtros avanzados',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            const Text(
                'Próximamente: filtros por fecha, área, hospital y prioridad.',
                style:
                    TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Cerrar',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Demo items ─────────────────────────────────────────────────────
  static final _demoItems = [
    _DemoItem({
      'equipoNombre': 'Ventilador Mecánico VM-300',
      'equipoArea':   'UCI',
      'equipo':       {'hospital': 'Hospital Q&Q', 'id': 'VM-300'},
      'estado':       'En Proceso',
      'solicitadoPor': 'Enf. María García',
      'fechaCreacion': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 3))),
    }),
    _DemoItem({
      'equipoNombre':  'Monitor Multiparámetros XR-200',
      'equipoArea':    'Urgencias',
      'equipo':        {'hospital': 'Clínica del Norte', 'id': 'XR-200'},
      'estado':        'Asignada',
      'solicitadoPor': 'Enf. Ana Torres',
      'fechaCreacion': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 8))),
    }),
    _DemoItem({
      'equipoNombre':  'Bomba de Infusión BIF-012',
      'equipoArea':    'Neonatología',
      'equipo':        {'hospital': 'Hospital Q&Q', 'id': 'BIF-012'},
      'estado':        'Esperando repuesto',
      'solicitadoPor': 'Enf. Laura Ruiz',
      'fechaCreacion': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 1))),
    }),
  ];
}

// ── Datos de demo ────────────────────────────────────────────────────
class _DemoItem {
  final Map<String, dynamic> data;
  const _DemoItem(this.data);
}

// ═══════════════════════════════════════════════════════════════════════
//  WIDGETS DE UI
// ═══════════════════════════════════════════════════════════════════════

// ── Tab label con badge ─────────────────────────────────────────────
class _TabLabel extends StatelessWidget {
  final String text;
  final int count;
  const _TabLabel(this.text, this.count);

  @override
  Widget build(BuildContext context) => Tab(
        height: 46,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            if (count > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$count',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      );
}

// ── Tarjeta indicador ───────────────────────────────────────────────
class _IndCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color bg, color;
  const _IndCard({
    required this.label, required this.count,
    required this.icon,  required this.bg, required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: 96,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text('$count',
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 20)),
            const SizedBox(height: 3),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: color.withValues(alpha: 0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.w600),
                maxLines: 2),
          ],
        ),
      );
}

// ── Estado vacío ────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final int tabIdx;
  const _EmptyState({required this.tabIdx});

  @override
  Widget build(BuildContext context) {
    const msgs = [
      'No tienes asignaciones activas',
      'No tienes solicitudes en espera',
      'No tienes asignaciones completadas',
    ];
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined,
              size: 72, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          Text(msgs[tabIdx],
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          const Text('Actualiza para ver los cambios recientes',
              style:
                  TextStyle(color: AppColors.textLight, fontSize: 12)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  CARD DE ASIGNACIÓN
// ═══════════════════════════════════════════════════════════════════════
class _AsignacionCard extends StatelessWidget {
  final String id;
  final Map<String, dynamic> data;
  final VoidCallback? onTap;
  const _AsignacionCard({
    required this.id, required this.data, required this.onTap,
  });

  // ── Tipo de equipo → icono + color ─────────────────────────────────
  static ({IconData icon, Color color}) _tipo(String nombre) {
    final n = nombre.toLowerCase();
    if (n.contains('bomba') || n.contains('infusion') || n.contains('perfusion'))
      return (icon: Icons.water_drop_outlined,     color: const Color(0xFFF97316));
    if (n.contains('monitor') || n.contains('signos') || n.contains('multiparametro'))
      return (icon: Icons.monitor_heart_outlined,  color: const Color(0xFF8B5CF6));
    if (n.contains('ventilador') || n.contains('respirad'))
      return (icon: Icons.air_outlined,            color: const Color(0xFF10B981));
    if (n.contains('desfibrilador') || n.contains('dea'))
      return (icon: Icons.electric_bolt_outlined,  color: const Color(0xFFEF4444));
    if (n.contains('tomogr') || n.contains('rayos'))
      return (icon: Icons.biotech_outlined,        color: const Color(0xFF3B82F6));
    if (n.contains('ecografo') || n.contains('ultrasonido'))
      return (icon: Icons.hearing_outlined,        color: const Color(0xFF06B6D4));
    if (n.contains('oximetro') || n.contains('saturacion'))
      return (icon: Icons.bloodtype_outlined,      color: const Color(0xFFEC4899));
    if (n.contains('incubadora') || n.contains('neonato'))
      return (icon: Icons.child_care_outlined,     color: const Color(0xFFF59E0B));
    return   (icon: Icons.medical_services_outlined, color: AppColors.primary);
  }

  // ── Tiempo transcurrido ────────────────────────────────────────────
  static String _elapsed(Timestamp? ts) {
    if (ts == null) return '—';
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inMinutes < 60)  return 'Hace ${diff.inMinutes} min';
    if (diff.inHours   < 24)  return 'Hace ${diff.inHours}h';
    if (diff.inDays    == 1)  return 'Hace 1 día';
    if (diff.inDays    < 30)  return 'Hace ${diff.inDays} días';
    return 'Hace ${(diff.inDays / 30).floor()} mes${diff.inDays > 60 ? "es" : ""}';
  }

  @override
  Widget build(BuildContext context) {
    final equipo     = data['equipoNombre']          as String? ?? 'Equipo';
    final codigo     = data['equipo']?['id']         as String?
                    ?? data['equipoId']              as String? ?? '—';
    final area       = data['equipoArea']            as String?
                    ?? data['equipo']?['area']       as String? ?? '—';
    final hospital   = data['equipo']?['hospital']   as String? ?? '—';
    final estado     = data['estado']                as String? ?? 'Pendiente';
    final solicitado = data['solicitadoPor']         as String? ?? '—';
    final ts         = data['fechaCreacion']         as Timestamp?;
    final fecha      = ts != null
        ? '${ts.toDate().day.toString().padLeft(2, '0')}/'
          '${ts.toDate().month.toString().padLeft(2, '0')}/'
          '${ts.toDate().year}'
        : '—';
    final hora       = ts != null
        ? '${ts.toDate().hour.toString().padLeft(2, '0')}:'
          '${ts.toDate().minute.toString().padLeft(2, '0')}'
        : '—';
    final elapsed    = _elapsed(ts);
    final tipo       = _tipo(equipo);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cabecera ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ícono del tipo de equipo
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      color:  tipo.color.withValues(alpha: 0.1),
                      shape:  BoxShape.circle,
                    ),
                    child: Icon(tipo.icon, color: tipo.color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(equipo,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14.5,
                                color: AppColors.textPrimary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 3),
                        Row(children: [
                          const Icon(Icons.tag_rounded,
                              size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: 3),
                          Text(codigo,
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11)),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusChip(estado: estado, small: true),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Divider con tiempo ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Expanded(child: Divider(height: 1, color: Color(0xFFF0F0F0))),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(children: [
                      const Icon(Icons.access_time_rounded,
                          size: 11, color: AppColors.textSecondary),
                      const SizedBox(width: 3),
                      Text(elapsed,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 10)),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(child: Divider(height: 1, color: Color(0xFFF0F0F0))),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Datos en grid 2×3 ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: _DataRow(
                              Icons.location_on_outlined, 'Área', area)),
                      Expanded(
                          child: _DataRow(
                              Icons.local_hospital_outlined,
                              'Hospital', hospital)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                          child: _DataRow(
                              Icons.calendar_today_outlined, 'Fecha', fecha)),
                      Expanded(
                          child: _DataRow(
                              Icons.access_time_outlined, 'Hora', hora)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _DataRow(
                      Icons.person_outline_rounded, 'Solicitado por',
                      solicitado),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── Botón Ver detalle ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.visibility_outlined, size: 17),
                  label: const Text('Ver detalle completo',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: onTap != null
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Fila de dato ─────────────────────────────────────────────────────
class _DataRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _DataRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 10)),
                Text(value,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      );
}
