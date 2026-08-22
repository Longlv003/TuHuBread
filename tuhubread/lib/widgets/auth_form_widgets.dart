import 'package:flutter/material.dart';

import '../core/app_tokens.dart';

/// Màu nền phần đầu tối của màn Đăng nhập / Đăng ký.
const _authHeaderColor = Color(0xFF16162B);
const _authFieldFill = Color(0xFFF4F5F7);
const _authLabelColor = Color(0xFF9AA0A6);

/// Bố cục chung cho màn Đăng nhập / Đăng ký: nửa trên nền tối có nút quay lại
/// + tiêu đề, nửa dưới là tấm nền trắng bo góc trên chứa form.
class AuthScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  /// Có hiện nút quay lại ở góc trái không (màn Đăng nhập là màn gốc nên
  /// không có gì để quay về).
  final VoidCallback? onBack;

  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _authHeaderColor,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 26),
              child: Column(
                children: [
                  SizedBox(
                    height: 40,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: onBack == null
                          ? null
                          : Material(
                              color: Colors.white,
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: onBack,
                                child: const SizedBox(
                                  width: 36,
                                  height: 36,
                                  child: Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    size: 16,
                                    color: _authHeaderColor,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFFB6B9C7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 28),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ô nhập kèm nhãn chữ hoa nhỏ phía trên (kiểu EMAIL / PASSWORD).
class AuthTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final VoidCallback? onToggleObscure;
  final ValueChanged<String>? onChanged;

  const AuthTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.onToggleObscure,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _authLabelColor,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 14, color: AppColors.text),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 14,
              color: Color(0xFFB0B5BD),
            ),
            filled: true,
            fillColor: _authFieldFill,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 15,
            ),
            suffixIcon: onToggleObscure == null
                ? null
                : IconButton(
                    icon: Icon(
                      obscureText
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 19,
                      color: const Color(0xFF8A9099),
                    ),
                    onPressed: onToggleObscure,
                  ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}

/// Nút hành động chính (ĐĂNG NHẬP / ĐĂNG KÝ) — cam, chữ hoa, full chiều rộng.
class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.6,
                ),
              ),
      ),
    );
  }
}

/// Dòng lỗi hiển thị ngay trong form.
class AuthErrorText extends StatelessWidget {
  final String message;

  const AuthErrorText({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.error_outline_rounded,
            color: AppColors.danger, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: AppColors.danger,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// Vạch ngăn có chữ "Hoặc" ở giữa.
class AuthOrDivider extends StatelessWidget {
  final String label;

  const AuthOrDivider({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFE8EAED))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: _authLabelColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFE8EAED))),
      ],
    );
  }
}

/// Nút đăng nhập mạng xã hội dạng tròn.
class AuthSocialButton extends StatelessWidget {
  final Widget child;
  final Color background;
  final VoidCallback onTap;

  const AuthSocialButton({
    super.key,
    required this.child,
    required this.background,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(child: child),
        ),
      ),
    );
  }
}

/// Dòng "Chưa có tài khoản? ĐĂNG KÝ".
class AuthFooterLink extends StatelessWidget {
  final String question;
  final String actionLabel;
  final VoidCallback onTap;

  const AuthFooterLink({
    super.key,
    required this.question,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          question,
          style: const TextStyle(fontSize: 13, color: Color(0xFF7F8C8D)),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: onTap,
          child: Text(
            actionLabel.toUpperCase(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}
