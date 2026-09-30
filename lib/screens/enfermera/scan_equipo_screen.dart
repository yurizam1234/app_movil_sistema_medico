import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/app_colors.dart';
import '../../config/routes.dart';

// ═══════════════════════════════════════════════════════════════════════
//  SCAN EQUIPO SCREEN — MEDCONTROL
//  Escanea QR del equipo → busca en Firestore → muestra resultado
// ═══════════════════════════════════════════════════════════════════════
class ScanEquipoScreen extends StatefulWidget {
  const ScanEquipoScreen({super.key});

  @override
  State<ScanEquipoScreen> createState() => _ScanEquipoScreenState();
}

class _ScanEquipoScreenState extends State<ScanEquipoScreen> {
  late final MobileScannerController _scanner;
  bool _scanned    = false;
  bool _searching  = false;
  bool _torchOn    = false;
  bool _frontCam   = false;

  @override
  void initState() {
    super.initState();
    _scanner = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  // ── Detectar QR ────────────────────────────────────────────────────
  void _onDetect(BarcodeCapture capture) async {
    if (_scanned || _searching) return;
    final code = capture.barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    setState(() {
      _scanned   = true;
      _searching = true;
    });
    await _scanner.stop();

    await _buscarEquipo(code);
  }

  // ── Buscar en Firestore ─────────────────────────────────────────────
  Future<void> _buscarEquipo(String codigoQr) async {
    try {
      Map<String, dynamic>? equipoData;

      // 1. Buscar por doc ID directamente (el QR generado guarda el ID del documento)
      try {
        final docSnap = await FirebaseFirestore.instance
            .collection('equipos')
            .doc(codigoQr)
            .get();
        if (docSnap.exists) {
          equipoData = docSnap.data()!;
          equipoData['id'] = docSnap.id;
        }
      } catch (_) {}

      // 2. Buscar por campo codigoQR (R mayúscula, así se guarda desde admin)
      if (equipoData == null) {
        final snap = await FirebaseFirestore.instance
            .collection('equipos')
            .where('codigoQR', isEqualTo: codigoQr)
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) {
          equipoData = snap.docs.first.data();
          equipoData['id'] = snap.docs.first.id;
        }
      }

      // 3. Buscar por número de serie
      if (equipoData == null) {
        final snap = await FirebaseFirestore.instance
            .collection('equipos')
            .where('serie', isEqualTo: codigoQr)
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) {
          equipoData = snap.docs.first.data();
          equipoData['id'] = snap.docs.first.id;
        }
      }

      // 4. Buscar por nombre exacto (por si el QR contiene el nombre)
      if (equipoData == null) {
        final snap = await FirebaseFirestore.instance
            .collection('equipos')
            .where('nombre', isEqualTo: codigoQr)
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) {
          equipoData = snap.docs.first.data();
          equipoData['id'] = snap.docs.first.id;
        }
      }

      if (!mounted) return;
      setState(() => _searching = false);

