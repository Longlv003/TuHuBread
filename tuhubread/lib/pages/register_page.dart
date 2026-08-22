import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart' as getx;
import 'package:tuhubread/l10n/app_localizations.dart';
import 'package:tuhubread/blocs/auth/auth_cubit.dart';
import '../blocs/auth/auth_state.dart';
import '../routes/routes.dart';
import '../widgets/auth_form_widgets.dart';

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
    authCubit.registerWithEmailAndPassword(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text.trim(),
      _confirmPasswordController.text.trim(),
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
          title: l10n.registerTitle,
          subtitle: l10n.registerSlogan,
          onBack: () => getx.Get.back(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthTextField(
                label: l10n.fullNameHint,
                hint: l10n.authNamePlaceholder,
                controller: _nameController,
                keyboardType: TextInputType.name,
                onChanged: clearErrorOnEdit,
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 16),
              AuthTextField(
                label: l10n.confirmPasswordHint,
                hint: l10n.authConfirmPasswordPlaceholder,
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                onToggleObscure: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                ),
                onChanged: clearErrorOnEdit,
              ),
              if (displayError != null) ...[
                const SizedBox(height: 14),
                AuthErrorText(message: displayError),
              ],
              const SizedBox(height: 24),
              AuthPrimaryButton(
                label: l10n.registerButtonText,
                isLoading: isLoading,
                onPressed: () => _onRegisterPressed(authCubit, l10n),
              ),
              const SizedBox(height: 18),
              AuthFooterLink(
                question: l10n.hasAccountText,
                actionLabel: l10n.loginButton,
                onTap: () => getx.Get.back(),
              ),
            ],
          ),
        );
      },
    );
  }
}
