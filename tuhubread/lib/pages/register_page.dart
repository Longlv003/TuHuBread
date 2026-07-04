import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart' as getx;
import 'package:tuhubread/l10n/app_localizations.dart';
import 'package:tuhubread/blocs/auth/auth_cubit.dart';
import '../blocs/auth/auth_state.dart';
import '../routes/routes.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    context.read<AuthCubit>().reset();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onRegisterPressed(AuthCubit authCubit, AppLocalizations l10n) {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    authCubit.registerWithEmailAndPassword(
      name,
      email,
      password,
      confirmPassword,
      emptyFieldsError: l10n.emptyFieldsError,
      passwordMismatchError: l10n.passwordMismatchError,
      invalidEmailError: l10n.invalidEmailError,
      firebaseErrors: {
        'weak-password': l10n.firebaseErrorWeakPassword,
        'email-already-in-use': l10n.firebaseErrorEmailAlreadyInUse,
        'invalid-email': l10n.invalidEmailError,
        'default': l10n.firebaseErrorDefault,
      },
      defaultRegisterError: l10n.registerFailureDefault,
      networkErrorMsg: l10n.networkError,
      timeoutErrorMsg: l10n.connectionTimeoutError,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F6),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            getx.Get.offAllNamed(Routes.homePage);
          }
        },
        builder: (context, state) {
          final totalLoading = state is AuthLoading;
          final authCubit = context.read<AuthCubit>();

          String? displayError;
          if (state is AuthFailure) {
            displayError = state.error;
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 30),
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF39C12).withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE67E22), width: 3),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.person_add_alt_1_rounded,
                        size: 48,
                        color: Color(0xFFD35400),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.registerTitle,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.registerSlogan,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF7F8C8D)),
                  ),
                  const SizedBox(height: 36),

                  Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _nameController,
                          keyboardType: TextInputType.name,
                          onChanged: (_) {
                            if (state is AuthFailure) {
                              authCubit.reset();
                            }
                          },
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFFE67E22)),
                            hintText: l10n.fullNameHint,
                            filled: true,
                            fillColor: const Color(0xFFF9F9F9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16.0),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (_) {
                            if (state is AuthFailure) {
                              authCubit.reset();
                            }
                          },
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFFE67E22)),
                            hintText: l10n.emailHint,
                            filled: true,
                            fillColor: const Color(0xFFF9F9F9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16.0),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          onChanged: (_) {
                            if (state is AuthFailure) {
                              authCubit.reset();
                            }
                          },
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFFE67E22)),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: const Color(0xFF7F8C8D),
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            hintText: l10n.passwordHint,
                            filled: true,
                            fillColor: const Color(0xFFF9F9F9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16.0),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          onChanged: (_) {
                            if (state is AuthFailure) {
                              authCubit.reset();
                            }
                          },
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.lock_clock_outlined, color: Color(0xFFE67E22)),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: const Color(0xFF7F8C8D),
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                });
                              },
                            ),
                            hintText: l10n.confirmPasswordHint,
                            filled: true,
                            fillColor: const Color(0xFFF9F9F9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16.0),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        
                        if (displayError != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  displayError,
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: totalLoading ? null : () => _onRegisterPressed(authCubit, l10n),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE67E22),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.0)),
                              elevation: 0,
                            ),
                            child: totalLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Text(
                                    l10n.registerButtonText,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.hasAccountText,
                        style: const TextStyle(color: Color(0xFF7F8C8D)),
                      ),
                      GestureDetector(
                        onTap: () {
                          getx.Get.back();
                        },
                        child: Text(
                          l10n.loginButton,
                          style: const TextStyle(
                            color: Color(0xFFE67E22),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
