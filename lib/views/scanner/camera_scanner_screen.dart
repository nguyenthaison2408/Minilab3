import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/expense_provider.dart';
import '../../services/ocr_service.dart';
import '../../services/receipt_parser.dart';
import 'review_receipt_screen.dart';

class CameraScannerScreen extends StatefulWidget {
  const CameraScannerScreen({super.key});

  @override
  State<CameraScannerScreen> createState() => _CameraScannerScreenState();
}

class _CameraScannerScreenState extends State<CameraScannerScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;
  bool _isProcessing = false;
  Offset? _focusPoint;

  late AnimationController _scanAnimController;
  late Animation<double> _scanLineAnimation;

  @override
  void initState() {
    super.initState();
    _initScannerAnimation();
    _initCamera();
  }

  void _initScannerAnimation() {
    _scanAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanLineAnimation = Tween<double>(begin: 0.1, end: 0.9).animate(
      CurvedAnimation(parent: _scanAnimController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        final backCamera = _cameras!.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => _cameras!.first,
        );

        _cameraController = CameraController(
          backCamera,
          ResolutionPreset.high,
          enableAudio: false,
        );

        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    try {
      final newMode = _isFlashOn ? FlashMode.off : FlashMode.torch;
      await _cameraController!.setFlashMode(newMode);
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
    } catch (e) {
      debugPrint('Error toggling flash: $e');
    }
  }

  Future<void> _handleFocusTap(TapDownDetails details, BoxConstraints constraints) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    final offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );

    setState(() {
      _focusPoint = details.localPosition;
    });

    try {
      await _cameraController!.setFocusPoint(offset);
      await _cameraController!.setExposurePoint(offset);
    } catch (_) {}

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _focusPoint = null;
        });
      }
    });
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isProcessing) {
      return;
    }

    try {
      setState(() => _isProcessing = true);
      final xFile = await _cameraController!.takePicture();
      await _processImageAndNavigate(xFile.path);
    } catch (e) {
      _showErrorSnackBar('Lỗi khi chụp ảnh: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final xFile = await picker.pickImage(source: ImageSource.gallery);
      if (xFile != null) {
        setState(() => _isProcessing = true);
        await _processImageAndNavigate(xFile.path);
      }
    } catch (e) {
      _showErrorSnackBar('Lỗi khi chọn ảnh: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _processImageAndNavigate(String imagePath) async {
    final expenseProvider = context.read<ExpenseProvider>();
    final cachedPath = await OcrService.cacheReceiptImage(imagePath);
    final ocrResult = await expenseProvider.scanReceipt(cachedPath);

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewReceiptScreen(
          imagePath: cachedPath,
          ocrResult: ocrResult,
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  void dispose() {
    _scanAnimController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Viewfinder or Fallback UI
            if (_isCameraInitialized && _cameraController != null)
              LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    onTapDown: (details) => _handleFocusTap(details, constraints),
                    child: SizedBox.expand(
                      child: CameraPreview(_cameraController!),
                    ),
                  );
                },
              )
            else
              _buildCameraUnavailablePlaceholder(),

            // Framing Crop Overlay & Laser Scan Line
            _buildCropOverlay(),

            // Tap Focus Indicator Ring
            if (_focusPoint != null)
              Positioned(
                left: _focusPoint!.dx - 30,
                top: _focusPoint!.dy - 30,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.accent, width: 2),
                  ),
                ),
              ),

            // Top Control Bar: Back, Flash, Title
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Quét Hoá Đơn',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isFlashOn ? Icons.flash_on : Icons.flash_off,
                      color: _isFlashOn ? Colors.amber : Colors.white,
                    ),
                    onPressed: _isCameraInitialized ? _toggleFlash : null,
                  ),
                ],
              ),
            ),

            // Bottom Action Controls
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  const Text(
                    'Căn chỉnh hoá đơn bên trong khung viền',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Gallery Picker Button
                      IconButton(
                        icon: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 30),
                        tooltip: 'Chọn ảnh từ thư viện',
                        onPressed: _isProcessing ? null : _pickFromGallery,
                      ),

                      // Shutter Capture Button
                      GestureDetector(
                        onTap: _isProcessing ? null : _takePicture,
                        child: Container(
                          width: 74,
                          height: 74,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            color: _isProcessing ? AppColors.accent : Colors.white24,
                          ),
                          child: Center(
                            child: _isProcessing
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Container(
                                    width: 56,
                                    height: 56,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),

                      // Preset Test Receipt Button (Extremely helpful for testing/evaluation)
                      IconButton(
                        icon: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 30),
                        tooltip: 'Thử hoá đơn mẫu',
                        onPressed: _isProcessing ? null : _openPresetSelector,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCropOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.maxWidth * 0.85;
        final boxHeight = constraints.maxHeight * 0.65;
        final left = (constraints.maxWidth - boxWidth) / 2;
        final top = (constraints.maxHeight - boxHeight) / 2 - 20;

        return Stack(
          children: [
            // Darkened outer mask
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.55),
                BlendMode.srcOut,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  Positioned(
                    left: left,
                    top: top,
                    width: boxWidth,
                    height: boxHeight,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Framing border
            Positioned(
              left: left,
              top: top,
              width: boxWidth,
              height: boxHeight,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.accent, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),

            // Animated Scanning Laser Line
            AnimatedBuilder(
              animation: _scanLineAnimation,
              builder: (context, child) {
                return Positioned(
                  left: left + 8,
                  top: top + (boxHeight * _scanLineAnimation.value),
                  width: boxWidth - 16,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withOpacity(0.8),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildCameraUnavailablePlaceholder() {
    return Container(
      color: AppColors.background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.camera_alt_outlined, size: 64, color: AppColors.accent),
              const SizedBox(height: 16),
              const Text(
                'Camera đang chuẩn bị hoặc không khả dụng',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bạn có thể chọn ảnh hoá đơn từ thư viện ảnh hoặc dùng mẫu hoá đơn test bên dưới.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _pickFromGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text('Chọn ảnh từ máy'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openPresetSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chọn mẫu hoá đơn mô phỏng',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Dành cho kiểm thử OCR Heuristic khi không có hoá đơn giấy vật lý bên cạnh:',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 16),
              _buildPresetTile(
                title: 'Hoá đơn WinMart+ (Thực phẩm)',
                subtitle: 'Tổng: 185.000 đ • Ngày: 15/10/2026',
                icon: Icons.shopping_basket,
                sampleText: '''WINMART+ CONG HOA
Địa chỉ: 123 Cong Hoa, Tan Binh, HCM
Tel: 028.38123456
HD số: 0092837
Ngày: 15/10/2026 14:30
-------------------------------
Sữa chua Vinamilk      35.000
Bánh mì Sandwich       22.000
Trái cây nhập khẩu    128.000
-------------------------------
TỔNG CỘNG: 185.000 đ
Tiền mặt: 200.000 đ
Tiền thối: 15.000 đ
Cảm ơn quý khách!''',
              ),
              _buildPresetTile(
                title: 'Hoá đơn Highlands Coffee',
                subtitle: 'Total: 75,000 VND • Date: 12-10-2026',
                icon: Icons.coffee,
                sampleText: '''HIGHLANDS COFFEE
Chi nhanh: Landmark 81
Date: 12-10-2026 09:15
Order #104
-------------------------------
1 Phin Sua Da (L)       45,000
1 Banh Mi Thit Nuong    30,000
-------------------------------
TOTAL: 75,000 VND
Payment: Momo
Thank you and see you again!''',
              ),
              _buildPresetTile(
                title: 'Hoá đơn Nhà sách Fahasa',
                subtitle: 'Thành tiền: 245.000 đ • Ngày: 08/10/2026',
                icon: Icons.book,
                sampleText: '''NHA SACH FAHASA
D/c: Nguyen Hue, Quan 1, TP.HCM
Ngay: 08/10/2026 16:45
-------------------------------
Giao trinh Flutter 3   180.000
So tay ghi chu          65.000
-------------------------------
THÀNH TIỀN: 245.000 đ
Khach da tra: 245.000 đ
Chuc ban hoc tot!''',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPresetTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required String sampleText,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppColors.primaryLight.withOpacity(0.2),
        child: Icon(icon, color: AppColors.accent, size: 20),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 14),
      onTap: () {
        Navigator.pop(context);
        final lines = sampleText.split('\n');
        final ocrModel = ReceiptParser.parse(sampleText, lines);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReviewReceiptScreen(
              imagePath: null,
              ocrResult: ocrModel,
            ),
          ),
        );
      },
    );
  }
}

