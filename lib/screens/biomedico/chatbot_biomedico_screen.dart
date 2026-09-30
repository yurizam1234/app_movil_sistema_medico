import 'package:flutter/material.dart';
import '../../config/app_colors.dart';

// ═══════════════════════════════════════════════════════════════════════
//  CHATBOT BIOMÉDICO — Identificación de equipos y guías de mantenimiento
// ═══════════════════════════════════════════════════════════════════════
class ChatbotBiomedicoScreen extends StatefulWidget {
  const ChatbotBiomedicoScreen({super.key});

  @override
  State<ChatbotBiomedicoScreen> createState() =>
      _ChatbotBiomedicoScreenState();
}

class _ChatbotBiomedicoScreenState extends State<ChatbotBiomedicoScreen> {
  final _ctrl        = TextEditingController();
  final _scroll      = ScrollController();
  final List<_Msg>   _msgs = [];
  bool _escribiendo  = false;

  // ── Base de conocimiento de equipos médicos ─────────────────────────
  static const _base = <String, Map<String, String>>{
    'ventilador': {
      'nombre': 'Ventilador Mecánico',
      'tipo': 'Equipo de soporte vital — Respiratorio',
      'descripcion':
          'Dispositivo que proporciona soporte ventilatorio a pacientes con insuficiencia respiratoria. Controla flujo, presión y volumen tidal.',
      'tipos': '• Volumétrico (control de volumen)\n• Presométrico (control de presión)\n• CPAP / BiPAP (presión positiva continua)\n• Ventilador de transporte (portátil)',
      'mantenimiento':
          '• Limpiar y reemplazar filtros cada 24 h de uso\n• Revisar circuitos y válvulas semanalmente\n• Calibración de sensores de flujo y presión cada 6 meses\n• Prueba de fugas antes de cada uso\n• Desinfección de circuito del paciente entre usos',
      'problemas':
          '• Alarma presión alta → revisar obstrucción en circuito o vía aérea\n• Alarma desconexión → verificar conexiones del circuito\n• Error flujo → limpiar sensor de flujo\n• Fugas → verificar juntas y tubuladuras',
    },
    'monitor': {
      'nombre': 'Monitor Multiparámetros',
      'tipo': 'Equipo de diagnóstico — Monitoreo continuo',
      'descripcion':
          'Vigilancia continua de signos vitales: ECG, SpO₂, presión arterial no invasiva, temperatura corporal y frecuencia respiratoria.',
      'tipos': '• Monitor de cabecera (unidad fija)\n• Monitor portátil (para traslados)\n• Monitor de transporte UCI',
      'mantenimiento':
          '• Limpiar electrodos y sensores cada turno\n• Verificar nivel de batería semanalmente\n• Calibración del módulo de presión arterial mensual\n• Revisión de cables y conectores mensual\n• Actualización de software semestral',
      'problemas':
          '• ECG con ruido → revisar colocación de electrodos y contacto con la piel\n• SpO₂ sin lectura → revisar perfusión, limpiar sensor óptico\n• Error batería → carga completa o reemplazo de batería\n• Pantalla sin imagen → verificar voltaje de alimentación',
    },
    'desfibrilador': {
      'nombre': 'Desfibrilador / DEA',
      'tipo': 'Equipo de soporte vital — Cardiovascular',
      'descripcion':
          'Dispositivo que administra una descarga eléctrica controlada para restablecer el ritmo cardíaco normal en fibrilación ventricular o taquicardia ventricular sin pulso.',
      'tipos': '• Desfibrilador manual bifásico\n• DEA (Desfibrilador Externo Automático)\n• Desfibrilador cardioversor implantable (DAI)',
      'mantenimiento':
          '• Verificar carga de batería diariamente\n• Revisar parches/paletas antes de cada uso\n• Auto-test del equipo diario (muchos modelos lo hacen automáticamente)\n• Mantenimiento preventivo anual por técnico certificado\n• Verificar fecha de vencimiento de parches cada 3 meses',
      'problemas':
          '• No carga → revisar batería, reemplazar si >2 años\n• Parches no detectados → limpiar conectores, verificar integridad\n• Alarma de batería baja → reemplazar batería inmediatamente\n• Error de ECG → revisar contacto de electrodos con el paciente',
    },
    'bomba': {
      'nombre': 'Bomba de Infusión / Bomba de Jeringa',
      'tipo': 'Equipo terapéutico — Administración de medicamentos',
      'descripcion':
          'Dispositivo electromecánico que administra fluidos intravenosos y medicamentos con flujo exacto y controlado, garantizando precisión en la dosificación.',
      'tipos': '• Bomba volumétrica (grandes volúmenes)\n• Bomba de jeringa (medicamentos concentrados)\n• Bomba de PCA (analgesia controlada por paciente)\n• Bomba enteral (nutrición)',
      'mantenimiento':
          '• Limpiar el mecanismo del cassette/jeringa semanalmente\n• Verificar alarmas y sensores de oclusión mensualmente\n• Calibración de flujo cada 6 meses\n• Revisar batería interna anualmente\n• Purga y limpieza de canales de fluido después de cada uso',
      'problemas':
          '• Alarma oclusión → verificar línea de infusión doblada o pinzada\n• Flujo inexacto → recalibrar o revisar cassette\n• Error de batería → conectar a red y revisar batería\n• Alarma aire en línea → purgar la línea correctamente',
    },
    'electrobistu': {
      'nombre': 'Electrobisturí (Unidad Electroquirúrgica)',
      'tipo': 'Equipo quirúrgico — Energía eléctrica',
      'descripcion':
          'Genera corriente eléctrica de alta frecuencia para cortar tejidos y coagular vasos sanguíneos durante cirugía, minimizando el sangrado.',
      'tipos': '• Monopolar (placa de retorno en paciente)\n• Bipolar (pinzas especializadas)\n• Ultrasónico (harmonic scalpel)\n• Radiofrecuencia (ablación)',
      'mantenimiento':
          '• Inspeccionar cables y conectores antes de cada uso\n• Limpiar el instrumento activo y placa de retorno\n• Verificar potencia de salida mensualmente\n• Revisión de sistema de alarmas de placa trimestralmente\n• Mantenimiento preventivo semestral por técnico',
      'problemas':
          '• Alarma placa → verificar contacto correcto con la piel del paciente\n• Corte ineficiente → aumentar potencia o revisar electrodo activo\n• Interferencia con monitor → separar cables del electrobisturí\n• Quemadura en placa → revisar integridad y colocación de la placa',
    },
    'ecografo': {
      'nombre': 'Ecógrafo / Ultrasonido',
      'tipo': 'Equipo de diagnóstico — Imagen médica',
      'descripcion':
          'Genera imágenes en tiempo real mediante ondas de ultrasonido. Se usa en diagnóstico obstétrico, cardíaco, abdominal, vascular y de partes blandas.',
      'tipos': '• Ecógrafo general (abdomen, obstetricia)\n• Ecocardiógrafo (corazón)\n• Ecógrafo portátil (punto de atención)\n• Doppler (flujo sanguíneo)\n• Ecógrafo 3D/4D',
      'mantenimiento':
          '• Limpiar y desinfectar transductores después de cada uso\n• Revisar cables de transductores semanalmente\n• Calibración de imagen mensual\n• Actualización de software semestral\n• Mantenimiento de sistema de refrigeración anual',
      'problemas':
          '• Imagen con ruido → limpiar transductor, usar gel adecuado\n• Transductor sin imagen → revisar conector y cable\n• Pantalla congelada → reiniciar sistema\n• Imagen oscura → ajustar ganancia y profundidad',
    },
    'rayos': {
      'nombre': 'Equipo de Rayos X',
      'tipo': 'Equipo de diagnóstico — Imagen por radiación',
      'descripcion':
          'Genera radiación ionizante para obtener imágenes diagnósticas de estructuras internas (huesos, tórax, abdomen). Esencial en urgencias y diagnóstico.',
      'tipos': '• Rayos X fijo de sala\n• Rayos X portátil (arco en C)\n• Fluoroscopía (tiempo real)\n• Mamógrafo\n• Tomógrafo (TC / TAC)',
      'mantenimiento':
          '• Verificar integridad del colimador y filtros mensualmente\n• Control de calidad de imagen trimestral\n• Revisión del sistema de refrigeración del tubo semestral\n• Dosimetría y protección radiológica anual\n• Verificar funcionamiento de blindajes y alertas de radiación',
      'problemas':
          '• Imagen sobreexpuesta → reducir kV o mAs\n• Imagen subexpuesta → aumentar técnica radiográfica\n• Artefactos → revisar detector o chasis\n• Equipo no dispara → verificar conexión eléctrica y permisos de usuario',
    },
    'autoclave': {
      'nombre': 'Esterilizador de Vapor (Autoclave)',
      'tipo': 'Equipo de esterilización — Procesamiento de instrumental',
      'descripcion':
          'Esteriliza instrumental médico y quirúrgico mediante vapor de agua saturado a alta temperatura (121–134 °C) y presión. Elimina microorganismos incluyendo esporas.',
      'tipos': '• Autoclave de gravedad (desplazamiento por gravedad)\n• Autoclave de pre-vacío (ciclo rápido)\n• Autoclave de gas plasma (material termosensible)\n• Autoclave de óxido de etileno (ETO)',
      'mantenimiento':
          '• Limpiar cámara interior semanalmente\n• Revisar juntas y sellos de puerta mensualmente\n• Validar ciclos con indicadores biológicos semanalmente\n• Mantenimiento preventivo de válvulas de seguridad semestral\n• Calibración de sensores de presión y temperatura anual',
      'problemas':
          '• Fallo en ciclo → revisar temperatura y presión, verificar carga\n• Fuga de vapor → revisar junta de puerta, reemplazar si necesario\n• Indicador biológico positivo → revalidar ciclo, no usar materiales\n• Error de presión → verificar trampa de vapor y filtros',
    },
    'oximetro': {
      'nombre': 'Oxímetro de Pulso',
      'tipo': 'Equipo de diagnóstico — Monitoreo no invasivo',
      'descripcion':
          'Mide de forma no invasiva la saturación de oxígeno en sangre (SpO₂) y la frecuencia cardíaca mediante luz infrarroja transmitida a través del dedo.',
      'tipos': '• Oxímetro de dedo (portátil)\n• Oxímetro de cabecera (con alarmas)\n• Sensor neonatal (para recién nacidos)\n• Sensor de reflexión (frente)',
      'mantenimiento':
          '• Limpiar sensor con alcohol isopropílico después de cada uso\n• Verificar calibración con oxímetro de referencia mensualmente\n• Revisar cable del sensor semanalmente\n• Reemplazar sensor si la lectura es inconsistente',
      'problemas':
          '• Sin lectura → mejorar perfusión (calentar dedo), limpiar sensor\n• Lectura baja sin causa → verificar con otro dedo o equipo\n• Artefactos por movimiento → usar sensor de frente o neonatal\n• Alarma continua → revisar valores normales del paciente',
    },
    'incubadora': {
      'nombre': 'Incubadora Neonatal',
      'tipo': 'Equipo de soporte vital — Neonatología',
      'descripcion':
          'Proporciona un ambiente térmico controlado y estéril para recién nacidos prematuros o de bajo peso que requieren atención especial fuera del útero materno.',
      'tipos': '• Incubadora cerrada (control de humedad y temperatura)\n• Cuna de calor radiante (acceso abierto para procedimientos)\n• Incubadora de transporte (traslados)',
      'mantenimiento':
          '• Limpiar y desinfectar completamente entre pacientes\n• Verificar temperatura interna vs. sensor cada turno\n• Revisar sistema de humidificación semanalmente\n• Calibración de sensores de temperatura y O₂ mensual\n• Revisión del sistema de alarmas mensual',
      'problemas':
          '• Temperatura inestable → revisar sensor de piel del bebé, verificar corrientes de aire\n• Alarma temperatura alta → revisar configuración y posición del bebé\n• Humedad insuficiente → revisar nivel de agua y calefactor de humidificador\n• Fallo de alarma → revisar batería de respaldo y calibrar',
    },
  };