      if (equipoData != null) {
        _mostrarEquipoEncontrado(equipoData, codigoQr);
      } else {
        // QR leído pero no está en Firestore → mostrar contenido igual
        _mostrarQrLeido(codigoQr);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _searching = false);
      _mostrarError();
    }
  }

  // ── BottomSheet: equipo encontrado ─────────────────────────────────
  void _mostrarEquipoEncontrado(Map<String, dynamic> equipo, String qr) {
    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Ícono + nombre
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.medical_services_outlined,
                      color: AppColors.accent, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        equipo['nombre'] ?? 'Equipo médico',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        equipo['area'] ?? equipo['ubicacion'] ?? '',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                _EstadoChip(estado: equipo['estado'] ?? 'Activo'),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),

            // Datos del equipo
            _InfoRow('Marca',  equipo['marca']  ?? '—'),
            _InfoRow('Modelo', equipo['modelo'] ?? '—'),
            _InfoRow('Serie',  equipo['serie']  ?? '—'),
            _InfoRow('Área',   equipo['area']   ?? equipo['ubicacion'] ?? '—'),

            const SizedBox(height: 24),

            // Acciones
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(
                    context,
                    AppRoutes.enfRegistrar,
                    arguments: {
                      'equipoPreseleccionado': equipo,
                      'usarOtroEquipo': false,
                    },
                  );
                },
                icon: const Icon(Icons.warning_amber_rounded, size: 20),
                label: const Text('Registrar Incidencia',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _reiniciarScanner();
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.divider),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Escanear otro equipo',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── BottomSheet: QR leído pero equipo no en Firestore ─────────────
  void _mostrarQrLeido(String qr) {
    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),

            // Ícono + título
            Row(children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.12),
                    shape: BoxShape.circle),
                child: const Icon(Icons.qr_code_2_rounded,
                    color: AppColors.accent, size: 28),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('QR leído correctamente',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary)),
                    Text('Código no registrado en el sistema',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ]),

            const SizedBox(height: 18),

            // Contenido del QR
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Contenido escaneado',
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  SelectableText(
                    qr,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
            const Text(
              'Este código QR no corresponde a ningún equipo registrado. Puedes registrar una incidencia manualmente.',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 12, height: 1.4),
            ),

            const SizedBox(height: 20),

            // Botón registrar incidencia
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(
                    context,
                    AppRoutes.enfRegistrar,
                    arguments: {'usarOtroEquipo': true, 'codigoQr': qr},
                  );
                },
                icon: const Icon(Icons.warning_amber_rounded, size: 20),
                label: const Text('Registrar Incidencia',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _reiniciarScanner();
                },
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                label: const Text('Escanear otro código',
                    style: TextStyle(color: AppColors.textSecondary)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.divider),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── BottomSheet: error de conexión ─────────────────────────────────
  void _mostrarError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Error de conexión. Verifica tu internet.'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'Reintentar',
          textColor: Colors.white,
          onPressed: _reiniciarScanner,
        ),
      ),
    );
    _reiniciarScanner();
  }

  Future<void> _reiniciarScanner() async {
    setState(() {
      _scanned   = false;
      _searching = false;
    });
    await _scanner.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Cámara ────────────────────────────────────────────────
          MobileScanner(
            controller: _scanner,
            onDetect: _onDetect,
          ),

          // ── Overlay oscuro con ventana QR ─────────────────────────
          _QrOverlay(),

          // ── AppBar flotante ───────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Botón volver
                  _CircleButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  // Linterna
                  _CircleButton(
                    icon: _torchOn
                        ? Icons.flash_on_rounded
                        : Icons.flash_off_rounded,
                    onTap: () {
                      _scanner.toggleTorch();
                      setState(() => _torchOn = !_torchOn);
                    },
                  ),
                  const SizedBox(width: 10),
                  // Cámara frontal/trasera
                  _CircleButton(
                    icon: Icons.flip_camera_ios_rounded,
                    onTap: () {
                      _scanner.switchCamera();
                      setState(() => _frontCam = !_frontCam);
                    },
                  ),
                ],
              ),
            ),
          ),

          // ── Título + instrucciones ────────────────────────────────
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 70),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Escanear Equipo',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Apunta el código QR del equipo médico',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.7), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Spinner de búsqueda ───────────────────────────────────
          if (_searching)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.accent),
                    SizedBox(height: 16),
                    Text(
                      'Buscando equipo...',
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),

          // ── Botón ingreso manual ───────────────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: TextButton.icon(
                  onPressed: _searching ? null : _mostrarIngresoManual,
                  icon: const Icon(Icons.keyboard_outlined,
                      color: Colors.white70, size: 18),
                  label: const Text(
                    'Ingresar código manualmente',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Ingreso manual de código ─────────────────────────────────────
  void _mostrarIngresoManual() {
    final ctrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Código del equipo'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Ingresa el código o serie',
            prefixIcon: const Icon(Icons.qr_code_2_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final code = ctrl.text.trim();
              if (code.isEmpty) return;
              Navigator.pop(ctx);
              setState(() {
                _scanned   = true;
                _searching = true;
              });
              _buscarEquipo(code);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Buscar'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  WIDGETS AUXILIARES
// ═══════════════════════════════════════════════════════════════════════

/// Overlay con ventana de escaneo
class _QrOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size   = MediaQuery.of(context).size;
    const box    = 250.0;
    final top    = (size.height - box) / 2;
    final left   = (size.width  - box) / 2;

    return CustomPaint(
      size: Size(size.width, size.height),
      painter: _OverlayPainter(
        scanWindow: Rect.fromLTWH(left, top, box, box),
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final Rect scanWindow;
  const _OverlayPainter({required this.scanWindow});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black54;

    // Oscurecer todo excepto la ventana
    canvas
      ..drawRect(Rect.fromLTWH(0, 0, size.width, scanWindow.top), paint)
      ..drawRect(
          Rect.fromLTWH(0, scanWindow.top, scanWindow.left, scanWindow.height),
          paint)
      ..drawRect(
          Rect.fromLTWH(scanWindow.right, scanWindow.top,
              size.width - scanWindow.right, scanWindow.height),
          paint)
      ..drawRect(
          Rect.fromLTWH(0, scanWindow.bottom, size.width,
              size.height - scanWindow.bottom),
          paint);

    // Borde turquesa de la ventana
    final border = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(
        RRect.fromRectAndRadius(scanWindow, const Radius.circular(16)),
        border);

    // Esquinas resaltadas
    final corner = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;
    const len = 24.0;
    final r   = scanWindow;
    // Top-left
    canvas
      ..drawLine(r.topLeft, r.topLeft.translate(len, 0), corner)
      ..drawLine(r.topLeft, r.topLeft.translate(0, len), corner)
      // Top-right
      ..drawLine(r.topRight, r.topRight.translate(-len, 0), corner)
      ..drawLine(r.topRight, r.topRight.translate(0, len), corner)
      // Bottom-left
      ..drawLine(r.bottomLeft, r.bottomLeft.translate(len, 0), corner)
      ..drawLine(r.bottomLeft, r.bottomLeft.translate(0, -len), corner)
      // Bottom-right
      ..drawLine(r.bottomRight, r.bottomRight.translate(-len, 0), corner)
      ..drawLine(r.bottomRight, r.bottomRight.translate(0, -len), corner);
  }

  @override
  bool shouldRepaint(_OverlayPainter old) => old.scanWindow != scanWindow;
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _CircleButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.black45,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            SizedBox(
              width: 68,
              child: Text(label,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                      fontSize: 14)),
            ),
          ],
        ),
      );
}

class _EstadoChip extends StatelessWidget {
  final String estado;
  const _EstadoChip({required this.estado});

  Color get _color {
    final e = estado.toLowerCase();
    if (e.contains('activo')) return AppColors.resolved;
    if (e.contains('mantenimiento')) return AppColors.pending;
    if (e.contains('fuera')) return AppColors.error;
    return AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          estado,
          style: TextStyle(
              color: _color, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      );
}
