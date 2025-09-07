import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/controller/auth_controller.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  bool _passwordVisible = false;

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
    return true;
  }

  Future<void> _doLogin() async {
    if (!_validateInputs()) return;
    setState(() => loading = true);
    final err = await ref
        .read(authControllerProvider.notifier)
        .signIn(email.text.trim(), password.text.trim());
    setState(() => loading = false);

    if (err != null && mounted) {
      if (err == "User not found") {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Please register first"),
            content: const Text(
                "No account found for this email. Please register first."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx, rootNavigator: true).pop();
                  context.go('/register');
                },
                child: const Text("Register"),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(err)));
      }
    } else if (mounted) {
      context.go('/');
    }
  }

  Future<void> _googleLogin() async {
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
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 50),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                alignment: Alignment.centerLeft,
                child: Text(
                  "Log In",
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      Text(
                        "Your  Email",
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
                                setState(
                                    () => _passwordVisible = !_passwordVisible);
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: Text(
                            "Forgot password?",
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF6B7280),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 327,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: loading ? null : _doLogin,
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
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : Text(
                                  "Log In",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF6B7280),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.go('/register'),
                            child: Text(
                              "Sign up",
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
                      
                      // Enhanced divider with better visibility
                      Container(
                        width: 327,
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 1,
                                color: const Color(0xFFE5E7EB),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                "Or login with",
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF6B7280),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: const Color(0xFFE5E7EB),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Center(
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: TextButton(
                            onPressed: loading ? null : _googleLogin,
                            style: TextButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                
                              ),
                              padding: EdgeInsets.zero,
                              backgroundColor: Colors.white,
                            ),
                            child: Image.asset("assets/google.png", height: 48, width: 48),
                          ),
                        ),
                      ),
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