  // ── Palabras clave → equipo ─────────────────────────────────────────
  static const _keywords = <String, List<String>>{
    'ventilador': ['ventilador', 'ventilaci', 'respirador', 'cpap', 'bipap', 'vm-'],
    'monitor':    ['monitor', 'multiparametro', 'ecg', 'electrocardiograma', 'spo2', 'signos vitales'],
    'desfibrilador': ['desfibrilador', 'dea', 'cardioversor', 'fibrilacion', 'descarga'],
    'bomba':      ['bomba', 'infusion', 'perfusion', 'jeringa', 'pca'],
    'electrobistu': ['electrobisturi', 'bisturi', 'electrocirugia', 'coagulador', 'monopolar', 'bipolar'],
    'ecografo':   ['ecografo', 'ultrasonido', 'ecografia', 'doppler', 'transductor'],
    'rayos':      ['rayos x', 'rayos-x', 'radiografia', 'fluoroscopia', 'tomogr', 'mamogr'],
    'autoclave':  ['autoclave', 'esterilizador', 'esteriliz', 'vapor', 'eto'],
    'oximetro':   ['oximetro', 'oximetria', 'saturacion', 'spo2', 'pulso'],
    'incubadora': ['incubadora', 'neonatal', 'neonato', 'prematuro', 'cuna de calor'],
  };

