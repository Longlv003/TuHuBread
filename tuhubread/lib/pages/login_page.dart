import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart' as getx;
import 'package:tuhubread/l10n/app_localizations.dart';
import 'package:tuhubread/blocs/auth/auth_cubit.dart';
import 'package:tuhubread/gen/assets.gen.dart';
import '../blocs/auth/auth_state.dart';
import '../routes/routes.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    context.read<AuthCubit>().reset();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginPressed(AuthCubit authCubit, AppLocalizations l10n) {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    authCubit.loginWithEmailAndPassword(
      email,
      password,
      emptyFieldsError: l10n.emptyEmailPassError,
      invalidEmailError: l10n.invalidEmailError,
      firebaseErrors: {
        'invalid-credential': l10n.firebaseErrorInvalidCredential,
        'user-disabled': l10n.firebaseErrorUserDisabled,
        'too-many-requests': l10n.firebaseErrorTooManyRequests,
        'default': l10n.firebaseErrorDefault,
      },
      defaultLoginError: l10n.loginFailureDefault,
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
          
          // Determine the error text to show inline
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
                  const SizedBox(height: 50),
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF39C12).withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE67E22), width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD35400).withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.bakery_dining_rounded,
                        size: 64,
                        color: Color(0xFFD35400),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    l10n.loginTitle,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2C3E50),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.loginSlogan,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF7F8C8D),
                    ),
                  ),
                  const SizedBox(height: 40),

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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.loginHeading,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.loginSubheading,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF95A5A6),
                          ),
                        ),
                        const SizedBox(height: 24),

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
                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16.0),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16.0),
                              borderSide: const BorderSide(color: Color(0xFFE67E22), width: 1.5),
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
                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16.0),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16.0),
                              borderSide: const BorderSide(color: Color(0xFFE67E22), width: 1.5),
                            ),
                          ),
                        ),
                        
                        // Inline error message below password and above button
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
                            onPressed: totalLoading ? null : () => _onLoginPressed(authCubit, l10n),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE67E22),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.0),
                              ),
                              elevation: 0,
                            ),
                            child: totalLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Text(
                                    l10n.loginButton,
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
                        l10n.noAccountText,
                        style: const TextStyle(color: Color(0xFF7F8C8D)),
                      ),
                      GestureDetector(
                        onTap: () {
                          getx.Get.toNamed(Routes.registerPage);
                        },
                        child: Text(
                          l10n.registerNowLink,
                          style: const TextStyle(
                            color: Color(0xFFE67E22),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade300, endIndent: 10, indent: 10)),
                      Text(
                        l10n.orText,
                        style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w700),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade300, endIndent: 10, indent: 10)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      InkWell(
                        onTap: () => authCubit.handleFacebookAuth(
                          defaultLoginError: l10n.loginFailureDefault,
                          networkErrorMsg: l10n.networkError,
                          timeoutErrorMsg: l10n.connectionTimeoutError,
                          cancelledError: l10n.loginCancelledError,
                          firebaseErrors: {
                            'invalid-credential': l10n.firebaseErrorInvalidCredential,
                            'user-disabled': l10n.firebaseErrorUserDisabled,
                            'too-many-requests': l10n.firebaseErrorTooManyRequests,
                            'default': l10n.firebaseErrorDefault,
                            'account-exists-with-different-credential': l10n.firebaseErrorAccountExistsWithDifferentCredential,
                          },
                        ),
                        borderRadius: BorderRadius.circular(12),
                        child: Ink(
                          child: Assets.images.logoFacebook.image(
                            width: 40,
                            height: 40,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      InkWell(
                        onTap: () => authCubit.handleGoogleAuth(
                          defaultLoginError: l10n.loginFailureDefault,
                          networkErrorMsg: l10n.networkError,
                          timeoutErrorMsg: l10n.connectionTimeoutError,
                          cancelledError: l10n.loginCancelledError,
                          firebaseErrors: {
                            'invalid-credential': l10n.firebaseErrorInvalidCredential,
                            'user-disabled': l10n.firebaseErrorUserDisabled,
                            'too-many-requests': l10n.firebaseErrorTooManyRequests,
                            'default': l10n.firebaseErrorDefault,
                            'account-exists-with-different-credential': l10n.firebaseErrorAccountExistsWithDifferentCredential,
                          },
                        ),
                        borderRadius: BorderRadius.circular(12),
                        child: Ink(
                          child: Assets.images.logoGoogle.image(
                            width: 40,
                            height: 40,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
