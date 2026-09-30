import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/app_colors.dart';
import '../../config/routes.dart';
import '../../models/user_model.dart';
import '../../widgets/status_chip.dart';
import 'perfil_screen.dart';

// ═══════════════════════════════════════════════════════════════════════
//  DASHBOARD PRINCIPAL — MÓDULO ENFERMERA
// ═══════════════════════════════════════════════════════════════════════
class DashboardEnfermeraScreen extends StatefulWidget {
  const DashboardEnfermeraScreen({super.key});

  @override
  State<DashboardEnfermeraScreen> createState() =>
      _DashboardEnfermeraScreenState();
}

class _DashboardEnfermeraScreenState extends State<DashboardEnfermeraScreen> {
  int _selectedIndex = 0;
  UserModel? _usuario;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _cargarUsuario();
  }

  Future<void> _cargarUsuario() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get();
      if (doc.exists && mounted) {
        setState(() => _usuario = UserModel.fromFirestore(doc));
      }
    } catch (_) {}
  }

  List<Widget> get _tabs => [
        _HomeTab(
          onGoToEquipos: () => setState(() => _selectedIndex = 1),
          usuario: _usuario,
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        const _EquiposTab(),
        const _NotificacionesTab(),
        const PerfilEnfermeraScreen(),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(context),
      body: IndexedStack(index: _selectedIndex, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withOpacity(0.12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppColors.primary),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.medical_services_outlined),
            selectedIcon:
                Icon(Icons.medical_services, color: AppColors.primary),
            label: 'Equipos',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications, color: AppColors.primary),
            label: 'Notificaciones',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppColors.primary),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  // ── Drawer ─────────────────────────────────────────────────────────
  Widget _buildDrawer(BuildContext context) {
    final nombre   = _usuario?.nombre   ?? 'Enfermera';
    final cargo    = _usuario?.cargo    ?? 'Enfermera';
    final hospital = _usuario?.hospital ?? 'Q&Q Medical Ltda.';

    return Drawer(
      child: Column(
        children: [
          // Header del drawer
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
            ),
            accountName: Text(
              nombre,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            accountEmail: Text(cargo),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.2),
              child: Text(
                nombre.isNotEmpty ? nombre[0].toUpperCase() : 'E',
                style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            otherAccountsPictures: [
              Tooltip(
                message: hospital,
                child: const CircleAvatar(
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.local_hospital_outlined,
                      color: Colors.white, size: 18),
                ),
              ),
            ],
          ),

          // Sección: Módulo Enfermera
          _DrawerSection('Módulo Enfermera'),
          _DrawerItem(Icons.home_outlined, 'Panel Principal', () {
            Navigator.pop(context);
            setState(() => _selectedIndex = 0);
          }),
          _DrawerItem(Icons.edit_note_outlined, 'Registrar Incidencia', () {
            Navigator.pop(context);
            Navigator.pushNamed(context, AppRoutes.enfRegistrar);
          }),
          _DrawerItem(Icons.assignment_outlined, 'Mis Solicitudes', () {
            Navigator.pop(context);
            Navigator.pushNamed(context, AppRoutes.enfSolicitudes);
          }),
          _DrawerItem(Icons.qr_code_scanner_outlined, 'Escanear Equipo', () {
            Navigator.pop(context);
            Navigator.pushNamed(context, AppRoutes.enfScan);
          }),
          _DrawerItem(Icons.smart_toy_outlined, 'ChatBot Asistente', () {
            Navigator.pop(context);
            Navigator.pushNamed(context, AppRoutes.enfChatbot);
          }),
          _DrawerItem(Icons.medical_services_outlined, 'Equipos', () {
            Navigator.pop(context);
            setState(() => _selectedIndex = 1);
          }),
          _DrawerItem(Icons.notifications_outlined, 'Notificaciones', () {
            Navigator.pop(context);
            setState(() => _selectedIndex = 2);
          }),

          const Divider(),

          // Sección: Cuenta
          _DrawerSection('Cuenta'),
          _DrawerItem(Icons.person_outline, 'Mi Perfil', () {
            Navigator.pop(context);
            setState(() => _selectedIndex = 3);
          }),

          const Spacer(),

          // Cerrar sesión
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
            child: Text(
              'MedControl v1.0',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerSection extends StatelessWidget {
  final String title;
  const _DrawerSection(this.title);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
              letterSpacing: 1),
        ),
      );
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _DrawerItem(this.icon, this.label, this.onTap);

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: AppColors.primary, size: 22),
        title: Text(label,
            style: const TextStyle(
                fontSize: 14, color: AppColors.textPrimary)),
        onTap: onTap,
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      );
}

