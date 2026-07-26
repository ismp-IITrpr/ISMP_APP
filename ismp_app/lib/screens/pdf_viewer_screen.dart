import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../theme/app_theme.dart';

class PdfViewerScreen extends StatefulWidget {
  final String pdfAssetPath;
  final String title;

  const PdfViewerScreen({
    super.key,
    required this.pdfAssetPath,
    required this.title,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  Uint8List? _pdfBytes;
  bool _isLoading = true;
  String? _error;
  PdfInteractionMode _interactionMode = PdfInteractionMode.pan; // Default to smooth scroll/pan

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      final ByteData data = await rootBundle.load(widget.pdfAssetPath);
      setState(() {
        _pdfBytes = data.buffer.asUint8List();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.backgroundGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(widget.title, style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            if (!_isLoading && _error == null)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  icon: Icon(
                    _interactionMode == PdfInteractionMode.pan
                        ? Icons.back_hand // Hand icon for scroll mode
                        : Icons.text_fields, // Text selection icon
                    color: Colors.white,
                  ),
                  tooltip: _interactionMode == PdfInteractionMode.pan
                      ? 'Switch to Text Selection'
                      : 'Switch to Smooth Scroll',
                  onPressed: () {
                    setState(() {
                      _interactionMode = _interactionMode == PdfInteractionMode.pan
                          ? PdfInteractionMode.selection
                          : PdfInteractionMode.pan;
                    });
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _interactionMode == PdfInteractionMode.pan
                              ? 'Scroll Mode Activated (Smooth)'
                              : 'Text Selection Mode Activated',
                        ),
                        duration: const Duration(seconds: 1),
                        backgroundColor: AppColors.surface,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Failed to load asset: $_error',
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : SfPdfViewer.memory(
                    _pdfBytes!,
                    interactionMode: _interactionMode,
                    canShowScrollHead: false,
                    canShowScrollStatus: false,
                    onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error rendering PDF: ${details.description}')),
                      );
                    },
                  ),
      ),
    );
  }
}