  @override
  void initState() {
    super.initState();
    _addBot('¡Hola! Soy el asistente biomédico de MedControl 🤖\n\n'
        'Puedo ayudarte con:\n'
        '• Identificar tipos de equipos médicos\n'
        '• Guías de mantenimiento preventivo\n'
        '• Diagnóstico de problemas comunes\n\n'
        'Escribe el nombre de un equipo (ej: "ventilador", "monitor cardíaco", "desfibrilador") o hazme una pregunta.');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _addBot(String text) {
    setState(() => _msgs.add(_Msg(text: text, esUsuario: false)));
    _scrollBottom();
  }

  void _scrollBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _enviar() async {
    final texto = _ctrl.text.trim();
    if (texto.isEmpty) return;

    setState(() {
      _msgs.add(_Msg(text: texto, esUsuario: true));
      _ctrl.clear();
      _escribiendo = true;
    });
    _scrollBottom();

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    final respuesta = _generar(texto.toLowerCase());
    setState(() {
      _escribiendo = false;
      _msgs.add(_Msg(text: respuesta, esUsuario: false));
    });
    _scrollBottom();
  }

  String _generar(String input) {
    // Saludos
    if (RegExp(r'^(hola|buenos|buenas|hi|hey|saludos)').hasMatch(input)) {
      return '¡Hola! ¿En qué equipo puedo ayudarte hoy? Puedes preguntarme sobre ventiladores, monitores, desfibriladores, bombas de infusión, ecógrafos y más.';
    }

    // Ayuda general
    if (input.contains('ayuda') || input.contains('qué puedes') || input.contains('que puedes')) {
      return 'Puedo informarte sobre:\n\n🔧 **Equipos disponibles:**\n• Ventilador mecánico\n• Monitor multiparámetros\n• Desfibrilador / DEA\n• Bomba de infusión\n• Electrobisturí\n• Ecógrafo\n• Rayos X\n• Autoclave\n• Oxímetro de pulso\n• Incubadora neonatal\n\nEscribe el nombre de cualquiera para ver su información completa.';
    }

    // Mantenimiento general
    if (input.contains('mantenimiento') && !_tieneEquipo(input)) {
      return 'Para darte la guía de mantenimiento específica, necesito saber qué equipo. Por ejemplo:\n• "mantenimiento del ventilador"\n• "mantenimiento del monitor"\n• "mantenimiento del autoclave"\n\n¿De cuál equipo necesitas la guía?';
    }

    // Buscar equipo por palabras clave
    for (final entry in _keywords.entries) {
      for (final kw in entry.value) {
        if (input.contains(kw)) {
          final info = _base[entry.key]!;

          // ¿Pregunta específica de mantenimiento?
          if (input.contains('mantenim') || input.contains('preventivo') || input.contains('limpi')) {
            return '🔧 **Mantenimiento — ${info['nombre']}**\n\n${info['mantenimiento']}';
          }

          // ¿Pregunta de problemas o averías?
          if (input.contains('problem') || input.contains('falla') || input.contains('error') ||
              input.contains('alarma') || input.contains('averia') || input.contains('arreglar')) {
            return '⚠️ **Problemas comunes — ${info['nombre']}**\n\n${info['problemas']}';
          }

          // ¿Pregunta de tipos?
          if (input.contains('tipo') || input.contains('clase') || input.contains('modelo') || input.contains('cuál')) {
            return '📋 **Tipos de ${info['nombre']}**\n\n${info['tipos']}';
          }

          // Información completa
          return '🏥 **${info['nombre']}**\n'
              '📌 *${info['tipo']}*\n\n'
              '${info['descripcion']}\n\n'
              '📋 **Tipos:**\n${info['tipos']}\n\n'
              '🔧 **Mantenimiento preventivo:**\n${info['mantenimiento']}\n\n'
              '⚠️ **Problemas comunes:**\n${info['problemas']}';
        }
      }
    }

    // Lista de equipos
    if (input.contains('lista') || input.contains('todos') || input.contains('cuales') || input.contains('cuáles')) {
      return '📋 **Equipos en mi base de conocimiento:**\n\n'
          '1. Ventilador Mecánico\n'
          '2. Monitor Multiparámetros\n'
          '3. Desfibrilador / DEA\n'
          '4. Bomba de Infusión / Jeringa\n'
          '5. Electrobisturí\n'
          '6. Ecógrafo / Ultrasonido\n'
          '7. Equipo de Rayos X\n'
          '8. Autoclave / Esterilizador\n'
          '9. Oxímetro de Pulso\n'
          '10. Incubadora Neonatal\n\n'
          'Escribe el nombre del que necesitas consultar.';
    }

    // Sin coincidencia
    return 'No encontré información específica sobre eso. Puedo ayudarte con equipos como ventilador, monitor, desfibrilador, bomba de infusión, ecógrafo, rayos X, autoclave, oxímetro o incubadora.\n\nIntenta escribir el nombre del equipo directamente.';
  }

  bool _tieneEquipo(String input) {
    for (final kws in _keywords.values) {
      for (final kw in kws) {
        if (input.contains(kw)) return true;
      }
    }
    return false;
  }

  // ── Sugerencias rápidas ─────────────────────────────────────────────
  static const _sugerencias = [
    'Ventilador mecánico',
    'Monitor cardíaco',
    'Desfibrilador',
    'Bomba de infusión',
    'Ecógrafo',
    'Autoclave',
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF0F4FF),
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          title: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.smart_toy_outlined,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Asistente Biomédico',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                  Text('Base de conocimiento de equipos',
                      style: TextStyle(
                          fontSize: 11, color: Colors.white70)),
                ],
              ),
            ],
          ),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_outlined),
              onPressed: () {
                setState(() => _msgs.clear());
                _addBot('Chat reiniciado. ¿Sobre qué equipo médico necesitas información?');
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Sugerencias
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _sugerencias.map((s) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(s, style: const TextStyle(fontSize: 12)),
                      avatar: const Icon(Icons.medical_services_outlined,
                          size: 14, color: AppColors.primary),
                      onPressed: () {
                        _ctrl.text = s;
                        _enviar();
                      },
                      backgroundColor: AppColors.surfaceVariant,
                      side: const BorderSide(color: AppColors.divider),
                    ),
                  )).toList(),
                ),
              ),
            ),

            // Mensajes
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                itemCount: _msgs.length + (_escribiendo ? 1 : 0),
                itemBuilder: (_, i) {
                  if (_escribiendo && i == _msgs.length) {
                    return const _TypingBubble();
                  }
                  return _BurbujaMensaje(msg: _msgs[i]);
                },
              ),
            ),

            // Input
            Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(
                  12, 10, 12,
                  MediaQuery.of(context).padding.bottom + 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      onSubmitted: (_) => _enviar(),
                      textInputAction: TextInputAction.send,
                      decoration: InputDecoration(
                        hintText: 'Pregunta sobre un equipo médico...',
                        hintStyle: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 14),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _enviar,
                    child: Container(
                      width: 46, height: 46,
                      decoration: const BoxDecoration(
                          color: AppColors.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

// ── Burbuja de mensaje ─────────────────────────────────────────────────
class _BurbujaMensaje extends StatelessWidget {
  final _Msg msg;
  const _BurbujaMensaje({required this.msg});

  @override
  Widget build(BuildContext context) {
    final esUsuario = msg.esUsuario;
    return Align(
      alignment:
          esUsuario ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.82),
        decoration: BoxDecoration(
          color: esUsuario ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft:     const Radius.circular(18),
            topRight:    const Radius.circular(18),
            bottomLeft:  Radius.circular(esUsuario ? 18 : 4),
            bottomRight: Radius.circular(esUsuario ? 4  : 18),
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 4,
                offset: const Offset(0, 2))
          ],
        ),
        child: Text(
          msg.text,
          style: TextStyle(
            color:    esUsuario ? Colors.white : AppColors.textPrimary,
            fontSize: 13.5,
            height:   1.45,
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();
  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 4,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) => _Dot(delay: i * 200)),
          ),
        ),
      );
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});
  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay),
        () { if (mounted) _ctrl.forward(); });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 3),
    child: FadeTransition(
      opacity: _anim,
      child: Container(
        width: 7, height: 7,
        decoration: const BoxDecoration(
            color: AppColors.textSecondary, shape: BoxShape.circle),
      ),
    ),
  );
}

class _Msg {
  final String text;
  final bool esUsuario;
  _Msg({required this.text, required this.esUsuario});
}
