import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/attendance_service.dart';
import '../services/database_service.dart';

class StudentScannerScreen extends StatefulWidget {
  final String studentId;

  const StudentScannerScreen({super.key, required this.studentId});

  @override
  State<StudentScannerScreen> createState() => _StudentScannerScreenState();
}

class _StudentScannerScreenState extends State<StudentScannerScreen> {
  final MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return; // Prevent multiple scans at once

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final String scannedCode = barcodes.first.rawValue!;
      
      setState(() {
        _isProcessing = true;
      });

      final String rawCode = scannedCode.trim();
      final parts = rawCode.split(':');
      
      if (parts.length != 2) {
        cameraController.stop();
        _showFailedDialog('Invalid QR code format.');
        return;
      }
      
      final String sessionId = parts[0];
      final int scannedTimeBlock = int.tryParse(parts[1]) ?? 0;
      final int currentTimeBlock = DateTime.now().millisecondsSinceEpoch ~/ 30000;
      
      // Allow current block or the previous block (to account for a few seconds of network/scan delay)
      if (scannedTimeBlock != currentTimeBlock && scannedTimeBlock != (currentTimeBlock - 1)) {
        cameraController.stop();
        _showFailedDialog('QR code has expired. Please scan the newly generated code.');
        return;
      }

      // Stop camera while processing and showing dialog
      cameraController.stop();

      bool success = false;
      String errorMessage = 'Unable to mark attendance.\nPlease try again.';

      try {
        final userProfile = await DatabaseService().getUserProfile(widget.studentId);
        final studentName = userProfile?.name ?? "Student";
        
        await AttendanceService().scanQR(sessionId, widget.studentId, studentName);
        success = true;
      } catch (e) {
        debugPrint('Error marking attendance: $e');
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      }

      if (success) {
        _showSuccessDialog();
      } else {
        _showFailedDialog(errorMessage);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildResultDialog(
        isSuccess: true,
        icon: Icons.check_circle_outline,
        iconColor: const Color(0xFFD9278D),
        title: 'Success!',
        message: 'Your attendance has been\nmarked successfully.',
        buttonText: 'Great!',
      ),
    );
  }

  void _showFailedDialog([String? message]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildResultDialog(
        isSuccess: false,
        icon: Icons.cancel_outlined,
        iconColor: const Color(0xFFFF2450),
        title: 'Failed!',
        message: message ?? 'The attendance window for this event has closed (2-minute limit).',
        buttonText: 'Go Back',
      ),
    );
  }

  Widget _buildResultDialog({
    required bool isSuccess,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required String buttonText,
  }) {
    return Dialog(
      backgroundColor: const Color(0xFF1F1635),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Icon(
              icon,
              size: 80,
              color: iconColor,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to attendance screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD9278D),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Event QR'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: _onDetect,
          ),
          // A scanning overlay frame
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFD9278D), width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Text(
              'Align the Event QR Code within the frame',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}