// ═══════════════════════════════════════════════════════════════════════
//  TAB 0 — INICIO
// ═══════════════════════════════════════════════════════════════════════
class _HomeTab extends StatelessWidget {
  final VoidCallback onGoToEquipos;
  final VoidCallback onMenuTap;
  final UserModel? usuario;

  const _HomeTab({
    required this.onGoToEquipos,
    required this.onMenuTap,
    this.usuario,
  });

  static const _actions = [
    {
      'icon': Icons.edit_note,
      'label': 'Registrar\nIncidencia',
      'color': 0xFFF59E0B,
      'route': AppRoutes.enfRegistrar,
    },
    {
      'icon': Icons.assignment_outlined,
      'label': 'Mis\nSolicitudes',
      'color': 0xFF3B82F6,
      'route': AppRoutes.enfSolicitudes,
    },
    {
      'icon': Icons.qr_code_scanner,
      'label': 'Escanear\nEquipo',
      'color': 0xFF8B5CF6,
      'route': AppRoutes.enfScan,
    },
    {
      'icon': Icons.bar_chart_rounded,
      'label': 'Reportes',
      'color': 0xFF10B981,
      'route': null,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final nombre = usuario?.nombre ?? FirebaseAuth.instance.currentUser?.displayName ?? 'Enfermera';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context, nombre)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Acceso rápido'),
                  const SizedBox(height: 14),
                  _buildGrid(context),
                  const SizedBox(height: 24),
                  _buildChatBotBanner(context),
                  const SizedBox(height: 24),
                  _sectionTitle('Mis estadísticas'),
                  const SizedBox(height: 14),
                  _buildStats(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header con gradiente ────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, String nombre) {
    final cargo    = usuario?.cargo    ?? 'Enfermera';
    final hospital = usuario?.hospital ?? 'Q&Q Medical Ltda.';
    final inicial  = nombre.isNotEmpty ? nombre[0].toUpperCase() : 'E';

    return Container(
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 12, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        children: [
          // Botón de menú (hamburguesa → Drawer)
          GestureDetector(
            onTap: onMenuTap,
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.4)),
              ),
              child: usuario?.photoUrl.isNotEmpty == true
                  ? ClipOval(
                      child: Image.network(usuario!.photoUrl,
                          fit: BoxFit.cover))
                  : Center(
                      child: Text(
                        inicial,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hola, $nombre',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$cargo · $hospital',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: Colors.white, size: 26),
                onPressed: () {},
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Grid de acciones rápidas ────────────────────────────────────────
  Widget _buildGrid(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.35,
      ),
      itemCount: _actions.length,
      itemBuilder: (context, i) {
        final a = _actions[i];
        final color = Color(a['color'] as int);
        return _ActionCard(
          icon: a['icon'] as IconData,
          label: a['label'] as String,
          color: color,
          onTap: () {
            final route = a['route'] as String?;
            if (route != null) {
              Navigator.pushNamed(context, route);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      '${(a['label'] as String).replaceAll('\n', ' ')} — próximamente disponible'),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              );
            }
          },
        );
      },
    );
  }

  // ── Banner ChatBot ──────────────────────────────────────────────────
  Widget _buildChatBotBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.enfChatbot),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.accent, AppColors.accentDark],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_outlined,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ChatBot Asistente',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 17)),
                  SizedBox(height: 4),
                  Text(
                    'Hola 👋 Soy tu asistente virtual MedControl. ¿En qué puedo ayudarte?',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle),
              child: const Icon(Icons.arrow_forward_ios,
                  color: Colors.white, size: 15),
            ),
          ],
        ),
      ),
    );
  }

  // ── Estadísticas ────────────────────────────────────────────────────
  Widget _buildStats() {
    return Row(
      children: const [
        Expanded(child: _StatTile('2', 'Pendientes', AppColors.pending)),
        SizedBox(width: 10),
        Expanded(child: _StatTile('4', 'En Proceso', AppColors.inProcess)),
        SizedBox(width: 10),
        Expanded(child: _StatTile('12', 'Resueltas', AppColors.resolved)),
      ],
    );
  }

  Widget _sectionTitle(String t) => Text(
        t,
        style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary),
      );
}

