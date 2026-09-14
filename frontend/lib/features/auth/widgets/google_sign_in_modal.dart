import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/router/route_names.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/text_styles.dart';
import 'package:frontend/core/utils/validators.dart';
import 'package:frontend/features/auth/providers/auth_provider.dart';
import 'package:frontend/shared/widgets/custom_button.dart';
import 'package:frontend/shared/widgets/custom_text_field.dart';

/// Interactive Google Sign-In sheet/modal that handles Google OAuth token or Google Account email authentication
class GoogleSignInModal extends ConsumerStatefulWidget {
  const GoogleSignInModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const GoogleSignInModal(),
    );
  }

  @override
  ConsumerState<GoogleSignInModal> createState() => _GoogleSignInModalState();
}

class _GoogleSignInModalState extends ConsumerState<GoogleSignInModal> {
  final _emailController = TextEditingController(text: 'alex.rivera.stanford@gmail.com');
  final _nameController = TextEditingController(text: 'Alex Rivera');
  final _tokenController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _showTokenField = false;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _submitGoogleAuth() async {
    if (_formKey.currentState?.validate() ?? false) {
      final email = _emailController.text.trim();
      final name = _nameController.text.trim();
      final idToken = _tokenController.text.trim().isNotEmpty ? _tokenController.text.trim() : null;

      final success = await ref.read(authNotifierProvider.notifier).signInWithGoogle(
            email: email,
            name: name.isNotEmpty ? name : null,
            idToken: idToken,
          );

      if (success && mounted) {
        Navigator.of(context).pop();
        context.go(RouteNames.home);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authNotifierProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.lightBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'G',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4285F4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sign In with Google',
                          style: AppTextStyles.titleLarge(context),
                        ),
                        Text(
                          'Authenticate securely with your Google Student account',
                          style: AppTextStyles.bodySmall(context).copyWith(
                            color: AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Error display
              if (authState.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    authState.errorMessage!,
                    style: const TextStyle(color: AppColors.error, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Google Email Field
              CustomTextField(
                controller: _emailController,
                label: 'Google Account Email',
                hint: 'name@gmail.com or university email',
                prefixIcon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
              ),
              const SizedBox(height: 14),

              // Full Name
              CustomTextField(
                controller: _nameController,
                label: 'Display Name',
                hint: 'Your full name',
                prefixIcon: Icons.badge_outlined,
              ),
              const SizedBox(height: 12),

              // Toggle Google ID Token
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showTokenField = !_showTokenField;
                  });
                },
                child: Row(
                  children: [
                    Icon(
                      _showTokenField ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _showTokenField ? 'Hide OAuth ID Token input' : 'Enter Google OAuth ID Token (Optional)',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (_showTokenField) ...[
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _tokenController,
                  label: 'Google ID Token / OAuth Code',
                  hint: 'Paste JWT ID token from Google Cloud Console if available',
                  prefixIcon: Icons.security_rounded,
                  maxLines: 2,
                ),
              ],
              const SizedBox(height: 20),

              // Submit Button
              CustomButton(
                text: 'Authenticate with Google',
                isLoading: authState.isLoading,
                icon: Icons.check_circle_outline_rounded,
                onPressed: _submitGoogleAuth,
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
