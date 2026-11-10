import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/i18n.dart';
import '../../models/models.dart';

/// Camera that reads the QR on the cart screen (link or pay) and returns it.
class ScanCartPage extends StatefulWidget {
  const ScanCartPage({super.key, this.forPayment = false});

  /// Opened from "Pay with the cart QR".
  final bool forPayment;

  @override
  State<ScanCartPage> createState() => _ScanCartPageState();
}

class _ScanCartPageState extends State<ScanCartPage> {
  final MobileScannerController _controller = MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates);
  bool _done = false;
  String? _lastRead;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    for (final barcode in capture.barcodes) {
      final qr = parseCartQr(barcode.rawValue);
      if (qr != null) {
        _done = true;
        Navigator.of(context).pop(qr);
        return;
      }
      setState(() => _lastRead = barcode.rawValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(context.tr(widget.forPayment ? 'scan.titlePay' : 'scan.title')),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.flash_on), onPressed: () => _controller.toggleTorch()),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 40,
            child: Text(
              context.tr(_lastRead != null ? 'scan.notCart' : widget.forPayment ? 'scan.hintPay' : 'scan.hint'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