// ─── Tarjeta de acción rápida ─────────────────────────────────────────
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tile de estadística ──────────────────────────────────────────────
class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatTile(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 28,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  TAB 1 — EQUIPOS
// ═══════════════════════════════════════════════════════════════════════
class _EquiposTab extends StatefulWidget {
  const _EquiposTab();

  @override
  State<_EquiposTab> createState() => _EquiposTabState();
}

class _EquiposTabState extends State<_EquiposTab> {
  final _search = TextEditingController();
  String _query = '';

  // Demo data — TODO: conectar con Firestore colección 'equipos'
  static const _data = [
    {
      'nombre': 'Ventilador Mecánico Drager Evita 4',
      'area': 'UCI',
      'estado': 'Activo'
    },
    {
      'nombre': 'Monitor Multiparamétrico Mindray MEC-1200',
      'area': 'Urgencias',
      'estado': 'En mantenimiento'
    },
    {
      'nombre': 'Electrocardiógrafo EDAN SE-1201',
      'area': 'Cardiología',
      'estado': 'Activo'
    },
    {
      'nombre': 'Bomba de Infusión Baxter AS50',
      'area': 'Pediatría',
      'estado': 'Activo'
    },
    {
      'nombre': 'Desfibrilador Zoll M Series',
      'area': 'UCI',
      'estado': 'Fuera de servicio'
    },
    {
      'nombre': 'Oxímetro de Pulso Nellcor PM10N',
      'area': 'Urgencias',
      'estado': 'Activo'
    },
    {
      'nombre': 'Incubadora Drager Air-Shields',
      'area': 'Neonatología',
      'estado': 'Activo'
    },
    {
      'nombre': 'Respirador Maquet Servo-i',
      'area': 'UCI Pediátrica',
      'estado': 'En mantenimiento'
    },
  ];

  List<Map<String, String>> get _filtered {
    if (_query.isEmpty) return List<Map<String, String>>.from(_data);
    return _data
        .where((e) =>
            e['nombre']!.toLowerCase().contains(_query.toLowerCase()) ||
            e['area']!.toLowerCase().contains(_query.toLowerCase()))
        .map((e) => Map<String, String>.from(e))
        .toList();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Equipos Médicos'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Buscar equipo o área...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _search.clear();
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
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final e = items[i];
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
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.medical_services,
                            color: AppColors.primary),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e['nombre']!,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14)),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined,
                                    size: 12,
                                    color: AppColors.textSecondary),
                                const SizedBox(width: 3),
                                Text(e['area']!,
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      StatusChip(estado: e['estado']!, small: true),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  TAB 2 — NOTIFICACIONES
// ═══════════════════════════════════════════════════════════════════════
class _NotificacionesTab extends StatelessWidget {
  const _NotificacionesTab();

  static const _notifs = [
    {
      'titulo': 'Nueva incidencia registrada',
      'desc': 'Ventilador UCI-01 presenta alarmas intermitentes',
      'tiempo': 'hace 5 min',
      'icon': Icons.warning_amber_rounded,
      'color': 0xFFF59E0B,
      'leida': false,
    },
    {
      'titulo': 'Solicitud actualizada',
      'desc': 'Tu solicitud INC-001 cambió a "En Proceso"',
      'tiempo': 'hace 1 hora',
      'icon': Icons.update_rounded,
      'color': 0xFF8B5CF6,
      'leida': false,
    },
    {
      'titulo': 'Mantenimiento programado',
      'desc': 'Monitor de Urgencias recibirá mantenimiento mañana a las 08:00',
      'tiempo': 'hace 3 horas',
      'icon': Icons.build_circle_outlined,
      'color': 0xFF3B82F6,
      'leida': true,
    },
    {
      'titulo': 'Equipo reparado',
      'desc': 'Desfibrilador Zoll M Series ya está operativo',
      'tiempo': 'ayer, 14:30',
      'icon': Icons.check_circle_outline,
      'color': 0xFF10B981,
      'leida': true,
    },
    {
      'titulo': 'Recordatorio pendiente',
      'desc': 'Tienes 2 solicitudes sin revisión desde hace 3 días',
      'tiempo': 'ayer, 09:00',
      'icon': Icons.notifications_active_outlined,
      'color': 0xFFEF4444,
      'leida': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notificaciones'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Marcar leídas',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _notifs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final n = _notifs[i];
          final color = Color(n['color'] as int);
          final leida = n['leida'] as bool;

          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: leida ? Colors.white : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
              border: leida
                  ? null
                  : Border.all(
                      color: AppColors.primary.withOpacity(0.15)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      shape: BoxShape.circle),
                  child: Icon(n['icon'] as IconData, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(n['titulo'] as String,
                                style: TextStyle(
                                    fontWeight: leida
                                        ? FontWeight.w600
                                        : FontWeight.bold,
                                    fontSize: 14)),
                          ),
                          if (!leida)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(n['desc'] as String,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)),
                      const SizedBox(height: 6),
                      Text(n['tiempo'] as String,
                          style: const TextStyle(
                              color: AppColors.textLight, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
