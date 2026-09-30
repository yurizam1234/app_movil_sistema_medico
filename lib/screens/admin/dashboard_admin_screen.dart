import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/app_colors.dart';
import '../../config/routes.dart';
import '../../models/user_model.dart';

// ═══════════════════════════════════════════════════════════════════════
//  DASHBOARD ADMINISTRADOR — MEDCONTROL
// ═══════════════════════════════════════════════════════════════════════
class DashboardAdminScreen extends StatefulWidget {
  const DashboardAdminScreen({super.key});

  @override
  State<DashboardAdminScreen> createState() => _DashboardAdminScreenState();
}

class _DashboardAdminScreenState extends State<DashboardAdminScreen> {
  UserModel? _usuario;
  bool _cargando = true;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  // Stats
  int _totalEquipos       = 0;
  int _totalIncidencias   = 0;
  int _pendientes         = 0;
  int _enProceso          = 0;
  int _resueltas          = 0;
  int _fueraServicio      = 0;
  int _biomedicosActivos  = 0;
  int _hospitalesTotal    = 0;

  // Para gráficos
  final Map<String, int> _estadosIncidencia = {};
  final List<_MesData> _incidenciasPorMes   = [];
  final List<Map<String, dynamic>> _actividad = [];
  final List<Map<String, dynamic>> _alertas   = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) { setState(() => _cargando = false); return; }

    try {
      // Cargar usuario + colecciones en paralelo
      final results = await Future.wait([
        FirebaseFirestore.instance.collection('usuarios').doc(uid).get(),
        FirebaseFirestore.instance.collection('equipos').get(),
        FirebaseFirestore.instance.collection('incidencias').get(),
        FirebaseFirestore.instance
            .collection('usuarios')
            .where('rol', isEqualTo: 'biomedico')
            .where('estado', isEqualTo: 'activo')
            .get(),
        FirebaseFirestore.instance.collection('hospitales').get(),
        FirebaseFirestore.instance
            .collection('incidencias')
            .orderBy('fechaCreacion', descending: true)
            .limit(5)
            .get(),
      ]);

      final userDoc    = results[0] as DocumentSnapshot<Map<String, dynamic>>;
      final equiposSnap= results[1] as QuerySnapshot<Map<String, dynamic>>;
      final incSnap    = results[2] as QuerySnapshot<Map<String, dynamic>>;
      final bioSnap    = results[3] as QuerySnapshot<Map<String, dynamic>>;
      final hospSnap   = results[4] as QuerySnapshot<Map<String, dynamic>>;
      final recSnap    = results[5] as QuerySnapshot<Map<String, dynamic>>;

      // Conteo de estados de incidencias
      int pend = 0, proc = 0, res = 0;
      final Map<String, int> estadosMap = {
        'Pendiente': 0, 'Asignada': 0, 'En Proceso': 0,
        'Resuelta': 0, 'Cerrada': 0,
      };
      for (final d in incSnap.docs) {
        final e = d.data()['estado'] as String? ?? 'Pendiente';
        if (e == 'Pendiente' || e == 'Asignada') pend++;
        if (e == 'En Proceso') proc++;
        if (e == 'Resuelta' || e == 'Cerrada')   res++;
        estadosMap[e] = (estadosMap[e] ?? 0) + 1;
      }

      // Fuera de servicio
      int fueraServ = 0;
      for (final d in equiposSnap.docs) {
        if ((d.data()['estado'] as String? ?? '') == 'Fuera de servicio') {
          fueraServ++;
        }
      }

      // Incidencias por mes (últimos 6 meses)
      final now    = DateTime.now();
      final meses  = List.generate(6, (i) {
        final m = DateTime(now.year, now.month - (5 - i));
        return _MesData(mes: _mesCorto(m.month), year: m.year, month: m.month, count: 0);
      });
      for (final d in incSnap.docs) {
        final ts = d.data()['fechaCreacion'] as Timestamp?;
        if (ts == null) continue;
        final fecha = ts.toDate();
        for (final m in meses) {
          if (m.month == fecha.month && m.year == fecha.year) {
            m.count++;
          }
        }
      }

      // Actividad reciente
      final activ = recSnap.docs.map((d) {
        final data   = d.data();
        final equipo = data['equipoNombre'] ?? 'equipo';
        final tipo   = data['tipo'] ?? 'incidencia';
        final enf    = data['enfermeraNombre'] ?? 'Enfermera';
        return {
          'texto': '$enf registró incidencia en $equipo',
          'tipo': tipo,
          'ts': data['fechaCreacion'],
        };
      }).toList();

      // Alertas: equipos fuera de servicio + repuestos bajo stock
      final alertasList = <Map<String, dynamic>>[];
      for (final d in equiposSnap.docs) {
        if ((d.data()['estado'] as String? ?? '') == 'Fuera de servicio') {
          alertasList.add({
            'tipo': 'error',
            'titulo': 'Equipo fuera de servicio',
            'msg': d.data()['nombre'] ?? 'Equipo',
          });
          if (alertasList.length >= 3) break;
        }
      }
      // Bajo stock
      final repSnap = await FirebaseFirestore.instance
          .collection('repuestos')
          .get();
      for (final d in repSnap.docs) {
        final data = d.data();
        final cant    = (data['cantidad']       ?? 0) as int;
        final minCant = (data['cantidadMinima'] ?? 0) as int;
        if (cant <= minCant) {
          alertasList.add({
            'tipo': 'warning',
            'titulo': 'Bajo stock',
            'msg': data['nombre'] ?? 'Repuesto',
          });
          if (alertasList.length >= 5) break;
        }
      }

      if (mounted) {
        setState(() {
          _usuario          = userDoc.exists ? UserModel.fromFirestore(userDoc) : null;
          _totalEquipos     = equiposSnap.docs.length;
          _totalIncidencias = incSnap.docs.length;
          _pendientes       = pend;
          _enProceso        = proc;
          _resueltas        = res;
          _fueraServicio    = fueraServ;
          _biomedicosActivos= bioSnap.docs.length;
          _hospitalesTotal  = hospSnap.docs.length;
          _estadosIncidencia.clear();
          _estadosIncidencia.addAll(estadosMap);
          _incidenciasPorMes..clear()..addAll(meses);
          _actividad..clear()..addAll(activ);
          _alertas..clear()..addAll(alertasList);
          _cargando = false;
        });
      }
    } catch (_) {
      // Demo data
      if (mounted) {
        setState(() {
          _totalEquipos     = 142;
          _totalIncidencias = 89;
          _pendientes       = 12;
          _enProceso        = 7;
          _resueltas        = 70;
          _fueraServicio    = 5;
          _biomedicosActivos= 8;
          _hospitalesTotal  = 3;
          _estadosIncidencia.addAll({
            'Pendiente': 12, 'Asignada': 5, 'En Proceso': 7,
            'Resuelta': 55, 'Cerrada': 10,
          });
          _incidenciasPorMes.addAll([
            _MesData(mes: 'Ene', year: 2026, month: 1, count: 9),
            _MesData(mes: 'Feb', year: 2026, month: 2, count: 14),
            _MesData(mes: 'Mar', year: 2026, month: 3, count: 11),
            _MesData(mes: 'Abr', year: 2026, month: 4, count: 18),
            _MesData(mes: 'May', year: 2026, month: 5, count: 22),
            _MesData(mes: 'Jun', year: 2026, month: 6, count: 15),
          ]);
          _actividad.addAll([
            {'texto': 'María García registró incidencia en Monitor Cardíaco', 'tipo': 'incidencia'},
            {'texto': 'Carlos Quispe inició mantenimiento en Ventilador VM-200', 'tipo': 'mantenimiento'},
            {'texto': 'Pedro Ramos finalizó mantenimiento en Desfibrilador', 'tipo': 'completado'},
            {'texto': 'Admin creó nuevo hospital: Clínica del Norte', 'tipo': 'sistema'},
            {'texto': 'Ana Torres registró incidencia en Bomba de Infusión', 'tipo': 'incidencia'},
          ]);
          _alertas.addAll([
            {'tipo': 'error',   'titulo': 'Equipo fuera de servicio', 'msg': 'Ventilador VM-300 — UCI'},
            {'tipo': 'warning', 'titulo': 'Bajo stock',               'msg': 'Batería Monitor 7.4V (4 ud.)'},
            {'tipo': 'error',   'titulo': 'Equipo fuera de servicio', 'msg': 'Desfibrilador DEF-003 — Urgencias'},
            {'tipo': 'warning', 'titulo': 'Mantenimiento vencido',    'msg': 'Bomba Infusión BIF-012'},
          ]);
          _cargando = false;
        });
      }
    }
  }

  String _mesCorto(int m) {
    const nombres = ['', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
                     'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return nombres[m];
  }

  @override
  Widget build(BuildContext context) {
    final nombre   = _usuario?.nombre   ?? 'Administrador';
    final cargo    = _usuario?.cargo    ?? 'Administrador';
    final hospital = _usuario?.hospital ?? 'Q&Q Medical Ltda.';
    final inicial  = nombre.isNotEmpty ? nombre[0].toUpperCase() : 'A';
    final now      = DateTime.now();
    final fecha    = '${_diasSemana[now.weekday - 1]}, ${now.day} de ${_meses[now.month - 1]} ${now.year}';
    final hora     = now.hour < 12 ? 'Buenos días' : now.hour < 18 ? 'Buenas tardes' : 'Buenas noches';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: _buildDrawer(context, nombre, cargo, inicial),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                setState(() => _cargando = true);
                await _cargarDatos();
              },
              child: CustomScrollView(
                slivers: [
                  // ── Header ──────────────────────────────────────
                  SliverToBoxAdapter(
                    child: _buildHeader(context, nombre, cargo, hospital,
                        inicial, fecha, hora),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // ── Stats 8 cards ──────────────────────────
                        _sectionTitle('Indicadores generales'),
                        const SizedBox(height: 12),
                        _StatsGrid(stats: [
                          _StatData('Total equipos',   '$_totalEquipos',     Icons.medical_services_outlined, AppColors.primary),
                          _StatData('Incidencias',     '$_totalIncidencias', Icons.report_outlined,           AppColors.pending),
                          _StatData('Pendientes',      '$_pendientes',       Icons.hourglass_empty,           AppColors.error),
                          _StatData('En proceso',      '$_enProceso',        Icons.autorenew_rounded,         const Color(0xFF8B5CF6)),
                          _StatData('Resueltas',       '$_resueltas',        Icons.check_circle_outline,      AppColors.resolved),
                          _StatData('Fuera servicio',  '$_fueraServicio',    Icons.warning_amber_outlined,    const Color(0xFFF97316)),
                          _StatData('Biomédicos',      '$_biomedicosActivos',Icons.person_outline,            AppColors.accent),
                          _StatData('Hospitales',      '$_hospitalesTotal',  Icons.local_hospital_outlined,   const Color(0xFF06B6D4)),
                        ]),

                        const SizedBox(height: 28),

                        // ── Gráfico de barras ──────────────────────
                        _sectionTitle('Incidencias por mes'),
                        const SizedBox(height: 12),
                        _BarChartSection(datos: _incidenciasPorMes),

                        const SizedBox(height: 28),

                        // ── Gráfico circular ───────────────────────
                        _sectionTitle('Estado de incidencias'),
                        const SizedBox(height: 12),
                        _PieChartSection(
                          estadosMap: _estadosIncidencia,
                          total: _totalIncidencias,
                        ),

                        const SizedBox(height: 28),

                        // ── Alertas ────────────────────────────────
                        if (_alertas.isNotEmpty) ...[
                          _sectionTitle('Alertas'),
                          const SizedBox(height: 12),
                          ..._alertas.map((a) => _AlertaTile(alerta: a)),
                          const SizedBox(height: 28),
                        ],

                        // ── Actividad reciente ─────────────────────
                        if (_actividad.isNotEmpty) ...[
                          _sectionTitle('Actividad reciente'),
                          const SizedBox(height: 12),
                          _ActividadCard(items: _actividad),
                        ],
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary));

  // ── Header ────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext ctx, String nombre, String cargo,
      String hospital, String inicial, String fecha, String hora) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(ctx).padding.top + 12, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D2D6C), Color(0xFF1565C0)],
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
                onTap: () => _scaffoldKey.currentState?.openDrawer(),
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withOpacity(0.4), width: 2),
                  ),
                  child: _usuario?.photoUrl.isNotEmpty == true
                      ? ClipOval(
                          child: Image.network(_usuario!.photoUrl,
                              fit: BoxFit.cover))
                      : Center(
                          child: Text(inicial,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold))),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$hora,',
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 13)),
                    Text(nombre,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
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
              IconButton(
                onPressed: () =>
                    Navigator.pushNamed(ctx, AppRoutes.adminNotificaciones),
                icon: const Icon(Icons.notifications_outlined,
                    color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  color: Colors.white60, size: 14),
              const SizedBox(width: 6),
              Text(fecha,
                  style: const TextStyle(
                      color: Colors.white60, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Drawer ────────────────────────────────────────────────────────
  Widget _buildDrawer(
      BuildContext context, String nombre, String cargo, String inicial) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Color(0xFF0D2D6C), Color(0xFF1565C0)]),
            ),
            accountName: Text(nombre,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15)),
            accountEmail: Text(cargo),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.2),
              child: Text(inicial,
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ),
          ),

          _DrawerTile(Icons.dashboard_outlined,     'Dashboard',          AppRoutes.dashboardAdmin,       context),
          _DrawerTile(Icons.people_outline,          'Gestión de usuarios',AppRoutes.adminUsuarios,         context),
          _DrawerTile(Icons.local_hospital_outlined, 'Hospitales',         AppRoutes.adminHospitales,       context),
          _DrawerTile(Icons.grid_view_outlined,      'Áreas',              AppRoutes.adminAreas,            context),
          _DrawerTile(Icons.medical_services_outlined,'Equipos médicos',   AppRoutes.adminEquipos,          context),
          _DrawerTile(Icons.bar_chart_rounded,       'Reportes',           AppRoutes.adminReportes,         context),
          _DrawerTile(Icons.notifications_outlined,  'Notificaciones',     AppRoutes.adminNotificaciones,   context),

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
                        context, '/', (_) => false);
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

  static const _diasSemana = [
    'Lunes', 'Martes', 'Miércoles', 'Jueves',
    'Viernes', 'Sábado', 'Domingo'
  ];
  static const _meses = [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
    'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
  ];
}

