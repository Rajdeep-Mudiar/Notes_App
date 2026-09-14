import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/router/route_names.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/text_styles.dart';
import 'package:frontend/core/utils/validators.dart';
import 'package:frontend/features/auth/providers/auth_provider.dart';
import 'package:frontend/features/auth/widgets/google_sign_in_button.dart';
import 'package:frontend/shared/widgets/custom_button.dart';
import 'package:frontend/shared/widgets/custom_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _universityController = TextEditingController(text: 'Stanford University');
  final _degreeController = TextEditingController(text: 'B.S. Computer Science');
  final _semesterController = TextEditingController(text: '4');
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _universityController.dispose();
    _degreeController.dispose();
    _semesterController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();
      final semester = int.tryParse(_semesterController.text.trim()) ?? 1;
      final success = await ref.read(authNotifierProvider.notifier).register(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            fullName: _nameController.text.trim(),
            university: _universityController.text.trim(),
            degree: _degreeController.text.trim(),
            currentSemester: semester,
          );
      if (success && mounted) {
        context.go(RouteNames.home);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            ref.read(authNotifierProvider.notifier).clearError();
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RouteNames.login);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Heading
                    Text(
                      'Create an Account',
                      style: AppTextStyles.displayMedium(context),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sign up for Student OS to organize notes, track assignments, and prepare for exams with AI.',
                      style: AppTextStyles.bodyMedium(context).copyWith(
                        color: AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Error Banner
                    if (authState.errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.error,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                authState.errorMessage!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Full Name
                    CustomTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      hint: 'Alex Rivera',
                      prefixIcon: Icons.person_outline_rounded,
                      validator: Validators.name,
                    ),
                    const SizedBox(height: 16),

                    // Email
                    CustomTextField(
                      controller: _emailController,
                      label: 'University Email',
                      hint: 'alex.rivera@stanford.edu',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 16),

                    // University & Semester Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: CustomTextField(
                            controller: _universityController,
                            label: 'University',
                            hint: 'Stanford University',
                            prefixIcon: Icons.school_outlined,
                            validator: (v) => Validators.required(v, message: 'Required'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: CustomTextField(
                            controller: _semesterController,
                            label: 'Sem',
                            hint: '4',
                            prefixIcon: Icons.timeline_rounded,
                            keyboardType: TextInputType.number,
                            validator: Validators.semester,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Degree / Major
                    CustomTextField(
                      controller: _degreeController,
                      label: 'Degree & Major',
                      hint: 'B.S. Computer Science',
                      prefixIcon: Icons.menu_book_rounded,
                      validator: (v) => Validators.required(v, message: 'Degree is required'),
                    ),
                    const SizedBox(height: 16),

                    // Password
                    CustomTextField(
                      controller: _passwordController,
                      label: 'Password',
                      hint: 'At least 6 characters',
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: _obscurePassword,
                      validator: Validators.password,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                          color: AppColors.lightTextMuted,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Submit Button
                    CustomButton(
                      text: 'Sign Up & Create Account',
                      isLoading: authState.isLoading,
                      icon: Icons.arrow_forward_rounded,
                      onPressed: _handleRegister,
                    ),
                    const SizedBox(height: 14),

                    // Divider
                    Row(
                      children: [
                        const Expanded(child: Divider(color: AppColors.lightBorder)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.lightTextMuted,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider(color: AppColors.lightBorder)),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Google Sign-In Button
                    const GoogleSignInButton(label: 'Sign Up with Google'),
                    const SizedBox(height: 20),

                    // Back to login
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          "Already have an account? ",
                          style: TextStyle(
                            color: AppColors.lightTextSecondary,
                            fontSize: 14,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            ref.read(authNotifierProvider.notifier).clearError();
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go(RouteNames.login);
                            }
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                            child: Text(
                              'Sign In',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
