import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/app_colors.dart';
import '../../config/routes.dart';
import '../../models/user_model.dart';

// ═══════════════════════════════════════════════════════════════════════
//  DASHBOARD BIOMÉDICO — Con BottomNavigationBar
// ═══════════════════════════════════════════════════════════════════════
class DashboardBiomedicoScreen extends StatefulWidget {
  const DashboardBiomedicoScreen({super.key});

  @override
  State<DashboardBiomedicoScreen> createState() =>
      _DashboardBiomedicoScreenState();
}

class _DashboardBiomedicoScreenState extends State<DashboardBiomedicoScreen> {
  int _tab = 0;
  UserModel? _usuario;
  int _pendientes  = 0;
  int _resueltas   = 0;
  int _totalEquipos = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final results = await Future.wait([
        FirebaseFirestore.instance.collection('usuarios').doc(uid).get(),
        FirebaseFirestore.instance
            .collection('incidencias')
            .where('tecnicoId', isEqualTo: uid)
            .where('estado', whereIn: ['Pendiente', 'Asignada', 'En Proceso'])
            .get(),
        FirebaseFirestore.instance
            .collection('incidencias')
            .where('tecnicoId', isEqualTo: uid)
            .where('estado', whereIn: ['Resuelta', 'Cerrada'])
            .get(),
        FirebaseFirestore.instance.collection('equipos').get(),
      ]);
      if (!mounted) return;
      setState(() {
        final userDoc = results[0] as DocumentSnapshot<Map<String, dynamic>>;
        if (userDoc.exists) _usuario = UserModel.fromFirestore(userDoc);
        _pendientes  = (results[1] as QuerySnapshot).docs.length;
        _resueltas   = (results[2] as QuerySnapshot).docs.length;
        _totalEquipos= (results[3] as QuerySnapshot).docs.length;
      });
    } catch (_) {}
  }

  // ── Bottom nav ──────────────────────────────────────────────────────
  void _onTabTap(int i) {
    if (i == 0) { setState(() => _tab = 0); return; }
    if (i == 1) { setState(() => _tab = 1); return; }
    if (i == 2) {
      Navigator.pushNamed(context, AppRoutes.bioNotificaciones);
      return;
    }
    if (i == 3) {
      Navigator.pushNamed(context, AppRoutes.bioPerfil);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombre   = _usuario?.nombre   ?? 'Biomédico';
    final cargo    = _usuario?.cargo    ?? 'Especialista Biomédico';
    final hospital = _usuario?.hospital ?? 'Q&Q Medical Ltda.';
    final inicial  = nombre.isNotEmpty ? nombre[0].toUpperCase() : 'B';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: _buildDrawer(context),
      body: IndexedStack(
        index: _tab,
        children: [
          // ── Tab 0: Inicio ──
          _InicioTab(
            usuario:      _usuario,
            nombre:       nombre,
            cargo:        cargo,
            hospital:     hospital,
            inicial:      inicial,
            pendientes:   _pendientes,
            resueltas:    _resueltas,
            totalEquipos: _totalEquipos,
            scaffoldKey:  _scaffoldKey,
            onRefresh:    _cargarDatos,
          ),
          // ── Tab 1: Equipos ──
          _EquiposTab(),
        ],
      ),
      // ── Bottom Navigation Bar ────────────────────────────────────────
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab > 1 ? 0 : _tab,
        onTap: _onTabTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor:   AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle:  const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle:const TextStyle(fontSize: 11),
        elevation: 12,
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(
            icon:       Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label:      'Inicio',
          ),
          BottomNavigationBarItem(
            icon:       Icon(Icons.medical_services_outlined),
            activeIcon: Icon(Icons.medical_services_rounded),
            label:      'Equipos',
          ),
          BottomNavigationBarItem(
            icon:       Icon(Icons.notifications_outlined),
            activeIcon: Icon(Icons.notifications_rounded),
            label:      'Notificaciones',
          ),
          BottomNavigationBarItem(
            icon:       Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label:      'Perfil',
          ),
        ],
      ),
      // ── FAB Chatbot ─────────────────────────────────────────────────
      floatingActionButton: _tab == 0
          ? FloatingActionButton.extended(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.bioChatbot),
              backgroundColor: AppColors.accent,
              elevation: 4,
              icon: const Icon(Icons.smart_toy_outlined,
                  color: Colors.white, size: 20),
              label: const Text('ChatBot',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  // ── Drawer ─────────────────────────────────────────────────────────
  Widget _buildDrawer(BuildContext context) {
    final nombre  = _usuario?.nombre ?? 'Biomédico';
    final cargo   = _usuario?.cargo  ?? 'Especialista';
    final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : 'B';

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight]),
            ),
            accountName: Text(nombre,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            accountEmail: Text(cargo),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.2),
              child: _usuario?.photoUrl.isNotEmpty == true
                  ? ClipOval(
                      child: Image.network(_usuario!.photoUrl, fit: BoxFit.cover))
                  : Text(inicial,
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
            ),
          ),
          _DItem(Icons.inbox_outlined,        'Solicitudes',       AppRoutes.bioSolicitudes,    context),
          _DItem(Icons.assignment_outlined,   'Mis Asignaciones',  AppRoutes.bioAsignaciones,   context),
          _DItem(Icons.history_outlined,      'Historial Equipos', AppRoutes.bioHistorial,      context),
          _DItem(Icons.build_outlined,        'Mantenimiento',     AppRoutes.bioMantenimiento,  context),
          _DItem(Icons.inventory_2_outlined,  'Inventario',        AppRoutes.bioInventario,     context),
          _DItem(Icons.bar_chart_rounded,     'Reportes',          AppRoutes.bioReportes,       context),
          _DItem(Icons.notifications_outlined,'Notificaciones',    AppRoutes.bioNotificaciones, context),
          _DItem(Icons.smart_toy_outlined,    'ChatBot Equipos',   AppRoutes.bioChatbot,        context),
          _DItem(Icons.chat_bubble_outline,   'Chat Enfermería',   AppRoutes.bioChat,           context),
          _DItem(Icons.person_outline,        'Mi Perfil',         AppRoutes.bioPerfil,         context),
          const Divider(),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                        context, AppRoutes.login, (_) => false);
                  }
                },
                icon: const Icon(Icons.logout, color: AppColors.error, size: 18),
                label: const Text('Cerrar sesión',
                    style: TextStyle(color: AppColors.error)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text('MedControl v1.0',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  TAB 0 — INICIO
// ═══════════════════════════════════════════════════════════════════════
class _InicioTab extends StatelessWidget {
  final UserModel? usuario;
  final String nombre, cargo, hospital, inicial;
  final int pendientes, resueltas, totalEquipos;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final Future<void> Function() onRefresh;

  const _InicioTab({
    required this.usuario,    required this.nombre,
    required this.cargo,      required this.hospital,
    required this.inicial,    required this.pendientes,
    required this.resueltas,  required this.totalEquipos,
    required this.scaffoldKey,required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) => RefreshIndicator(
        onRefresh: onRefresh,
        child: CustomScrollView(
          slivers: [
            // ── Header ─────────────────────────────────────────────
            SliverToBoxAdapter(child: _buildHeader(context)),

            // ── Acciones rápidas ────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Acciones rápidas',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 16),

                    // ── 4 tarjetas principales ─────────────────────
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 1.25,
                      children: [
                        _AccionCard(
                          icon:  Icons.assignment_outlined,
                          label: 'Mis Asignaciones',
                          color: AppColors.primary,
                          badge: pendientes > 0 ? '$pendientes' : null,
                          onTap: () => Navigator.pushNamed(
                              context, AppRoutes.bioAsignaciones),
                        ),
                        _AccionCard(
                          icon:  Icons.check_circle_outline,
                          label: 'Incidencias Atendidas',
                          color: AppColors.resolved,
                          badge: resueltas > 0 ? '$resueltas' : null,
                          onTap: () => Navigator.pushNamed(
                              context, AppRoutes.bioSolicitudes),
                        ),
                        _AccionCard(
                          icon:  Icons.history_outlined,
                          label: 'Historial de Equipos',
                          color: AppColors.accent,
                          onTap: () => Navigator.pushNamed(
                              context, AppRoutes.bioHistorial),
                        ),
                        _AccionCard(
                          icon:  Icons.bar_chart_rounded,
                          label: 'Reportes',
                          color: const Color(0xFF06B6D4),
                          onTap: () => Navigator.pushNamed(
                              context, AppRoutes.bioReportes),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── Accesos secundarios ────────────────────────
                    const Text('Más módulos',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 12),

                    _SecundarioTile(Icons.build_outlined,        'Registro de Mantenimiento', const Color(0xFFF59E0B), () => Navigator.pushNamed(context, AppRoutes.bioMantenimiento)),
                    const SizedBox(height: 8),
                    _SecundarioTile(Icons.inventory_2_outlined,  'Inventario de Repuestos',   const Color(0xFFEF4444), () => Navigator.pushNamed(context, AppRoutes.bioInventario)),
                    const SizedBox(height: 8),
                    _SecundarioTile(Icons.chat_bubble_outline,   'Chat con Enfermería',        AppColors.accent,       () => Navigator.pushNamed(context, AppRoutes.bioChat)),
                    const SizedBox(height: 8),
                    _SecundarioTile(Icons.inbox_outlined,        'Solicitudes recibidas',      const Color(0xFF3B82F6), () => Navigator.pushNamed(context, AppRoutes.bioSolicitudes)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildHeader(BuildContext context) => Container(
        padding: EdgeInsets.fromLTRB(
            20, MediaQuery.of(context).padding.top + 12, 20, 28),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryLight],
          ),
          borderRadius: BorderRadius.only(
            bottomLeft:  Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => scaffoldKey.currentState?.openDrawer(),
                  child: Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withOpacity(0.4), width: 2),
                    ),
                    child: usuario?.photoUrl.isNotEmpty == true
                        ? ClipOval(
                            child: Image.network(usuario!.photoUrl,
                                fit: BoxFit.cover))
                        : Center(
                            child: Text(inicial,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold)),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hola, $nombre',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('$cargo · $hospital',
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                if (pendientes > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$pendientes pendiente${pendientes > 1 ? 's' : ''}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _QuickStat('Asignadas',  '$pendientes',   Icons.assignment_outlined),
                const SizedBox(width: 10),
                _QuickStat('Resueltas',  '$resueltas',    Icons.check_circle_outline),
                const SizedBox(width: 10),
                _QuickStat('Equipos',    '$totalEquipos', Icons.medical_services_outlined),
              ],
            ),
          ],
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════
//  TAB 1 — EQUIPOS
// ═══════════════════════════════════════════════════════════════════════
class _EquiposTab extends StatefulWidget {
  @override
  State<_EquiposTab> createState() => _EquiposTabState();
}

class _EquiposTabState extends State<_EquiposTab> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Color _colorEstado(String e) {
    switch (e.toLowerCase()) {
      case 'operativo':         return AppColors.resolved;
      case 'en mantenimiento':  return AppColors.pending;
      case 'fuera de servicio': return AppColors.error;
      default:                  return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          // Header simple
          Container(
            padding: EdgeInsets.fromLTRB(
                16, MediaQuery.of(context).padding.top + 16, 16, 16),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                bottomLeft:  Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Equipos Médicos',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v.toLowerCase()),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Buscar equipo...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.15),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('equipos')
                  .orderBy('nombre')
                  .snapshots(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = (snap.data?.docs ?? []).where((d) {
                  final n = (d.data()['nombre'] ?? '').toString().toLowerCase();
                  final a = (d.data()['area']   ?? '').toString().toLowerCase();
                  return _query.isEmpty || n.contains(_query) || a.contains(_query);
                }).toList();

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.medical_services_outlined,
                            size: 72, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          _query.isEmpty
                              ? 'No hay equipos registrados'
                              : 'Sin resultados para "$_query"',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 15),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final d      = docs[i].data();
                    final nombre = d['nombre']  as String? ?? 'Equipo';
                    final area   = d['area']    as String? ?? '—';
                    final estado = d['estado']  as String? ?? 'Operativo';
                    final tipo   = d['tipo']    as String? ?? '';
                    final color  = _colorEstado(estado);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
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
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        leading: Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                              Icons.medical_services_outlined,
                              color: AppColors.primary, size: 22),
                        ),
                        title: Text(nombre,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.textPrimary)),
                        subtitle: Text(
                          '${tipo.isNotEmpty ? '$tipo · ' : ''}$area',
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(estado,
                              style: TextStyle(
                                  color: color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      );
}

// ═══════════════════════════════════════════════════════════════════════
//  WIDGETS COMPARTIDOS
// ═══════════════════════════════════════════════════════════════════════

class _AccionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String? badge;
  final VoidCallback onTap;
  const _AccionCard({
    required this.icon, required this.label,
    required this.color, required this.onTap, this.badge,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: color.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 46, height: 46,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    Text(label,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.textPrimary,
                            height: 1.3)),
                  ],
                ),
              ),
              if (badge != null)
                Positioned(
                  top: 10, right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(badge!,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ),
      );
}

class _SecundarioTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _SecundarioTile(this.icon, this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary)),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: AppColors.textSecondary),
            ],
          ),
        ),
      );
}

class _QuickStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _QuickStat(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white70, size: 18),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white60, fontSize: 10)),
            ],
          ),
        ),
      );
}

class _DItem extends StatelessWidget {
  final IconData icon;
  final String label, route;
  final BuildContext parentCtx;
  const _DItem(this.icon, this.label, this.route, this.parentCtx);

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: AppColors.primary, size: 22),
        title: Text(label,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(parentCtx, route);
        },
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      );
}
