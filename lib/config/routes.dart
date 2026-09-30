import 'package:flutter/material.dart';
import 'package:proyect/screens/login/login_screen.dart';
import 'package:proyect/screens/home/home_screen.dart';
import 'package:proyect/screens/inventario/inventario_screen.dart';
import 'package:proyect/screens/ordenes/ordenes_screen.dart';
import 'package:proyect/screens/recorrido/recorrido_diario_screen.dart';
import 'package:proyect/screens/agenda/agenda_screen.dart';
import 'package:proyect/screens/incidencias/registrar_incidencia_screen.dart';
import 'package:proyect/screens/incidencias/mis_solicitudes_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/enfermera/dashboard_enfermera_screen.dart';
import '../screens/enfermera/chatbot_screen.dart';
import '../screens/enfermera/registrar_incidencia_screen.dart';
import '../screens/enfermera/solicitudes_screen.dart';
import '../screens/enfermera/perfil_screen.dart';
import '../screens/enfermera/scan_equipo_screen.dart';
import '../screens/gerente/dashboard_gerente_screen.dart';
import '../screens/biomedico/dashboard_biomedico_screen.dart';
import '../screens/biomedico/solicitudes_biomedico_screen.dart';
import '../screens/biomedico/mis_asignaciones_screen.dart';
import '../screens/biomedico/registro_mantenimiento_screen.dart';
import '../screens/biomedico/inventario_repuestos_screen.dart';
import '../screens/biomedico/reportes_screen.dart';
import '../screens/biomedico/notificaciones_screen.dart';
import '../screens/biomedico/historial_equipo_screen.dart';
import '../screens/biomedico/perfil_biomedico_screen.dart';
import '../screens/biomedico/chats_recientes_screen.dart';
import '../screens/biomedico/chatbot_biomedico_screen.dart';
import '../screens/development/development_screen.dart';
import '../screens/login/register_screen.dart';
import '../screens/admin/dashboard_admin_screen.dart';
import '../screens/admin/gestion_usuarios_screen.dart';
import '../screens/admin/gestion_hospitales_screen.dart';
import '../screens/admin/gestion_areas_screen.dart';
import '../screens/admin/gestion_equipos_screen.dart';
import '../screens/admin/reportes_admin_screen.dart';
import '../screens/admin/notificaciones_admin_screen.dart';

class AppRoutes {
  // ── Globales ─────────────────────────────────────────────────────────
  static const splash             = '/splash';
  static const register           = '/register';
  static const login              = '/';
  static const home               = '/home';
  static const inventario         = '/inventario';
  static const ordenes            = '/ordenes';
  static const recorrido          = '/recorrido';
  static const agenda             = '/agenda';
  static const incidencia         = '/incidencia';
  static const solicitudes        = '/solicitudes';
  static const development        = '/development';

  // ── Dashboards ───────────────────────────────────────────────────────
  static const dashboardEnfermera = '/dashboard-enfermera';
  static const dashboardBiomedico = '/dashboard-biomedico';
  static const dashboardGerente   = '/dashboard-gerente';
  static const dashboardAdmin     = '/dashboard-admin';

  // ── Módulo Admin ─────────────────────────────────────────────────────
  static const adminUsuarios      = '/admin/usuarios';
  static const adminHospitales    = '/admin/hospitales';
  static const adminAreas         = '/admin/areas';
  static const adminEquipos       = '/admin/equipos';
  static const adminReportes      = '/admin/reportes';
  static const adminNotificaciones= '/admin/notificaciones';

  // ── Módulo Enfermera ─────────────────────────────────────────────────
  static const enfChatbot         = '/enfermera/chatbot';
  static const enfRegistrar       = '/enfermera/registrar';
  static const enfSolicitudes     = '/enfermera/solicitudes';
  static const enfPerfil          = '/enfermera/perfil';
  static const enfScan            = '/enfermera/scan';

  // ── Módulo Biomédico ─────────────────────────────────────────────────
  static const bioSolicitudes     = '/biomedico/solicitudes';
  static const bioAsignaciones    = '/biomedico/mis-asignaciones';
  static const bioMantenimiento   = '/biomedico/mantenimiento';
  static const bioInventario      = '/biomedico/inventario';
  static const bioReportes        = '/biomedico/reportes';
  static const bioNotificaciones  = '/biomedico/notificaciones';
  static const bioHistorial       = '/biomedico/historial';
  static const bioChat            = '/biomedico/chat';
  static const bioChatbot         = '/biomedico/chatbot';
  static const bioPerfil          = '/biomedico/perfil';

  // ── Mapa de rutas ────────────────────────────────────────────────────
  static Map<String, WidgetBuilder> get routes => {
    splash:             (_) => const SplashScreen(),
    login:              (_) => LoginScreen(),
    register:           (_) => const RegisterScreen(),
    home:               (_) => const HomeScreen(),
    inventario:         (_) => const InventarioScreen(),
    ordenes:            (_) => const OrdenesScreen(),
    recorrido:          (_) => const RecorridoDiarioScreen(),
    agenda:             (_) => const AgendaScreen(),
    incidencia:         (_) => const RegistrarIncidenciaScreen(),
    solicitudes:        (_) => const MisSolicitudesScreen(),
    development:        (_) => const DevelopmentScreen(),

    // Dashboards
    dashboardEnfermera:  (_) => const DashboardEnfermeraScreen(),
    dashboardBiomedico:  (_) => const DashboardBiomedicoScreen(),
    dashboardGerente:    (_) => const DashboardGerenteScreen(),
    dashboardAdmin:      (_) => const DashboardAdminScreen(),

    // Admin
    adminUsuarios:       (_) => const GestionUsuariosScreen(),
    adminHospitales:     (_) => const GestionHospitalesScreen(),
    adminAreas:          (_) => const GestionAreasScreen(),
    adminEquipos:        (_) => const GestionEquiposScreen(),
    adminReportes:       (_) => const ReportesAdminScreen(),
    adminNotificaciones: (_) => const NotificacionesAdminScreen(),

    // Enfermera
    enfChatbot:         (_) => const ChatBotEnfermeraScreen(),
    enfRegistrar:       (_) => const RegistrarIncidenciaEnfermeraScreen(),
    enfSolicitudes:     (_) => const SolicitudesEnfermeraScreen(),
    enfPerfil:          (_) => const PerfilEnfermeraScreen(),
    enfScan:            (_) => const ScanEquipoScreen(),

    // Biomédico
    bioSolicitudes:     (_) => const SolicitudesBiomedicoScreen(),
    bioAsignaciones:    (_) => const MisAsignacionesScreen(),
    bioMantenimiento:   (_) => const RegistroMantenimientoScreen(
                                  incidenciaId: '', equipoNombre: '', equipoData: {}),
    bioInventario:      (_) => const InventarioRepuestosScreen(),
    bioReportes:        (_) => const ReportesScreen(),
    bioNotificaciones:  (_) => const NotificacionesScreen(),
    bioHistorial:       (_) => const HistorialEquipoScreen(equipoId: ''),
    bioChat:            (_) => const ChatsRecientesScreen(),
    bioChatbot:         (_) => const ChatbotBiomedicoScreen(),
    bioPerfil:          (_) => const PerfilBiomedicoScreen(),
  };
}
