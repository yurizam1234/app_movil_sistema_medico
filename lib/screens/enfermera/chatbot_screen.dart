import 'package:flutter/material.dart';
import '../../config/app_colors.dart';

// ═══════════════════════════════════════════════════════════════════════
//  CHATBOT ASISTENTE — MÓDULO ENFERMERA
// ═══════════════════════════════════════════════════════════════════════
class ChatBotEnfermeraScreen extends StatelessWidget {
  const ChatBotEnfermeraScreen({super.key});

  static const _faqs = [
    _Faq(
      pregunta: '¿Cómo registrar una incidencia?',
      respuesta:
          'Selecciona "Registrar Incidencia" en el menú de inicio, elige el equipo afectado del listado, '
          'selecciona el tipo de incidencia, escribe una descripción detallada del problema, adjunta '
          'fotografías si es necesario y presiona "Enviar Solicitud". Recibirás una confirmación de registro.',
      icono: Icons.edit_note,
    ),
    _Faq(
      pregunta: '¿Cómo consultar mis solicitudes?',
      respuesta:
          'Ingresa a "Mis Solicitudes" desde el menú de inicio o la barra de navegación. Allí verás '
          'el listado completo de todas las incidencias que has registrado con su estado actualizado '
          'en tiempo real.',
      icono: Icons.assignment_outlined,
    ),
    _Faq(
      pregunta: '¿Qué significa el estado "Asignada"?',
      respuesta:
          'El estado "Asignada" indica que tu solicitud ya fue recibida por el área biomédica y fue '
          'asignada a un técnico específico. El técnico revisará el problema y se pondrá en contacto '
          'contigo o acudirá al área indicada.',
      icono: Icons.person_pin_circle_outlined,
    ),
    _Faq(
      pregunta: '¿Qué significa el estado "En Proceso"?',
      respuesta:
          'El estado "En Proceso" significa que el técnico biomédico asignado ya está trabajando '
          'activamente en el diagnóstico y solución del problema reportado. Puedes ver el nombre '
          'del técnico en el detalle de la solicitud.',
      icono: Icons.build_outlined,
    ),
    _Faq(
      pregunta: '¿Qué significa el estado "Pendiente"?',
      respuesta:
          'El estado "Pendiente" indica que tu solicitud fue registrada exitosamente en el sistema '
          'pero aún no ha sido asignada a un técnico. El área biomédica la atenderá en orden de '
          'prioridad y disponibilidad.',
      icono: Icons.hourglass_empty,
    ),
    _Faq(
      pregunta: '¿Qué significa el estado "Resuelta"?',
      respuesta:
          'El estado "Resuelta" indica que el técnico biomédico completó el trabajo, el equipo fue '
          'reparado o mantenido, y está nuevamente operativo. Puedes revisar el historial completo '
          'de intervenciones en el detalle de la solicitud.',
      icono: Icons.check_circle_outline,
    ),
    _Faq(
      pregunta: '¿Cómo escanear un equipo médico?',
      respuesta:
          'Presiona el botón "Escanear Equipo" en la pantalla de inicio. Apunta la cámara hacia el '
          'código QR adherido al equipo médico. El sistema identificará automáticamente el equipo, '
          'mostrará su información y te permitirá registrar una incidencia o ver su historial.',
      icono: Icons.qr_code_scanner,
    ),
    _Faq(
      pregunta: '¿Cómo contactar al técnico asignado?',
      respuesta:
          'Ingresa al detalle de tu solicitud y encontrarás el nombre del técnico biomédico asignado. '
          'Desde ahí podrás acceder al chat directo con el técnico para coordinar el acceso al equipo '
          'o brindar información adicional.',
      icono: Icons.chat_outlined,
    ),
    _Faq(
      pregunta: '¿Cómo ver el historial de un equipo?',
      respuesta:
          'Puedes ver el historial de dos formas: (1) Escanea el código QR del equipo y selecciona '
          '"Ver Historial", o (2) desde la sección "Equipos" en la barra inferior, busca el equipo '
          'y toca "Historial de mantenimiento".',
      icono: Icons.history,
    ),
    _Faq(
      pregunta: '¿Cómo adjuntar fotografías a una incidencia?',
      respuesta:
          'Durante el registro de una incidencia, encontrarás la sección "Fotografías". Toca el '
          'botón "+" para agregar imágenes desde la cámara o la galería del dispositivo. Puedes '
          'adjuntar hasta 5 fotografías por incidencia.',
      icono: Icons.photo_camera_outlined,
    ),
    _Faq(
      pregunta: '¿Qué hacer si un equipo deja de funcionar?',
      respuesta:
          'Si un equipo deja de funcionar: (1) Desconecta el equipo si es seguro hacerlo, '
          '(2) Registra inmediatamente una incidencia en MedControl con descripción detallada, '
          '(3) Notifica al jefe de turno, y (4) No intentes reparar el equipo por cuenta propia.',
      icono: Icons.power_off_outlined,
    ),
    _Faq(
      pregunta: '¿Cuánto tiempo tarda en resolverse una incidencia?',
      respuesta:
          'El tiempo varía según la complejidad: averías simples se resuelven en 2-4 horas, '
          'problemas complejos pueden tardar 1-3 días. Si el equipo requiere repuestos, el técnico '
          'te informará el tiempo estimado desde el detalle de la solicitud.',
      icono: Icons.schedule_outlined,
    ),
    _Faq(
      pregunta: '¿Qué tipos de incidencias puedo registrar?',
      respuesta:
          'Puedes registrar: Avería (fallo total o parcial), Mal funcionamiento (comportamiento '
          'irregular), Calibración (necesidad de ajuste), Mantenimiento preventivo (servicio '
          'programado), Fallo eléctrico, Alarma (alertas persistentes) y Accidente.',
      icono: Icons.category_outlined,
    ),
    _Faq(
      pregunta: '¿Cómo saber quién es el técnico asignado?',
      respuesta:
          'Ingresa a "Mis Solicitudes" y abre el detalle de la incidencia. En la sección '
          '"Técnico Asignado" verás el nombre completo del técnico biomédico, su especialidad '
          'y la fecha en que fue asignado.',
      icono: Icons.engineering_outlined,
    ),
    _Faq(
      pregunta: '¿Cómo recuperar mi contraseña?',
      respuesta:
          'En la pantalla de inicio de sesión, toca "¿Olvidaste tu contraseña?". Ingresa tu '
          'correo electrónico institucional y recibirás un enlace de recuperación en tu bandeja '
          'de entrada. El enlace expira en 24 horas.',
      icono: Icons.lock_reset_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ChatBot Asistente'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(Icons.smart_toy_outlined,
                color: Colors.white.withOpacity(0.85)),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildBotGreeting()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _FaqTile(faq: _faqs[i]),
                childCount: _faqs.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotGreeting() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.accent, AppColors.accentDark],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: AppColors.accent.withOpacity(0.3),
              blurRadius: 14,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Asistente MedControl',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 17),
                ),
                SizedBox(height: 6),
                Text(
                  'Hola 👋 Soy tu asistente virtual MedControl. ¿En qué puedo ayudarte?',
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Modelo de pregunta frecuente ─────────────────────────────────────
class _Faq {
  final String pregunta;
  final String respuesta;
  final IconData icono;

  const _Faq(
      {required this.pregunta,
      required this.respuesta,
      required this.icono});
}

// ─── Tile expandible ──────────────────────────────────────────────────
class _FaqTile extends StatefulWidget {
  final _Faq faq;
  const _FaqTile({required this.faq});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _controller;
  late final Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _rotation = Tween<double>(begin: 0, end: 0.5).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _controller.forward() : _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        children: [
          InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.12),
                        shape: BoxShape.circle),
                    child: Icon(widget.faq.icono,
                        color: AppColors.accent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.faq.pregunta,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.textPrimary),
                    ),
                  ),
                  RotationTransition(
                    turns: _rotation,
                    child: const Icon(Icons.expand_more,
                        color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.smart_toy,
                        color: AppColors.accent, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.faq.respuesta,
                        style: const TextStyle(
                            fontSize: 13.5,
                            color: AppColors.textPrimary,
                            height: 1.55),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }
}
