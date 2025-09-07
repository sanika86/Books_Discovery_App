import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fast_contacts/fast_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../profile/providers/profile_providers.dart';

// Contact Model for better handling
class ContactModel {
  final String id;
  final String displayName;
  final String? phoneNumber;
  final String? email;
  final List<int>? avatar;
  final String? avatarUrl; 

  ContactModel({
    required this.id,
    required this.displayName,
    this.phoneNumber,
    this.email,
    this.avatar, this.avatarUrl,
  });

  factory ContactModel.fromFastContact(Contact contact) {
    return ContactModel(
      id: contact.id ?? '',
      displayName: contact.displayName.isNotEmpty ? contact.displayName : 'Unknown',
      phoneNumber: contact.phones.isNotEmpty ? contact.phones.first.number : null,
      email: contact.emails.isNotEmpty ? contact.emails.first.address : null,
      avatar: null, // fast_contacts doesn't provide avatar directly
       avatarUrl: null,
    );
  }
}

// Contacts Provider
final contactsProvider = FutureProvider<List<ContactModel>>((ref) async {
  final permission = await Permission.contacts.request();
  
  if (permission.isGranted) {
    final contacts = await FastContacts.getAllContacts();
    return contacts.map((contact) => ContactModel.fromFastContact(contact)).toList();
  } else {
    throw Exception('Contacts permission denied');
  }
});

class ContactsPage extends ConsumerStatefulWidget {
  const ContactsPage({super.key});

  @override
  ConsumerState<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends ConsumerState<ContactsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<ContactModel> _filteredContacts = [];
  List<ContactModel> _allContacts = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterContacts(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredContacts = _allContacts;
      });
    } else {
      setState(() {
        _filteredContacts = _allContacts.where((contact) {
          return contact.displayName.toLowerCase().contains(query.toLowerCase()) ||
              (contact.phoneNumber?.contains(query) ?? false) ||
              (contact.email?.toLowerCase().contains(query.toLowerCase()) ?? false);
        }).toList();
      });
    }
  }

  void _showContactBottomSheet(ContactModel contact) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ContactBottomSheet(contact: contact),
    );
  }

 void _showCurrentUserBottomSheet() {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    // Get the profile picture URL using the provider
    final profilePictureAsync = ref.read(profilePictureProvider);
    
    String? avatarUrl;
    profilePictureAsync.when(
      data: (url) => avatarUrl = url,
      loading: () => avatarUrl = null,
      error: (_, __) => avatarUrl = null,
    );
    
    final currentUserContact = ContactModel(
      id: user.uid,
      displayName: user.displayName ?? user.email?.split('@').first ?? 'You',
      email: user.email,
      phoneNumber: user.phoneNumber,
      avatarUrl: avatarUrl, // Add the avatar URL
    );
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ContactBottomSheet(
        contact: currentUserContact,
        isCurrentUser: true,
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(contactsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Contacts',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
          ),
        ),
        actions: [
          // In the AppBar actions
IconButton(
  onPressed: _showCurrentUserBottomSheet,
  icon: Consumer(
    builder: (context, ref, child) {
      final profilePicture = ref.watch(profilePictureProvider);
      
      return profilePicture.when(
        data: (imageUrl) => CircleAvatar(
          radius: 20,
          backgroundColor: const Color(0xFF3D5CFF),
          backgroundImage: imageUrl != null
              ? NetworkImage(imageUrl)
              : const AssetImage("assets/Avatar.png") as ImageProvider,
          child: imageUrl == null
              ? Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 18,
                )
              : null,
        ),
        loading: () => const CircleAvatar(
          radius: 18,
          backgroundColor: Color(0xFF3D5CFF),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
        error: (_, __) => const CircleAvatar(
          radius: 18,
          backgroundColor: Color(0xFF3D5CFF),
          child: Icon(
            Icons.person,
            color: Colors.white,
            size: 18,
          ),
        ),
      );
    },
  ),
),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _filterContacts,
                decoration: InputDecoration(
                  hintText: 'Search contacts...',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 16,
                    color: const Color(0xFF9CA3AF),
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF9CA3AF),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),

          // Contacts List
          Expanded(
            child: contactsAsync.when(
              data: (contacts) {
                if (_allContacts.isEmpty) {
                  _allContacts = contacts;
                  _filteredContacts = contacts;
                }

                final displayContacts = _filteredContacts;

                if (displayContacts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.contacts,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isEmpty 
                              ? 'No contacts found'
                              : 'No contacts match your search',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: displayContacts.length,
                  itemBuilder: (context, index) {
                    final contact = displayContacts[index];
                    return _buildContactItem(contact);
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF3D5CFF),
                ),
              ),
              error: (error, stackTrace) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Permission Required',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.red[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please grant contacts permission\nto view your contacts',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        // Open app settings to grant permission
                        await openAppSettings();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3D5CFF),
                      ),
                      child: const Text('Grant Permission'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        // Retry permission request
                        ref.refresh(contactsProvider);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(ContactModel contact) {
  return GestureDetector(
    onTap: () => _showContactBottomSheet(contact),
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          // Avatar with profile image or fallback
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF3D5CFF).withOpacity(0.1),
            backgroundImage: contact.avatarUrl != null 
                ? NetworkImage(contact.avatarUrl!)
                : null,
            child: contact.avatarUrl == null
                ? Text(
                    contact.displayName.isNotEmpty 
                        ? contact.displayName[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3D5CFF),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          
          // Contact Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.displayName,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                if (contact.phoneNumber != null)
                  Text(
                    contact.phoneNumber!,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF6B7280),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          
          // Arrow indicator
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey[400],
          ),
        ],
      ),
    ),
  );
}
}

// Contact Bottom Sheet Widget
class ContactBottomSheet extends StatelessWidget {
  final ContactModel contact;
  final bool isCurrentUser;

  const ContactBottomSheet({
    super.key,
    required this.contact,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            
            // Avatar
           CircleAvatar(
              radius: 50,
              backgroundColor: const Color(0xFF3D5CFF).withOpacity(0.1),
              backgroundImage: contact.avatarUrl != null 
                  ? NetworkImage(contact.avatarUrl!)
                  : null,
              child: contact.avatarUrl == null
                  ? Text(
                      contact.displayName.isNotEmpty 
                          ? contact.displayName[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3D5CFF),
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            
            // Name
            Text(
              contact.displayName,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
              textAlign: TextAlign.center,
            ),
            
            if (isCurrentUser)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF3D5CFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'You',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3D5CFF),
                  ),
                ),
              ),
            
            const SizedBox(height: 24),
            
            // Contact Details
            if (contact.phoneNumber != null) ...[
              _buildDetailRow(
                Icons.phone,
                'Phone',
                contact.phoneNumber!,
              ),
              const SizedBox(height: 16),
            ],
            
            if (contact.email != null) ...[
              _buildDetailRow(
                Icons.email,
                'Email',
                contact.email!,
              ),
              const SizedBox(height: 16),
            ],
            
            // Action buttons for non-current user
            if (!isCurrentUser) ...[
              Row(
                children: [
                  if (contact.phoneNumber != null) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          // You can add url_launcher here to actually make calls
                          // launch('tel:${contact.phoneNumber}');
                        },
                        icon: const Icon(Icons.phone),
                        label: const Text('Call'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (contact.email != null)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          // You can add url_launcher here to send emails
                          // launch('mailto:${contact.email}');
                        },
                        icon: const Icon(Icons.email),
                        label: const Text('Email'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3D5CFF),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF3D5CFF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF3D5CFF),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: const Color(0xFF111827),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
