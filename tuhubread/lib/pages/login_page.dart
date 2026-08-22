import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart' as getx;
import 'package:tuhubread/l10n/app_localizations.dart';
import 'package:tuhubread/blocs/auth/auth_cubit.dart';
import 'package:tuhubread/gen/assets.gen.dart';
import '../blocs/auth/auth_state.dart';
import '../routes/routes.dart';
import '../widgets/auth_form_widgets.dart';

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
    authCubit.loginWithEmailAndPassword(
      _emailController.text.trim(),
      _passwordController.text.trim(),
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

  Map<String, String> _socialFirebaseErrors(AppLocalizations l10n) => {
        'invalid-credential': l10n.firebaseErrorInvalidCredential,
        'user-disabled': l10n.firebaseErrorUserDisabled,
        'too-many-requests': l10n.firebaseErrorTooManyRequests,
        'default': l10n.firebaseErrorDefault,
        'account-exists-with-different-credential':
            l10n.firebaseErrorAccountExistsWithDifferentCredential,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          getx.Get.offAllNamed(Routes.homePage);
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        final authCubit = context.read<AuthCubit>();
        final displayError = state is AuthFailure ? state.error : null;

        void clearErrorOnEdit(String _) {
          if (state is AuthFailure) authCubit.reset();
        }

        return AuthScaffold(
          title: l10n.loginHeading,
          subtitle: l10n.loginSubheading,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthTextField(
                label: l10n.emailHint,
                hint: l10n.authEmailPlaceholder,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                onChanged: clearErrorOnEdit,
              ),
              const SizedBox(height: 16),
              AuthTextField(
                label: l10n.passwordHint,
                hint: l10n.authPasswordPlaceholder,
                controller: _passwordController,
                obscureText: _obscurePassword,
                onToggleObscure: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                onChanged: clearErrorOnEdit,
              ),
              if (displayError != null) ...[
                const SizedBox(height: 14),
                AuthErrorText(message: displayError),
              ],
              const SizedBox(height: 24),
              AuthPrimaryButton(
                label: l10n.loginButton,
                isLoading: isLoading,
                onPressed: () => _onLoginPressed(authCubit, l10n),
              ),
              const SizedBox(height: 18),
              AuthFooterLink(
                question: l10n.noAccountText,
                actionLabel: l10n.registerNowLink,
                onTap: () => getx.Get.toNamed(Routes.registerPage),
              ),
              const SizedBox(height: 22),
              AuthOrDivider(label: l10n.orText),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AuthSocialButton(
                    background: const Color(0xFF1877F2),
                    onTap: () => authCubit.handleFacebookAuth(
                      defaultLoginError: l10n.loginFailureDefault,
                      networkErrorMsg: l10n.networkError,
                      timeoutErrorMsg: l10n.connectionTimeoutError,
                      cancelledError: l10n.loginCancelledError,
                      firebaseErrors: _socialFirebaseErrors(l10n),
                    ),
                    child: Assets.images.logoFacebook.image(
                      width: 26,
                      height: 26,
                    ),
                  ),
                  const SizedBox(width: 18),
                  AuthSocialButton(
                    background: Colors.white,
                    onTap: () => authCubit.handleGoogleAuth(
                      defaultLoginError: l10n.loginFailureDefault,
                      networkErrorMsg: l10n.networkError,
                      timeoutErrorMsg: l10n.connectionTimeoutError,
                      cancelledError: l10n.loginCancelledError,
                      firebaseErrors: _socialFirebaseErrors(l10n),
                    ),
                    child: Assets.images.logoGoogle.image(
                      width: 26,
                      height: 26,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
