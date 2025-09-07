import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  final List<Map<String, String>> onboardingData = [
    {
      "image": "assets/illustration.png",
      "title": "Numerous free\ntrial courses",
      "subtitle": "Free courses for you to\nfind your way to learning",
    },
    {
      "image": "assets/onboard2.png",
      "title": "Quick and easy\nlearning",
      "subtitle": "Easy and fast learning at\nany time to help you\nimprove various skills",
    },
    {
      "image": "assets/onboard3.png",
      "title": "Create your own\nstudy plan",
      "subtitle": "Study according to the\nstudy plan, make study\nmore motivated",
    },
  ];

  Future<void> _completeOnboarding(BuildContext context, String route) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // <-- Add this line for pure white background
      body: Stack(
        children: [
          // Skip button at top-right (hide on last page)
          if (_currentIndex != onboardingData.length - 1)
            Positioned(
              top: 80,
              right: 8,
              child: TextButton(
                onPressed: () => _completeOnboarding(context, '/login'),
                child: Text(
                  "Skip",
                  style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                height: 1.3, // line-height: 100%
                                color: Colors.grey,
                              ),
                ),
              ),
            ),
          // Centered onboarding content
          Center(
            child: SizedBox(
              width: 302,
              height: 537,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min, // Fix overflow
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: onboardingData.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        final data = onboardingData[index];
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min, // Fix overflow
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(32),
                              child: Image.asset(
                                data["image"]!,
                                height: 230,
                                width: 230,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 32),
                            Text(
                              data["title"]!,
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                height: 1.3,
                                color: const Color(0xFF111827),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              data["subtitle"]!,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                height: 1.3,
                                color: Color(0xFF858597),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            // Only add extra space on last page
                            if (_currentIndex == onboardingData.length - 1)
                              const SizedBox(height: 32),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Indicator (hide on last page)
                  if (_currentIndex != onboardingData.length - 1)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        onboardingData.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          height: 6,
                          width: _currentIndex == index ? 30 : 8,
                          decoration: BoxDecoration(
                            color: _currentIndex == index
                                ? const Color(0xFF3D5CFF)
                                : Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  if (_currentIndex != onboardingData.length - 1)
                    const SizedBox(height: 45),
                  // Buttons only on last page
                  if (_currentIndex == onboardingData.length - 1)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8), // Prevent overflow
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 140,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () => _completeOnboarding(context, '/register'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3D5CFF),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                                padding: EdgeInsets.zero,
                              ),
                              child: Text(
                                "Sign up",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 140,
                            height: 50,
                            child: OutlinedButton(
                              onPressed: () => _completeOnboarding(context, '/login'),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF3D5CFF)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              child: Text(
                                "Log in",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF3D5CFF),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}