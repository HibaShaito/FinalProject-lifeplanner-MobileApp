import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:lifeplanner/services/auth_service.dart';
import 'package:lifeplanner/services/user_repository.dart';
import 'package:lifeplanner/utils/network_status_service.dart';
import 'package:provider/provider.dart';
import 'package:lifeplanner/pages/settings/privacy_policy.dart';
import 'package:lifeplanner/pages/settings/terms_and_conditions_page.dart';
import 'package:lifeplanner/pages/onboarding/welcome_page.dart';
import 'package:lifeplanner/widgets/base_scaffold.dart';
import 'login_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});
  static route() => MaterialPageRoute(builder: (_) => const SignUpPage());

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final AuthService authService = AuthService();
  final UserRepository userRepository = UserRepository();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  bool isValidEmail(String email) {
    final emailRegExp = RegExp(r'^[\w.-]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegExp.hasMatch(email);
  }

  bool isValidPassword(String password) {
    final pwdRegExp = RegExp(
      r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[^A-Za-z\d]).{8,}$',
    );
    return pwdRegExp.hasMatch(password);
  }

  Future<void> createUserWithEmailAndPassword() async {
    if (!formKey.currentState!.validate()) return;

    try {
      final user = await authService.signUpWithEmail(
        email: emailController.text.trim().toLowerCase(),
        password: passwordController.text,
      );

      if (user != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent. Please check your inbox.'),
          ),
        );
        Navigator.pushReplacement(context, LoginPage.route());
      }
    } catch (e) {
      passwordController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Widget _roundedInputField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget buildGoogleSignInButton(bool isOnline) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return OutlinedButton.icon(
      onPressed:
          isOnline
              ? () async {
                final user = await authService.signInWithGoogle();
                if (user != null && mounted) {
                  Navigator.pushReplacement(context, LoginPage.route());
                }
              }
              : null,
      icon: Icon(Icons.g_mobiledata, size: width * 0.075),
      label: const Text('Continue with Google'),
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        minimumSize: Size(double.infinity, height * 0.065),
        backgroundColor: isOnline ? null : Colors.grey[300],
      ),
    );
  }

  Widget buildOrDivider() {
    return Row(
      children: const [
        Expanded(child: Divider(thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text("or", style: TextStyle(color: Colors.black54)),
        ),
        Expanded(child: Divider(thickness: 1)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = context.watch<NetworkStatusNotifier>().isOnline;

    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final paddingHorizontal = width * 0.06;

    return BaseScaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFCD7D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const WelcomePage()),
            );
          },
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: paddingHorizontal),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Life Planner',
                    style: TextStyle(
                      fontSize: width * 0.06,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Create an account',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: width * 0.045,
                  ),
                ),
                const SizedBox(height: 16),
                _roundedInputField(
                  controller: emailController,
                  hintText: 'Email',
                  validator: (value) {
                    final trimmed = value?.trim() ?? '';
                    if (trimmed.isEmpty || !isValidEmail(trimmed)) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _roundedInputField(
                  controller: passwordController,
                  hintText: 'Password',
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter a password';
                    }
                    if (!isValidPassword(value)) {
                      return 'Password must be ≥8 chars, include upper & lower case, a number & a special character';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: height * 0.065,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isOnline ? Colors.black : Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: isOnline ? createUserWithEmailAndPassword : null,
                    child: const Text(
                      'Continue',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                buildOrDivider(),
                const SizedBox(height: 16),
                buildGoogleSignInButton(isOnline),
                const SizedBox(height: 24),

                Center(
                  child: Text.rich(
                    TextSpan(
                      text: 'By continuing, you agree to our ',
                      style: TextStyle(fontSize: width * 0.03),
                      children: [
                        TextSpan(
                          text: 'Terms of Service',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                          recognizer:
                              TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => const TermsAndConditionsPage(),
                                    ),
                                  );
                                },
                        ),
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                          recognizer:
                              TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const PrivacyPolicyPage(),
                                    ),
                                  );
                                },
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
