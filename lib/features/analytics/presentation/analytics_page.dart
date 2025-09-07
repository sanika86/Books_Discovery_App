import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../profile/providers/profile_providers.dart';
import '../providers/analytics_providers.dart';

class AnalyticsPage extends ConsumerStatefulWidget {
  const AnalyticsPage({super.key});

  @override
  ConsumerState<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends ConsumerState<AnalyticsPage>
    with TickerProviderStateMixin {
  late AnimationController _pieChartAnimationController;
  late AnimationController _barChartAnimationController;
  late AnimationController _lineChartAnimationController;

  late Animation<double> _pieChartAnimation;
  late Animation<double> _barChartAnimation;
  late Animation<double> _lineChartAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _pieChartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _barChartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _lineChartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Create animations
    _pieChartAnimation = CurvedAnimation(
      parent: _pieChartAnimationController,
      curve: Curves.easeInOutCubic,
    );
    _barChartAnimation = CurvedAnimation(
      parent: _barChartAnimationController,
      curve: Curves.easeInOutBack,
    );
    _lineChartAnimation = CurvedAnimation(
      parent: _lineChartAnimationController,
      curve: Curves.easeInOutQuart,
    );

    // Start animations with delays
    Future.delayed(const Duration(milliseconds: 200), () {
      _pieChartAnimationController.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      _barChartAnimationController.forward();
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      _lineChartAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _pieChartAnimationController.dispose();
    _barChartAnimationController.dispose();
    _lineChartAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName =
        user?.displayName ?? user?.email?.split('@').first ?? 'User';
    final profilePicture = ref.watch(profilePictureProvider);

    return Scaffold(
      backgroundColor: Colors.white, // full white background
      body: Stack(
        children: [
          // Blue background half screen ke liye
          Container(
            height: MediaQuery.of(context).size.height * 0.30,
            color: const Color(0xFF3D5CFF),
          ),

          // Scrollable content
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Header Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 30),
                    decoration: const BoxDecoration(
                      color: Color(0xFF3D5CFF),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Hi, $userName",
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Let's start learning",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white.withOpacity(0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                        profilePicture.when(
                          data: (imageUrl) => CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.white,
                            backgroundImage: imageUrl != null
                                ? NetworkImage(imageUrl)
                                : const AssetImage("assets/Avatar.png")
                                    as ImageProvider,
                          ),
                          loading: () => const CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.white,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          error: (_, __) => const CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.white,
                            backgroundImage: AssetImage("assets/Avatar.png"),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Genre Distribution Chart
                  _buildGenreDistributionCard(),
                  const SizedBox(height: 24),

                  // Book Publishing Trend Chart
                  _buildPublishingTrendCard(),
                  const SizedBox(height: 24),

                  // Sales Overview Chart
                  _buildSalesOverviewCard(),
                  const SizedBox(height: 24),

                  // Meetup Card
                  _buildMeetupCard(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Genre Distribution Card
  Widget _buildGenreDistributionCard() {
    final genreData = ref.watch(genreDistributionProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFCEECFE), // Updated background
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Genre Distribution",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 180,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: AnimatedBuilder(
                      animation: _pieChartAnimation,
                      builder: (context, child) {
                        return PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 70, // donut effect
                            startDegreeOffset: -90,
                            sections: genreData.map((data) {
                              return PieChartSectionData(
                                color: data.color,
                                value: data.count.toDouble(),
                                title: '', // no percentage text
                                radius: 20, // fixed thickness
                                borderSide: BorderSide.none,
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: genreData.take(6).map((data) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: data.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  data.genre,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: const Color(0xFF6B7280),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPublishingTrendCard() {
    final trendData = ref.watch(publishingTrendProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFCCCCCC),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Book Publishing Trend (2021-2025)",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: AnimatedBuilder(
                animation: _barChartAnimation,
                builder: (context, child) {
                  return BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 1400,
                      barTouchData: BarTouchData(enabled: true),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  value.toInt().toString(),
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: const Color(0xFF6B7280),
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 200,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: const Color(0xFFE5E7EB),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: trendData.asMap().entries.map((entry) {
                        final index = entry.key;
                        final data = entry.value;
                        return BarChartGroupData(
                          x: data.year,
                          barRods: [
                            BarChartRodData(
                              toY: data.bookCount.toDouble() *
                                  _barChartAnimation.value,
                              color: const Color(0xFF3D5CFF),
                              width: 30,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(6),
                                topRight: Radius.circular(6),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesOverviewCard() {
    final salesData = ref.watch(salesOverviewProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFCCCCCC),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Sales Overview (2024)",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Monthly revenue trends",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: AnimatedBuilder(
                animation: _lineChartAnimation,
                builder: (context, child) {
                  return LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 5000,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: const Color(0xFFE5E7EB),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt() - 1;
                              if (index >= 0 && index < salesData.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    salesData[index].period,
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: const Color(0xFF6B7280),
                                    ),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 10000,
                            reservedSize: 50,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '\$${(value / 1000).toInt()}k',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: const Color(0xFF6B7280),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 1,
                      maxX: 12,
                      minY: 0,
                      maxY: 45000,
                      lineBarsData: [
                        LineChartBarData(
                          spots: salesData.asMap().entries.map((entry) {
                            final index = entry.key;
                            final data = entry.value;
                            return FlSpot(
                              (index + 1).toDouble(),
                              data.revenue * _lineChartAnimation.value,
                            );
                          }).toList(),
                          isCurved: true,
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF3D5CFF),
                              const Color(0xFF06D6A0),
                            ],
                          ),
                          barWidth: 4,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: Colors.white,
                                strokeWidth: 3,
                                strokeColor: const Color(0xFF3D5CFF),
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF3D5CFF).withOpacity(0.3),
                                const Color(0xFF3D5CFF).withOpacity(0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeetupCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFEFE0FF),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Meetup",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Off-line exchange of learning experiences",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 12),
                 
                ],
              ),
            ),
            const SizedBox(width: 20),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
  color: const Color(0xFFEFE0FF), // background color
  borderRadius: BorderRadius.circular(24),
  boxShadow: [
    BoxShadow(
      color: const Color(0xFFB8B8D2).withOpacity(0.2), // 20% opacity
      offset: const Offset(0, 8), // X=0, Y=8
      blurRadius: 12, // Blur=12
      spreadRadius: 0, // Spread=0
    ),
  ],
),

              child: const Icon(
                Icons.people_rounded,
                size: 40,
                color: Color(0xFF3D5CFF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
