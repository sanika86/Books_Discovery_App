import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../auth/controller/auth_controller.dart';
import '../providers/profile_providers.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _slideController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Create animations
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _scaleController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _showProfilePictureOptions() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Profile Picture',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildOptionButton(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () async {
                      Navigator.pop(context);
                      final permission = await Permission.photos.request();
                      if (permission.isGranted) {
                        ref.read(profilePictureProvider.notifier).pickAndUploadImage();
                      }
                    },
                  ),
                  _buildOptionButton(
                    icon: Icons.delete,
                    label: 'Remove',
                    color: Colors.red,
                    onTap: () {
                      Navigator.pop(context);
                      ref.read(profilePictureProvider.notifier).removeProfilePicture();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: (color ?? const Color(0xFF3D5CFF)).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              size: 24,
              color: color ?? const Color(0xFF3D5CFF),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final profilePicture = ref.watch(profilePictureProvider);
    
    final userName = user?.displayName ?? user?.email?.split('@').first ?? 'User';
    final userEmail = user?.email ?? 'No email';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header Section with Profile Picture
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF3D5CFF),
                      Color(0xFF6366F1),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      // Profile Picture with Hero Animation
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Hero(
                          tag: 'profile_picture',
                          child: GestureDetector(
                            onTap: _showProfilePictureOptions,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: profilePicture.when(
                                data: (imageUrl) => CircleAvatar(
                                  radius: 56,
                                  backgroundColor: Colors.white,
                                  backgroundImage: imageUrl != null 
                                      ? NetworkImage(imageUrl)
                                      : null,
                                  child: imageUrl == null
                                      ? Text(
                                          userName[0].toUpperCase(),
                                          style: GoogleFonts.poppins(
                                            fontSize: 32,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF3D5CFF),
                                          ),
                                        )
                                      : null,
                                ),
                                loading: () => const CircleAvatar(
                                  radius: 56,
                                  backgroundColor: Colors.white,
                                  child: CircularProgressIndicator(),
                                ),
                                error: (_, __) => CircleAvatar(
                                  radius: 56,
                                  backgroundColor: Colors.white,
                                  child: Text(
                                    userName[0].toUpperCase(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF3D5CFF),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // Edit Profile Picture Hint
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.camera_alt,
                              size: 14,
                              color: Colors.white.withOpacity(0.8),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Tap to edit',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // User Name
                      Text(
                        userName,
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // User Email
                      Text(
                        userEmail,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Stats Cards
              // SlideTransition(
              //   position: _slideAnimation,
              //   child: Padding(
              //     padding: const EdgeInsets.symmetric(horizontal: 24),
              //     child: Row(
              //       children: [
              //         Expanded(
              //           child: _buildStatCard(
              //             'Books Read',
              //             userStats['books_read'].toString(),
              //             Icons.book,
              //             const Color(0xFF06D6A0),
              //           ),
              //         ),
              //         const SizedBox(width: 16),
              //         Expanded(
              //           child: _buildStatCard(
              //             'Reading Streak',
              //             '${userStats['reading_streak']} days',
              //             Icons.local_fire_department,
              //             const Color(0xFFFF6B6B),
              //           ),
              //         ),
              //       ],
              //     ),
              //   ),
              // ),
              
              // const SizedBox(height: 16),
              
              // SlideTransition(
              //   position: _slideAnimation,
              //   child: Padding(
              //     padding: const EdgeInsets.symmetric(horizontal: 24),
              //     child: Row(
              //       children: [
              //         Expanded(
              //           child: _buildStatCard(
              //             'Favorite Genre',
              //             userStats['favorite_genre'],
              //             Icons.favorite,
              //             const Color(0xFFFFE66D),
              //           ),
              //         ),
              //         const SizedBox(width: 16),
              //         Expanded(
              //           child: _buildStatCard(
              //             'This Month',
              //             '${userStats['books_this_month']} books',
              //             Icons.calendar_today,
              //             const Color(0xFF4ECDC4),
              //           ),
              //         ),
              //       ],
              //     ),
              //   ),
              // ),
              
              // const SizedBox(height: 32),
              
              // Profile Options
              FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      _buildProfileOption(
                        icon: Icons.edit,
                        title: 'Edit Profile',
                        subtitle: 'Update your personal information',
                        onTap: () {
                          // Navigate to edit profile
                        },
                      ),
                      _buildProfileOption(
                        icon: Icons.notifications,
                        title: 'Notifications',
                        subtitle: 'Manage your notification preferences',
                        onTap: () {
                          // Navigate to notifications settings
                        },
                      ),
                      // _buildProfileOption(
                      //   icon: Icons.security,
                      //   title: 'Privacy & Security',
                      //   subtitle: 'Manage your privacy settings',
                      //   onTap: () {
                      //     // Navigate to privacy settings
                      //   },
                      // ),
                      // _buildProfileOption(
                      //   icon: Icons.help,
                      //   title: 'Help & Support',
                      //   subtitle: 'Get help and contact support',
                      //   onTap: () {
                      //     // Navigate to help
                      //   },
                      // ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Logout Button
              FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        // Show confirmation dialog
                        final shouldLogout = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(
                              'Logout',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                            ),
                            content: Text(
                              'Are you sure you want to logout?',
                              style: GoogleFonts.poppins(),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text('Cancel', style: GoogleFonts.poppins()),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(
                                  'Logout',
                                  style: GoogleFonts.poppins(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                        
                        if (shouldLogout == true && context.mounted) {
                          await ref.read(authControllerProvider.notifier).signOut();
                          context.go('/login');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[50],
                        foregroundColor: Colors.red[600],
                        elevation: 0,
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.red[200]!),
                        ),
                      ),
                      icon: const Icon(Icons.logout),
                      label: Text(
                        'Logout',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3D5CFF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF3D5CFF),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}