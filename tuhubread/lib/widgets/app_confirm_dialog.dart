import 'package:flutter/material.dart';

/// Kiểu màu cho nút xác nhận.
enum ConfirmDialogType {
  danger,
  warning,
  success,
  info,
}

/// Dialog xác nhận tái sử dụng — layout giống StatusDialog:
///
/// ```
///     [  image widget  ]    ← nổi tự nhiên lên trên card (Positioned top: 0)
/// ╭────────────────────╮
/// │   (khoảng cho ảnh) │   ← margin top: 100, padding top: 50
/// │      Title bold    │
/// │   description text │
/// ╰────────────────────╯
///
///  [ Huỷ ]   [ Xác nhận ]  ← buttons NGOÀI card
/// ```
///
/// **Cách dùng:**
/// ```dart
/// await AppConfirmDialog.show(
///   context,
///   type: ConfirmDialogType.danger,
///   image: Image.asset('assets/images/robot.png', height: 180),
///   title: 'Xóa sản phẩm?',
///   description: 'Bạn có chắc muốn xóa khỏi giỏ hàng không?',
///   confirmTitle: 'Xóa',
///   cancelTitle: 'Huỷ',
///   onConfirm: () { /* xử lý */ },
/// );
/// ```
class AppConfirmDialog extends StatelessWidget {
  final ConfirmDialogType type;
  final String title;
  final String description;
  final String confirmTitle;
  final String cancelTitle;

  /// Widget ảnh — Image.asset, Image.network, Lottie... Tuỳ ý.
  /// Nếu null thì card không có khoảng trống phía trên.
  final Widget? image;

  /// Callback sau khi dialog đóng và người dùng nhấn xác nhận.
  final VoidCallback? onConfirm;

  const AppConfirmDialog({
    super.key,
    required this.type,
    required this.title,
    required this.description,
    this.confirmTitle = 'Xác nhận',
    this.cancelTitle = 'Huỷ',
    this.image,
    this.onConfirm,
  });

  // ─── Màu theo type ────────────────────────────────────────────────────────

  Color get _confirmColor => switch (type) {
        ConfirmDialogType.danger  => const Color(0xFFE74C3C),
        ConfirmDialogType.warning => const Color(0xFFE67E22),
        ConfirmDialogType.success => const Color(0xFF27AE60),
        ConfirmDialogType.info    => const Color(0xFF2980B9),
      };

  // ─── Show helper ──────────────────────────────────────────────────────────

  static Future<bool?> show(
    BuildContext context, {
    required ConfirmDialogType type,
    required String title,
    required String description,
    String confirmTitle = 'Xác nhận',
    String cancelTitle = 'Huỷ',
    Widget? image,
    VoidCallback? onConfirm,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (_) => AppConfirmDialog(
        type: type,
        title: title,
        description: description,
        confirmTitle: confirmTitle,
        cancelTitle: cancelTitle,
        image: image,
        onConfirm: onConfirm,
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final hasImage = image != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Stack: card + ảnh nổi ─────────────────────────────────
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(top: hasImage ? 100 : 0),
                    padding: EdgeInsets.fromLTRB(
                      20,
                      hasImage ? 60 : 32,
                      20,
                      32,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF7F8C8D),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasImage) Positioned(top: 0, child: image!),
                ],
              ),

              const SizedBox(height: 20),

              // ── Buttons — ngoài card ──────────────────────────────────
              Row(
                children: [
                  // Huỷ: outline
                  Expanded(
                    child: _OutlineBtn(
                      label: cancelTitle,
                      onTap: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Xác nhận: gradient filled
                  Expanded(
                    child: _GradientBtn(
                      label: confirmTitle,
                      color: _confirmColor,
                      onTap: () {
                        Navigator.of(context).pop(true);
                        onConfirm?.call();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Private buttons ─────────────────────────────────────────────────────────

class _OutlineBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _OutlineBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF7F8C8D),
          side: const BorderSide(color: Color(0xFFCBD5E0), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class _GradientBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _GradientBtn({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color,
              Color.lerp(color, Colors.orange, 0.3) ?? color,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}
