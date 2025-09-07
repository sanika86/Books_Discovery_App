import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../auth/controller/auth_controller.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  bool _passwordVisible = false;
  bool _acceptTerms = false;

  String? _emailError;
  String? _passwordError;

  bool _validateInputs() {
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    final emailText = email.text.trim();
    final passwordText = password.text.trim();

    if (!RegExp(r"^[\w\.-]+@[\w\.-]+\.\w+$").hasMatch(emailText)) {
      setState(() => _emailError = "Enter a valid email address");
      return false;
    }
    if (passwordText.length < 6) {
      setState(() => _passwordError = "Password must be at least 6 characters");
      return false;
    }
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please accept terms & conditions")),
      );
      return false;
    }
    return true;
  }

  Future<void> _doRegister() async {
    if (!_validateInputs()) return;
    setState(() => loading = true);
    final err = await ref.read(authControllerProvider.notifier)
        .signUp(email.text.trim(), password.text.trim());
    setState(() => loading = false);

    if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: Colors.red),
      );
    } else if (mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('seenVerification', false);
      context.go('/verification');
    }
  }

  Future<void> _googleSignUp() async {
    setState(() => loading = true);
    final err = await ref.read(authControllerProvider.notifier).googleSignIn();
    setState(() => loading = false);
    if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Container(
          width: 375,
          height: 1000,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header section with grey background
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 50),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Sign Up",
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Enter your details below & free sign up",
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: const Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Form section with white background
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      
                      // Email field
                      Text(
                        "Your Email",
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 327,
                        height: 50,
                        child: TextField(
                          controller: email,
                          keyboardType: TextInputType.emailAddress,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                          decoration: InputDecoration(
                            hintText: "Cooper_Kristin@gmail.com",
                            hintStyle: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF858597),
                            ),
                            errorText: _emailError,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Password field
                      Text(
                        "Password",
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 327,
                        height: 50,
                        child: TextField(
                          controller: password,
                          obscureText: !_passwordVisible,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                          decoration: InputDecoration(
                            hintText: "••••••••••••",
                            hintStyle: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF858597),
                            ),
                            errorText: _passwordError,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _passwordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: const Color(0xFF6B7280),
                              ),
                              onPressed: () {
                                setState(() => _passwordVisible = !_passwordVisible);
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Create account button
                      SizedBox(
                        width: 327,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: loading ? null : _doRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                            padding: EdgeInsets.zero,
                          ),
                          child: loading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  "Create account",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Terms & conditions checkbox
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _acceptTerms,
                            onChanged: (val) {
                              setState(() => _acceptTerms = val ?? false);
                            },
                            activeColor: const Color(0xFF3B82F6),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                "By creating an account you have to agree with our them & condication.",
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: const Color(0xFF6B7280),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Login link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already have an account? ",
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF6B7280),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.go('/login'),
                            child: Text(
                              "Log in",
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF3B82F6),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Divider
                      // Row(
                      //   children: [
                      //     const Expanded(child: Divider(thickness: 1)),
                      //     Padding(
                      //       padding: const EdgeInsets.symmetric(horizontal: 8),
                      //       child: Text(
                      //         "Or sign up with",
                      //         style: GoogleFonts.poppins(
                      //           color: const Color(0xFF6B7280),
                      //           fontSize: 14,
                      //           fontWeight: FontWeight.w400,
                      //         ),
                      //       ),
                      //     ),
                      //     const Expanded(child: Divider(thickness: 1)),
                      //   ],
                      // ),
                      // const SizedBox(height: 18),

                      // Google sign up button
                      // Center(
                      //   child: SizedBox(
                      //     width: 48,
                      //     height: 48,
                      //     child: TextButton(
                      //       onPressed: loading ? null : _googleSignUp,
                      //       style: TextButton.styleFrom(
                      //         shape: RoundedRectangleBorder(
                      //           borderRadius: BorderRadius.circular(12),
                      //         ),
                      //         padding: EdgeInsets.zero,
                      //         backgroundColor: Colors.white,
                      //       ),
                      //       child: Image.asset("assets/google.png", height: 48),
                      //     ),
                      //   ),
                      // ),
                      // const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}