// ══ Drawer Tile ────────────────────────────────────────────────────────
class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final BuildContext parentCtx;
  const _DrawerTile(this.icon, this.label, this.route, this.parentCtx);

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: AppColors.primary, size: 22),
        title: Text(label,
            style: const TextStyle(
                fontSize: 14, color: AppColors.textPrimary)),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(parentCtx, route);
        },
        dense: true,
      );
}

// ══ Stats Grid (8 tarjetas en 2 columnas) ──────────────────────────────
class _StatsGrid extends StatelessWidget {
  final List<_StatData> stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: stats.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.9),
        itemBuilder: (_, i) {
          final s = stats[i];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                      color: s.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(s.icon, color: s.color, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(s.valor,
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: s.color)),
                      Text(s.label,
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
}

class _StatData {
  final String label, valor;
  final IconData icon;
  final Color color;
  const _StatData(this.label, this.valor, this.icon, this.color);
}

// ══ Bar Chart (incidencias por mes) ───────────────────────────────────
class _BarChartSection extends StatelessWidget {
  final List<_MesData> datos;
  const _BarChartSection({required this.datos});

  @override
  Widget build(BuildContext context) {
    if (datos.isEmpty) return const SizedBox.shrink();
    final maxVal = datos.fold(0, (max, d) => d.count > max ? d.count : max);

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
      child: SizedBox(
        height: 160,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: datos.map((d) {
            final pct = maxVal > 0 ? d.count / maxVal : 0.0;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('${d.count}',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary)),
                    const SizedBox(height: 3),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      height: 110 * pct,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF1A4F9E), Color(0xFF0D2D6C)],
                        ),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(d.mes,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 11)),
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

class _MesData {
  final String mes;
  final int year, month;
  int count;
  _MesData({required this.mes, required this.year, required this.month, required this.count});
}

// ══ Pie Chart (estado de incidencias) — CustomPainter ────────────────
class _PieChartSection extends StatelessWidget {
  final Map<String, int> estadosMap;
  final int total;
  const _PieChartSection(
      {required this.estadosMap, required this.total});

  static const _colors = {
    'Pendiente': Color(0xFFF59E0B),
    'Asignada':  Color(0xFF3B82F6),
    'En Proceso':Color(0xFF8B5CF6),
    'Resuelta':  Color(0xFF10B981),
    'Cerrada':   Color(0xFF6B7280),
  };

  @override
  Widget build(BuildContext context) {
    if (total == 0) return const SizedBox.shrink();

    final slices = estadosMap.entries
        .where((e) => e.value > 0)
        .map((e) => _PieSlice(
              label: e.key,
              value: e.value.toDouble(),
              color: _colors[e.key] ?? AppColors.textSecondary,
            ))
        .toList();

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
          // Pie chart
          SizedBox(
            width: 140,
            height: 140,
            child: CustomPaint(
              painter: _PieChartPainter(slices: slices, total: total),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$total',
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary)),
                    const Text('total',
                        style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 20),

          // Leyenda
          Expanded(
            child: Column(
              children: slices.map((s) {
                final pct = total > 0
                    ? (s.value / total * 100).toStringAsFixed(0)
                    : '0';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                            color: s.color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(s.label,
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12)),
                      ),
                      Text('${s.value.toInt()} ($pct%)',
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PieSlice {
  final String label;
  final double value;
  final Color color;
  const _PieSlice(
      {required this.label, required this.value, required this.color});
}

class _PieChartPainter extends CustomPainter {
  final List<_PieSlice> slices;
  final int total;
  const _PieChartPainter({required this.slices, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    double startAngle = -math.pi / 2;
    final totalVal = slices.fold(0.0, (s, e) => s + e.value);

    for (final s in slices) {
      final sweep = 2 * math.pi * (s.value / totalVal);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle, sweep, true,
        Paint()..color = s.color..style = PaintingStyle.fill,
      );
      startAngle += sweep;
    }

    // Separadores blancos
    startAngle = -math.pi / 2;
    for (final s in slices) {
      final sweep = 2 * math.pi * (s.value / totalVal);
      canvas.drawLine(
        center,
        center + Offset(math.cos(startAngle) * radius,
                        math.sin(startAngle) * radius),
        Paint()..color = Colors.white..strokeWidth = 1.5,
      );
      startAngle += sweep;
    }

    // Centro blanco (donut)
    canvas.drawCircle(center, radius * 0.55,
        Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_PieChartPainter old) => old.slices != slices;
}

// ══ Alertas ───────────────────────────────────────────────────────────
class _AlertaTile extends StatelessWidget {
  final Map<String, dynamic> alerta;
  const _AlertaTile({required this.alerta});

  @override
  Widget build(BuildContext context) {
    final esError  = alerta['tipo'] == 'error';
    final color    = esError ? AppColors.error : AppColors.pending;
    final icon     = esError
        ? Icons.error_outline_rounded
        : Icons.warning_amber_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alerta['titulo'] as String? ?? '',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: color)),
                Text(alerta['msg'] as String? ?? '',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══ Actividad reciente ────────────────────────────────────────────────
class _ActividadCard extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  const _ActividadCard({required this.items});

  IconData _icon(String tipo) {
    switch (tipo) {
      case 'mantenimiento': return Icons.build_outlined;
      case 'completado':    return Icons.check_circle_outline;
      case 'sistema':       return Icons.settings_outlined;
      default:              return Icons.report_outlined;
    }
  }

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
          children: items.map((item) {
            final tipo  = item['tipo'] as String? ?? 'incidencia';
            final texto = item['texto'] as String? ?? '';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_icon(tipo),
                        color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(texto,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            height: 1.35)),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      );
}
