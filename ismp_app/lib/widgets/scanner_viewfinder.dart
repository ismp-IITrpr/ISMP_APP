import 'package:flutter/material.dart';

class ScannerViewfinder extends StatefulWidget {
  final VoidCallback onScanComplete;
  final VoidCallback onCancel;

  const ScannerViewfinder({
    super.key,
    required this.onScanComplete,
    required this.onCancel,
  });

  @override
  State<ScannerViewfinder> createState() => _ScannerViewfinderState();
}

class _ScannerViewfinderState extends State<ScannerViewfinder>
    with SingleTickerProviderStateMixin {
  late AnimationController _laserController;
  late Animation<double> _laserAnimation;

  @override
  void initState() {
    super.initState();

    _laserController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _laserController, curve: Curves.easeInOut),
    );

    // Auto-trigger completion after 3 seconds of scanning
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        widget.onScanComplete();
      }
    });
  }

  @override
  void dispose() {
    _laserController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scannerSize = size.width * 0.65;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: double.infinity,
        height: size.height * 0.6,
        decoration: BoxDecoration(
          color: const Color(0xFF0F0920).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: const Color(0xFF1F1635), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Close Button
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: widget.onCancel,
              ),
            ),

            // Main Scanner Layout
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.qr_code_scanner,
                  color: Color(0xFFD9278D),
                  size: 40,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Scanning QR Code',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Simulating camera viewfinder...',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 32),

                // Viewfinder Frame
                SizedBox(
                  width: scannerSize,
                  height: scannerSize,
                  child: Stack(
                    children: [
                      // Viewfinder corner borders
                      Positioned.fill(
                        child: CustomPaint(
                          painter: ViewfinderCornerPainter(
                            color: const Color(0xFFD9278D),
                            strokeWidth: 4.0,
                          ),
                        ),
                      ),

                      // Scanning Laser Line
                      AnimatedBuilder(
                        animation: _laserAnimation,
                        builder: (context, child) {
                          final topOffset = _laserAnimation.value * (scannerSize - 4);
                          return Positioned(
                            top: topOffset,
                            left: 8,
                            right: 8,
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF2450),
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF2450).withValues(alpha: 0.8),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Keep the QR code steady inside the frame',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Painter to draw bracket corners for the QR scanner viewfinder
class ViewfinderCornerPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  ViewfinderCornerPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLength = 24.0;
    const offset = 2.0;

    // Top-Left Corner
    canvas.drawPath(
      Path()
        ..moveTo(offset, cornerLength + offset)
        ..lineTo(offset, offset)
        ..lineTo(cornerLength + offset, offset),
      paint,
    );

    // Top-Right Corner
    canvas.drawPath(
      Path()
        ..moveTo(size.width - offset - cornerLength, offset)
        ..lineTo(size.width - offset, offset)
        ..lineTo(size.width - offset, cornerLength + offset),
      paint,
    );

    // Bottom-Left Corner
    canvas.drawPath(
      Path()
        ..moveTo(offset, size.height - offset - cornerLength)
        ..lineTo(offset, size.height - offset)
        ..lineTo(cornerLength + offset, size.height - offset),
      paint,
    );

    // Bottom-Right Corner
    canvas.drawPath(
      Path()
        ..moveTo(size.width - offset - cornerLength, size.height - offset)
        ..lineTo(size.width - offset, size.height - offset)
        ..lineTo(size.width - offset, size.height - offset - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
