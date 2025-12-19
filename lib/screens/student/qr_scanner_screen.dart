import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

/// QR Code Scanner Screen for joining schools and classrooms
class QrScannerScreen extends StatefulWidget {
  final bool scanOnly; // If true, only return code without joining
  
  const QrScannerScreen({super.key, this.scanOnly = false});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleQrCode(String data) async {
    if (_isProcessing) return;
    
    setState(() => _isProcessing = true);

    try {
      // Parse QR code data
      final Map<String, dynamic> qrData = jsonDecode(data);
      final type = qrData['type'] as String?;
      final code = qrData['code'] as String?;
      final name = qrData['name'] as String?;

      if (type == null || code == null) {
        throw Exception('Invalid QR code format');
      }

      // If scanOnly mode, just return the code without joining
      if (widget.scanOnly) {
        if (mounted) {
          Navigator.pop(context, {'type': type, 'code': code, 'name': name});
        }
        return;
      }

      // Otherwise, auto-join
      if (type == 'school') {
        await _joinSchool(code, name ?? 'Unknown School');
      } else if (type == 'classroom') {
        await _joinClassroom(code, name ?? 'Unknown Classroom');
      } else {
        throw Exception('Unknown QR code type: $type');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _joinSchool(String schoolCode, String schoolName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('You must be logged in to join a school');
    }

    // Find school by code
    final schoolQuery = await FirebaseFirestore.instance
        .collection('schools')
        .where('schoolCode', isEqualTo: schoolCode.toUpperCase())
        .limit(1)
        .get();

    if (schoolQuery.docs.isEmpty) {
      throw Exception('School not found with code: $schoolCode');
    }

    final schoolDoc = schoolQuery.docs.first;
    final schoolId = schoolDoc.id;

    // Update user's school
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({
      'schoolId': schoolId,
      'schoolName': schoolDoc.data()['name'],
    });

    if (mounted) {
      Navigator.pop(context, {'type': 'school', 'id': schoolId});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully joined $schoolName!'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  Future<void> _joinClassroom(String classroomCode, String classroomName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('You must be logged in to join a classroom');
    }

    // Find classroom by code
    final classroomQuery = await FirebaseFirestore.instance
        .collection('classrooms')
        .where('classCode', isEqualTo: classroomCode.toUpperCase())
        .limit(1)
        .get();

    if (classroomQuery.docs.isEmpty) {
      throw Exception('Classroom not found with code: $classroomCode');
    }

    final classroomDoc = classroomQuery.docs.first;
    final classroomId = classroomDoc.id;
    final classroomData = classroomDoc.data();

    // Check if already in classroom
    final studentIds = List<String>.from(classroomData['studentIds'] ?? []);
    if (studentIds.contains(user.uid)) {
      throw Exception('You are already in this classroom');
    }

    // Add student to classroom
    await FirebaseFirestore.instance
        .collection('classrooms')
        .doc(classroomId)
        .update({
      'studentIds': FieldValue.arrayUnion([user.uid]),
    });

    // Update user's classrooms
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({
      'classroomIds': FieldValue.arrayUnion([classroomId]),
    });

    if (mounted) {
      Navigator.pop(context, {'type': 'classroom', 'id': classroomId});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully joined $classroomName!'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  Future<void> _pickImageAndScan() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image == null) return;

      setState(() => _isProcessing = true);

      // Analyze the image for QR code
      final BarcodeCapture? capture = await _controller.analyzeImage(image.path);
      
      if (capture != null && capture.barcodes.isNotEmpty) {
        final barcode = capture.barcodes.first;
        if (barcode.rawValue != null) {
          await _handleQrCode(barcode.rawValue!);
        } else {
          throw Exception('No QR code data found in image');
        }
      } else {
        throw Exception('No QR code found in image');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6B46C1), Color(0xFF9333EA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        foregroundColor: Colors.white,
        title: const Text(
          'Scan QR Code',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library, color: Colors.white),
            onPressed: _pickImageAndScan,
            tooltip: 'Pick from gallery',
          ),
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.white),
            onPressed: () => _controller.toggleTorch(),
            tooltip: 'Toggle flash',
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
            onPressed: () => _controller.switchCamera(),
            tooltip: 'Flip camera',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera view
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _handleQrCode(barcode.rawValue!);
                  break;
                }
              }
            },
          ),

          // Overlay with scanning area
          CustomPaint(
            painter: ScannerOverlayPainter(),
            child: Container(),
          ),

          // Instructions
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.qr_code_scanner,
                    size: 48,
                    color: Color(0xFF8B5CF6),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Position QR code within the frame',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Scanning will happen automatically',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Processing indicator
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: Color(0xFF8B5CF6),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Processing...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Custom painter for scanner overlay
class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final scanAreaSize = size.width * 0.7;
    final left = (size.width - scanAreaSize) / 2;
    final top = (size.height - scanAreaSize) / 2;

    // Draw semi-transparent overlay
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize),
        const Radius.circular(20),
      ))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Draw corner brackets
    final cornerPaint = Paint()
      ..color = const Color(0xFF8B5CF6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final cornerLength = 30.0;

    // Top-left
    canvas.drawLine(
      Offset(left, top + cornerLength),
      Offset(left, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left, top),
      Offset(left + cornerLength, top),
      cornerPaint,
    );

    // Top-right
    canvas.drawLine(
      Offset(left + scanAreaSize - cornerLength, top),
      Offset(left + scanAreaSize, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + scanAreaSize, top),
      Offset(left + scanAreaSize, top + cornerLength),
      cornerPaint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(left, top + scanAreaSize - cornerLength),
      Offset(left, top + scanAreaSize),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left, top + scanAreaSize),
      Offset(left + cornerLength, top + scanAreaSize),
      cornerPaint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(left + scanAreaSize - cornerLength, top + scanAreaSize),
      Offset(left + scanAreaSize, top + scanAreaSize),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + scanAreaSize, top + scanAreaSize - cornerLength),
      Offset(left + scanAreaSize, top + scanAreaSize),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
