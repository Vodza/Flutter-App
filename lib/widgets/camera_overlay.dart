import 'package:flutter/material.dart';

class CameraOverlay extends StatelessWidget {
  final VoidCallback onCapture;
  final VoidCallback onPickGallery;
  final VoidCallback onToggleFlash;
  final bool isFlashOn;

  const CameraOverlay({
    super.key,
    required this.onCapture,
    required this.onPickGallery,
    required this.onToggleFlash,
    required this.isFlashOn,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;

        // Tỷ lệ khung hóa đơn (chuẩn khổ giấy biên lai dọc)
        final boxWidth = screenWidth * 0.85;
        final boxHeight = screenHeight * 0.62;
        final left = (screenWidth - boxWidth) / 2;
        final top = (screenHeight - boxHeight) / 2.3;

        return Stack(
          children: [
            // Lớp phủ làm tối xung quanh viền ngoài khung ngắm
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.55),
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

            // Viền khung ngắm & góc bo căn chỉnh hóa đơn
            Positioned(
              left: left,
              top: top,
              width: boxWidth,
              height: boxHeight,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF38BDF8), width: 2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.crop_free, color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Căn chỉnh hóa đơn vào khung',
                              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox.shrink(),
                  ],
                ),
              ),
            ),

            // Nút điều khiển trên cùng (Đóng, Bật Flash)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.black.withValues(alpha: 0.5),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  CircleAvatar(
                    backgroundColor: Colors.black.withValues(alpha: 0.5),
                    child: IconButton(
                      icon: Icon(
                        isFlashOn ? Icons.flash_on : Icons.flash_off,
                        color: isFlashOn ? Colors.amber : Colors.white,
                      ),
                      onPressed: onToggleFlash,
                    ),
                  ),
                ],
              ),
            ),

            // Thanh công cụ chụp ảnh bên dưới
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Nút mở thư viện ảnh
                  IconButton(
                    iconSize: 32,
                    icon: const Icon(Icons.photo_library_outlined, color: Colors.white),
                    onPressed: onPickGallery,
                  ),

                  // Nút chụp to ở giữa
                  GestureDetector(
                    onTap: onCapture,
                    child: Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: const Icon(Icons.camera_alt, color: Color(0xFF0F172A), size: 30),
                      ),
                    ),
                  ),

                  // Khoảng trống cân đối
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
