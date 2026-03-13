import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({Key? key}) : super(key: key);

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen>
    with TickerProviderStateMixin {
  MobileScannerController? _controller;
  bool _isScanning = true;
  bool _torchEnabled = false;
  String? _errorMessage;

  late AnimationController _scanLineController;
  late AnimationController _pulseController;
  late AnimationController _cornerController;
  late Animation<double> _scanLineAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _cornerAnimation;

  @override
  void initState() {
    super.initState();
    _initializeScanner();
    _initializeAnimations();
  }

  void _initializeScanner() {
    try {
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize camera: $e';
      });
    }
  }

  void _initializeAnimations() {
    // Scanning line animation
    _scanLineController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat();

    _scanLineAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _scanLineController,
        curve: Curves.easeInOut,
      ),
    );

    // Pulse animation for corners
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Corner bracket animation
    _cornerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _cornerAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _cornerController,
        curve: Curves.elasticOut,
      ),
    );

    _cornerController.forward();
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    _pulseController.dispose();
    _cornerController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? scannedValue = barcodes.first.rawValue;

    if (scannedValue != null && scannedValue.isNotEmpty) {
      setState(() {
        _isScanning = false;
      });

      // Success animation
      _scanLineController.stop();
      _pulseController.stop();

      // Return after short delay for visual feedback
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          Navigator.pop(context, scannedValue);
        }
      });
    }
  }

  void _toggleTorch() {
    setState(() {
      _torchEnabled = !_torchEnabled;
    });
    _controller?.toggleTorch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _errorMessage != null ? _buildErrorView() : _buildScannerView(),
    );
  }

  Widget _buildErrorView() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A237E),
            Colors.black,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TweenAnimationBuilder(
                  duration: const Duration(milliseconds: 600),
                  tween: Tween<double>(begin: 0, end: 1),
                  builder: (context, double value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Opacity(
                        opacity: value,
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      size: 72,
                      color: Color(0xFFEF5350),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Camera Error',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _errorMessage ?? 'Unknown error',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                _buildActionButton(
                  'Retry',
                  Icons.refresh_rounded,
                  () {
                    setState(() {
                      _errorMessage = null;
                    });
                    _initializeScanner();
                  },
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  'Go Back',
                  Icons.arrow_back_rounded,
                  () => Navigator.pop(context),
                  isPrimary: false,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onPressed,
      {bool isPrimary = true}) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: isPrimary
            ? const LinearGradient(
                colors: [Color(0xFF5C6BC0), Color(0xFF3949AB)],
              )
            : null,
        color: isPrimary ? null : Colors.white.withOpacity(0.1),
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: Icon(icon, size: 22),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildScannerView() {
    if (_controller == null) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1A237E),
              Colors.black,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            strokeWidth: 3,
          ),
        ),
      );
    }

    return Stack(
      children: [
        // Camera view
        MobileScanner(
          controller: _controller,
          onDetect: _onDetect,
        ),

        // Dark overlay
        Container(
          color: Colors.black.withOpacity(0.5),
        ),

        // Main content
        SafeArea(
          child: Column(
            children: [
              // Top bar
              _buildTopBar(),

              const Spacer(),

              // Scan area
              _buildScanArea(),

              const Spacer(),

              // Bottom instructions
              _buildBottomInstructions(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          TweenAnimationBuilder(
            duration: const Duration(milliseconds: 400),
            tween: Tween<double>(begin: 0, end: 1),
            builder: (context, double value, child) {
              return Transform.translate(
                offset: Offset(-20 * (1 - value), 0),
                child: Opacity(opacity: value, child: child),
              );
            },
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),

          // Title
          TweenAnimationBuilder(
            duration: const Duration(milliseconds: 500),
            tween: Tween<double>(begin: 0, end: 1),
            builder: (context, double value, child) {
              return Opacity(opacity: value, child: child);
            },
            child: const Text(
              'Scan QR Code',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),

          // Flashlight button
          TweenAnimationBuilder(
            duration: const Duration(milliseconds: 400),
            tween: Tween<double>(begin: 0, end: 1),
            builder: (context, double value, child) {
              return Transform.translate(
                offset: Offset(20 * (1 - value), 0),
                child: Opacity(opacity: value, child: child),
              );
            },
            child: GestureDetector(
              onTap: _toggleTorch,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _torchEnabled
                      ? const Color(0xFFFFA726).withOpacity(0.2)
                      : Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _torchEnabled
                        ? const Color(0xFFFFA726)
                        : Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  _torchEnabled
                      ? Icons.flash_on_rounded
                      : Icons.flash_off_rounded,
                  color: _torchEnabled ? const Color(0xFFFFA726) : Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanArea() {
    const scanAreaSize = 280.0;

    return SizedBox(
      width: scanAreaSize,
      height: scanAreaSize,
      child: Stack(
        children: [
          // Transparent center
          Center(
            child: Container(
              width: scanAreaSize,
              height: scanAreaSize,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),

          // Animated scanning line
          AnimatedBuilder(
            animation: _scanLineAnimation,
            builder: (context, child) {
              return Positioned(
                top: _scanLineAnimation.value * (scanAreaSize - 4),
                left: 0,
                right: 0,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        const Color(0xFF66BB6A).withOpacity(0.8),
                        const Color(0xFF66BB6A),
                        const Color(0xFF66BB6A).withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF66BB6A).withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Corner brackets with pulse animation
          ..._buildCornerBrackets(scanAreaSize),

          // Center indicator
          Center(
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCornerBrackets(double size) {
    const bracketLength = 50.0;
    const bracketWidth = 5.0;
    const offset = 0.0;

    return [
      // Top-left
      Positioned(
        top: offset,
        left: offset,
        child: AnimatedBuilder(
          animation: _cornerAnimation,
          builder: (context, child) {
            return AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _pulseAnimation.value,
                  child: Transform.scale(
                    scale: _cornerAnimation.value,
                    alignment: Alignment.topLeft,
                    child: CustomPaint(
                      size: const Size(bracketLength, bracketLength),
                      painter: CornerBracketPainter(
                        color: Colors.white,
                        strokeWidth: bracketWidth,
                        isTopLeft: true,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),

      // Top-right
      Positioned(
        top: offset,
        right: offset,
        child: AnimatedBuilder(
          animation: _cornerAnimation,
          builder: (context, child) {
            return AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _pulseAnimation.value,
                  child: Transform.scale(
                    scale: _cornerAnimation.value,
                    alignment: Alignment.topRight,
                    child: CustomPaint(
                      size: const Size(bracketLength, bracketLength),
                      painter: CornerBracketPainter(
                        color: Colors.white,
                        strokeWidth: bracketWidth,
                        isTopRight: true,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),

      // Bottom-left
      Positioned(
        bottom: offset,
        left: offset,
        child: AnimatedBuilder(
          animation: _cornerAnimation,
          builder: (context, child) {
            return AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _pulseAnimation.value,
                  child: Transform.scale(
                    scale: _cornerAnimation.value,
                    alignment: Alignment.bottomLeft,
                    child: CustomPaint(
                      size: const Size(bracketLength, bracketLength),
                      painter: CornerBracketPainter(
                        color: Colors.white,
                        strokeWidth: bracketWidth,
                        isBottomLeft: true,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),

      // Bottom-right
      Positioned(
        bottom: offset,
        right: offset,
        child: AnimatedBuilder(
          animation: _cornerAnimation,
          builder: (context, child) {
            return AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _pulseAnimation.value,
                  child: Transform.scale(
                    scale: _cornerAnimation.value,
                    alignment: Alignment.bottomRight,
                    child: CustomPaint(
                      size: const Size(bracketLength, bracketLength),
                      painter: CornerBracketPainter(
                        color: Colors.white,
                        strokeWidth: bracketWidth,
                        isBottomRight: true,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    ];
  }

  Widget _buildBottomInstructions() {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 600),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF5C6BC0).withOpacity(0.9),
              const Color(0xFF3949AB).withOpacity(0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5C6BC0).withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.qr_code_2_rounded,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(height: 12),
            const Text(
              'Position QR code within frame',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Scanning will happen automatically',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 13,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for corner brackets
class CornerBracketPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final bool isTopLeft;
  final bool isTopRight;
  final bool isBottomLeft;
  final bool isBottomRight;

  CornerBracketPainter({
    required this.color,
    required this.strokeWidth,
    this.isTopLeft = false,
    this.isTopRight = false,
    this.isBottomLeft = false,
    this.isBottomRight = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();

    if (isTopLeft) {
      path.moveTo(size.width, 0);
      path.lineTo(strokeWidth / 2, 0);
      path.lineTo(strokeWidth / 2, size.height);
    } else if (isTopRight) {
      path.moveTo(0, 0);
      path.lineTo(size.width - strokeWidth / 2, 0);
      path.lineTo(size.width - strokeWidth / 2, size.height);
    } else if (isBottomLeft) {
      path.moveTo(strokeWidth / 2, 0);
      path.lineTo(strokeWidth / 2, size.height - strokeWidth / 2);
      path.lineTo(size.width, size.height - strokeWidth / 2);
    } else if (isBottomRight) {
      path.moveTo(size.width - strokeWidth / 2, 0);
      path.lineTo(size.width - strokeWidth / 2, size.height - strokeWidth / 2);
      path.lineTo(0, size.height - strokeWidth / 2);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
