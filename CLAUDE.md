# MedControl — Flutter App

Sistema de Gestión de Equipos Médicos. App Flutter multiplataforma con Firebase.

## Stack
- **Flutter** SDK ^3.10.7 — Material Design
- **Firebase Auth** ^5.6.2 — autenticación por email/password
- **Cloud Firestore** ^5.6.11 — base de datos
- **firebase_core** ^3.15.2

## Estructura del proyecto

```
lib/
├── main.dart                  # Entry point — Firebase.initializeApp + MaterialApp
├── firebase_options.dart      # Generado por FlutterFire CLI
├── config/
│   ├── routes.dart            # AppRoutes — todas las rutas nombradas
│   ├── app_theme.dart         # AppTheme.lightTheme
│   ├── colors.dart / app_colors.dart
│   └── theme.dart
├── models/
│   ├── user.dart              # User (uid, email, displayName, role/cargo)
│   ├── equipo.dart            # Equipo con fromJson/toJson
│   ├── orden_servicio.dart
│   ├── evento.dart
│   └── area.dart
├── screens/
│   ├── login/                 # LoginScreen — FirebaseAuth signIn
│   ├── home/                  # HomeScreen — menú general
│   ├── development/           # DevelopmentScreen — menú dev para pruebas
│   ├── biomedico/             # Dashboard + Asignaciones, Historial, Reportes,
│   │                          #   Notificaciones, OrdenesTrabajo, Mantenimiento,
│   │                          #   InventarioRepuestos, DetalleRepuesto, DetalleOrden
│   ├── enfermera/             # Dashboard + RegistrarIncidencia, Solicitudes,
│   │                          #   DetalleSolicitud, ChatBot, Historial, Perfil
│   ├── gerente/               # DashboardGerente
│   ├── inventario/            # InventarioScreen, EquipoDetalle, EditarEquipo
│   ├── ordenes/               # OrdenesScreen, OrdenDetalle, OrdenesEquipo
│   ├── incidencias/           # RegistrarIncidencia, MisSolicitudes, DetalleSolicitud
│   ├── agenda/                # AgendaScreen, NuevoEvento
│   └── recorrido/             # RecorridoDiario
└── widgets/
    ├── custom_textfield.dart
    ├── custom_button.dart
    ├── info_card.dart
    ├── status_chip.dart
    ├── photo_gallery.dart
    └── action_button.dart
```

## Roles de usuario
| Rol | Dashboard | Ruta |
|-----|-----------|------|
| Biomédico | DashboardBiomedicoScreen | navega directo post-login |
| Enfermera | DashboardEnfermeraScreen | `/dashboard-enfermera` |
| Gerente | DashboardGerenteScreen | `/dashboard-gerente` |

> **Actualmente** el login redirige siempre a `DashboardBiomedicoScreen` (hardcodeado). La lógica de roles por Firestore está pendiente.

## Rutas nombradas (AppRoutes)
```dart
'/'                    → LoginScreen
'/home'               → HomeScreen
'/inventario'         → InventarioScreen
'/ordenes'            → OrdenesScreen
'/recorrido'          → RecorridoDiarioScreen
'/agenda'             → AgendaScreen
'/incidencia'         → RegistrarIncidenciaScreen
'/solicitudes'        → MisSolicitudesScreen
'/dashboard-enfermera'→ DashboardEnfermeraScreen
'/dashboard-gerente'  → DashboardGerenteScreen
'/development'        → DevelopmentScreen  ← initialRoute actual
```

## Assets
```
assets/images/
├── hospital_banner.avif
├── logo_medcontrol.jpg
├── medico.webp
└── equipos.jpg
```

## Colores principales
- Azul primario: `Color(0xFF0D2D6C)`
- Fondo claro: `Color(0xFFF5F7FA)`
- Teal (enfermera): `Colors.teal`

## Convenciones de código
- Widgets `StatelessWidget` por defecto; `StatefulWidget` solo cuando hay estado local
- Navegación por rutas nombradas (`pushNamed`) para pantallas globales; `MaterialPageRoute` para sub-pantallas de un módulo
- Modelos tienen `fromJson` factory; los que se escriben en Firestore también tienen `toJson`
- Color primario definido en `config/app_colors.dart` (usar constantes, no literales hex directos)

## Slash Commands personalizados (Skills)

| Comando | Descripción |
|---------|-------------|
| `/flutter-design` | Analiza la pantalla abierta y aplica Material Design 3 + UX médico |
| `/ui-review` | Revisión estructurada con checklist y puntuación /10 por categoría |
| `/ux-patterns` | Patrones UX listos para MedControl (formularios, listas, navegación multi-rol) |
| `/redesign` | Rediseño completo de una pantalla con MD3 y ThemeData correcto |

Definidos en `.claude/commands/`.

## Comandos Flutter
```bash
flutter run                        # correr en dispositivo/emulador
flutter run -d chrome              # correr en web
flutter pub get                    # instalar dependencias
flutter build apk                  # compilar Android
flutterfire configure              # reconfigurar Firebase
```

## Pendientes conocidos
- Lógica de roles: leer `cargo` del usuario en Firestore y redirigir al dashboard correcto
- `DashboardEnfermeraScreen`: rutas `/registrarIncidencia`, `/chatbot` no están en `AppRoutes`
- `DevelopmentScreen`: solo muestra el módulo Enfermera; faltan Biomédico y Gerente
- Datos hardcodeados en dashboards (nombre, estadísticas) — conectar a Firestore
