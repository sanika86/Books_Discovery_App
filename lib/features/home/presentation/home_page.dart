import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

import '../../profile/providers/profile_providers.dart';
import '../model/home_model.dart';
import '../provider/search_provider.dart';

// Books API Service
class BooksApiService {
  static const String _baseUrl = 'https://www.googleapis.com/books/v1/volumes';

  Future<List<Book>> searchBooks(String query, {int maxResults = 20}) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$_baseUrl?q=${Uri.encodeComponent(query)}&maxResults=$maxResults'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List<dynamic>? ?? [];

        return items.map((item) => Book.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load books: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching books: $e');
    }
  }

  Future<List<Book>> getBooksByAuthor(String author,
      {int maxResults = 10}) async {
    try {
      final query = 'inauthor:${Uri.encodeComponent(author)}';
      final response = await http.get(
        Uri.parse('$_baseUrl?q=$query&maxResults=$maxResults'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List<dynamic>? ?? [];

        return items.map((item) => Book.fromJson(item)).toList();
      } else {
        throw Exception(
            'Failed to load books by author: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting books by author: $e');
    }
  }

  // New method to get popular/trending books
  Future<List<Book>> getPopularBooks({int maxResults = 20}) async {
    try {
      // Search for popular books using common popular topics
      const popularQueries = [
        'bestsellers',
        'fiction',
        'programming',
        'business',
        'science',
        'history',
        'psychology',
        'cooking'
      ];

      final randomQuery =
          popularQueries[Random().nextInt(popularQueries.length)];

      final response = await http.get(
        Uri.parse(
            '$_baseUrl?q=$randomQuery&orderBy=relevance&maxResults=$maxResults'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List<dynamic>? ?? [];

        return items.map((item) => Book.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load popular books: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting popular books: $e');
    }
  }
}

// Search History Provider
final searchHistoryProvider =
    StateNotifierProvider<SearchHistoryNotifier, List<String>>((ref) {
  return SearchHistoryNotifier();
});

class SearchHistoryNotifier extends StateNotifier<List<String>> {
  SearchHistoryNotifier() : super([]) {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('search_history') ?? [];
    state = history;
  }

  Future<void> addSearchTerm(String term) async {
    if (term.trim().isEmpty) return;

    final newHistory =
        [term, ...state.where((item) => item != term)].take(10).toList();
    state = newHistory;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('search_history', newHistory);
  }

  Future<void> clearHistory() async {
    state = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('search_history');
  }
}

// Books Search Provider
final booksSearchProvider =
    StateNotifierProvider<BooksSearchNotifier, AsyncValue<List<Book>>>((ref) {
  return BooksSearchNotifier();
});

class BooksSearchNotifier extends StateNotifier<AsyncValue<List<Book>>> {
  BooksSearchNotifier() : super(const AsyncValue.loading()) {
    // Load popular books by default
    _loadDefaultBooks();
  }

  final _apiService = BooksApiService();
  bool _isSearchMode = false;

  Future<void> _loadDefaultBooks() async {
    try {
      final books = await _apiService.getPopularBooks();
      state = AsyncValue.data(books);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> searchBooks(String query) async {
    if (query.trim().isEmpty) {
      _isSearchMode = false;
      await _loadDefaultBooks();
      return;
    }

    _isSearchMode = true;
    state = const AsyncValue.loading();

    try {
      final books = await _apiService.searchBooks(query);
      state = AsyncValue.data(books);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<List<Book>> getBooksByAuthor(String author) async {
    try {
      return await _apiService.getBooksByAuthor(author);
    } catch (e) {
      return [];
    }
  }

  bool get isSearchMode => _isSearchMode;
}

// Analytics Data Provider (for storing search results)
final analyticsDataProvider =
    StateNotifierProvider<AnalyticsDataNotifier, List<Book>>((ref) {
  return AnalyticsDataNotifier();
});

class AnalyticsDataNotifier extends StateNotifier<List<Book>> {
  AnalyticsDataNotifier() : super([]);

  void addBooks(List<Book> books) {
    final existingIds = state.map((book) => book.id).toSet();
    final newBooks =
        books.where((book) => !existingIds.contains(book.id)).toList();
    state = [...state, ...newBooks];
  }
}

// Enhanced Book class to include price generation
extension BookPricing on Book {
  double get price {
    // Generate a pseudo-random price based on book ID hash
    final hash = id.hashCode.abs();
    final basePrice = 99 + (hash % 401); // Price between ₹99 and ₹500
    return basePrice.toDouble();
  }

  double get discountedPrice {
    final discount = (id.hashCode.abs() % 30) / 100; // 0-30% discount
    return price * (1 - discount);
  }

  int get discountPercentage {
    return ((price - discountedPrice) / price * 100).round();
  }
}

// Home Page Implementation
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _showSearchHistory = false;

  void _performSearch(String query) {
    if (query.trim().isNotEmpty) {
      ref.read(searchHistoryProvider.notifier).addSearchTerm(query);
      ref.read(booksSearchProvider.notifier).searchBooks(query);
      setState(() {
        _showSearchHistory = false;
      });
      FocusScope.of(context).unfocus();
    }
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(booksSearchProvider.notifier).searchBooks('');
    setState(() {
      _showSearchHistory = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(booksSearchProvider);
    final searchHistory = ref.watch(searchHistoryProvider);
    final isSearchMode = ref.read(booksSearchProvider.notifier).isSearchMode;

    // Add search results to analytics data
    searchResults.whenData((books) {
      if (books.isNotEmpty) {
        ref.read(analyticsDataProvider.notifier).addBooks(books);
      }
    });

    // Focus on search field if shouldFocus is true
    final shouldFocus = ref.watch(searchFocusProvider);
    if (shouldFocus) {
      Future.microtask(() {
        _searchFocusNode.requestFocus();
        ref.read(searchFocusProvider.notifier).state = false;
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Expanded(
              child: Text(
                'Course',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
            ),
            Consumer(
              builder: (context, ref, _) {
                final profilePicture = ref.watch(profilePictureProvider);
                final user = FirebaseAuth.instance.currentUser;
                final userName =
                    user?.displayName ?? user?.email?.split('@').first ?? 'U';

                return profilePicture.when(
                  data: (imageUrl) {
                    return CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFF3D5CFF),
                      backgroundImage:
                          imageUrl != null ? NetworkImage(imageUrl) : null,
                      child: imageUrl == null
                          ? Text(
                              userName[0].toUpperCase(),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          : null,
                    );
                  },
                  loading: () => const CircleAvatar(
                    radius: 20,
                    backgroundColor: Color(0xFF3D5CFF),
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  error: (_, __) => CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF3D5CFF),
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Search Bar with History
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onSubmitted: _performSearch,
                      onChanged: (value) {
                        if (value.isEmpty) {
                          _clearSearch();
                        }
                      },
                      onTap: () {
                        setState(() {
                          _showSearchHistory = true;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Find Course',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 16,
                          color: const Color(0xFF9CA3AF),
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFF9CA3AF),
                        ),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_searchController.text.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.clear,
                                    color: Color(0xFF9CA3AF)),
                                onPressed: _clearSearch,
                              ),
                            IconButton(
                              icon: const Icon(Icons.tune,
                                  color: Color(0xFF9CA3AF)),
                              onPressed: () {
                                context.push('/search-filter');
                              },
                            ),
                          ],
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  // Search History Dropdown
                  if (_showSearchHistory && searchHistory.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: searchHistory.take(5).map((term) {
                          return ListTile(
                            leading: const Icon(Icons.history, size: 20),
                            title: Text(term),
                            onTap: () {
                              _searchController.text = term;
                              _performSearch(term);
                            },
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),

            // Category Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildCategoryCard(
                      '',
                      const Color(0xFFCEECFE), // Light blue background #CEECFE
                      'assets/language.png',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCategoryCard(
                      '',
                      const Color(
                          0xFFEFE0FF), // Light purple background #EFE0FF
                      'assets/Frame.png',
                    ),
                  ),
                ],
              ),
            ),

            // Choice your course section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isSearchMode ? 'Search Results' : 'Courses',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  Icon(
                    Icons.grid_view,
                    color: const Color(0xFF3D5CFF),
                  ),
                ],
              ),
            ),

            // Filter Tabs
            if (!isSearchMode)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    _buildFilterTab('All', true),
                    const SizedBox(width: 12),
                    _buildFilterTab('Popular', false),
                    const SizedBox(width: 12),
                    _buildFilterTab('New', false),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Books List
            searchResults.when(
              data: (books) {
                if (books.isEmpty && isSearchMode) {
                  return Container(
                    height: 200,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No books found',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: books.length,
                  itemBuilder: (context, index) {
                    final book = books[index];
                    return _buildBookItem(book);
                  },
                );
              },
              loading: () => Container(
                height: 200,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF3D5CFF),
                  ),
                ),
              ),
              error: (error, stackTrace) => Container(
                height: 200,
                child: Center(
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
                        'Error loading books',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: Colors.red[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref
                              .read(booksSearchProvider.notifier)
                              ._loadDefaultBooks();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3D5CFF),
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Add some bottom padding
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

Widget _buildCategoryCard(String title, Color bgColor, String imagePath) {
  return GestureDetector(
    onTap: () {
      _searchController.text = title.toLowerCase();
      _performSearch(title.toLowerCase());
    },
    child: Container(
      height: 100,
      decoration: BoxDecoration(
        color: bgColor, // Background color applied first
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Image positioned on the left side (no fill, no overlay)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 120, // Adjust width as needed
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback when image doesn't load - show icon
                  return Container(
                    color: Colors.white.withOpacity(0.1),
                    child: Center(
                      child: Icon(
                        title == 'Language' ? Icons.language : Icons.palette,
                        color: Colors.white.withOpacity(0.7),
                        size: 32,
                      ),
                    ),
                  );
                },
              ),
            ),
            // Text positioned on the right side
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              left: 130, // Leave space for image
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: title == '' 
                        ? const Color(0xFF4285F4) // Blue text for Language
                        : const Color(0xFF9C27B0), // Purple text for Painting
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildFilterTab(String title, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF3D5CFF) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isSelected ? Colors.white : const Color(0xFF6B7280),
        ),
      ),
    );
  }

  Widget _buildBookItem(Book book) {
    final bookPrice = book.price;
    final discountedPrice = book.discountedPrice;
    final discountPercent = book.discountPercentage;

    return GestureDetector(
      onTap: () {
        context.push('/book-detail', extra: book);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 60,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
                image: book.thumbnail != null
                    ? DecorationImage(
                        image: NetworkImage(book.thumbnail!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: book.thumbnail == null
                  ? const Icon(Icons.book, color: Colors.grey)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (book.authors.isNotEmpty)
                    Text(
                      book.authors.join(', '),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF6B7280),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        book.categories.isNotEmpty
                            ? book.categories.first
                            : 'General',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF3D5CFF),
                        ),
                      ),
                      if (book.averageRating != null) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 2),
                        Text(
                          book.averageRating!.toStringAsFixed(1),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Price section
                  Row(
                    children: [
                      Text(
                        '₹${discountedPrice.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF059669),
                        ),
                      ),
                      if (discountPercent > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          '₹${bookPrice.toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: const Color(0xFF9CA3AF),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$discountPercent% OFF',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF059669),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// BookDetailPage remains the same as your original implementation
class BookDetailPage extends ConsumerWidget {
  final Book book;

  const BookDetailPage({super.key, required this.book});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookPrice = book.price;
    final discountedPrice = book.discountedPrice;
    final discountPercent = book.discountPercentage;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Book Details',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: book.thumbnail != null
                        ? DecorationImage(
                            image: NetworkImage(book.thumbnail!),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: Colors.grey[300],
                  ),
                  child: book.thumbnail == null
                      ? const Icon(Icons.book, size: 48, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (book.authors.isNotEmpty)
                        Text(
                          'By ${book.authors.join(', ')}',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      const SizedBox(height: 8),
                      if (book.averageRating != null)
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              book.averageRating!.toStringAsFixed(1),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 12),
                      // Price section in detail page
                      Row(
                        children: [
                          Text(
                            '₹${discountedPrice.toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF059669),
                            ),
                          ),
                          if (discountPercent > 0) ...[
                            const SizedBox(width: 12),
                            Text(
                              '₹${bookPrice.toStringAsFixed(0)}',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                color: const Color(0xFF9CA3AF),
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (discountPercent > 0)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$discountPercent% OFF',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF059669),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (book.description != null) ...[
              Text(
                'Description',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                book.description!,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
            ],
            if (book.authors.isNotEmpty) ...[
              Text(
                'Other books by ${book.authors.first}',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<Book>>(
                future: ref
                    .read(booksSearchProvider.notifier)
                    .getBooksByAuthor(book.authors.first),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError ||
                      !snapshot.hasData ||
                      snapshot.data!.isEmpty) {
                    return Text(
                      'No other books found by this author',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF6B7280),
                      ),
                    );
                  }

                  final otherBooks = snapshot.data!
                      .where((b) => b.id != book.id)
                      .take(5)
                      .toList();

                  return Column(
                    children: otherBooks.map((otherBook) {
                      return GestureDetector(
                        onTap: () {
                          // Navigate to another book detail with stacked navigation
                          context.push('/book-detail', extra: otherBook);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  image: otherBook.thumbnail != null
                                      ? DecorationImage(
                                          image: NetworkImage(
                                              otherBook.thumbnail!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                  color: Colors.grey[300],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      otherBook.title,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF111827),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '₹${otherBook.discountedPrice.toStringAsFixed(0)}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF059669),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  // Add to wishlist functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Added to wishlist'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF3D5CFF)),
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_border,
                      color: const Color(0xFF3D5CFF),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Wishlist',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: const Color(0xFF3D5CFF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  // Add to cart or buy now functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added "${book.title}" to cart'),
                      duration: const Duration(seconds: 2),
                      action: SnackBarAction(
                        label: 'View Cart',
                        onPressed: () {
                          // Navigate to cart
                        },
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3D5CFF),
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.shopping_cart, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Add to Cart',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// SEARCH FILTER PAGE - Enhanced with better functionality
// ============================================================================
class SearchFilterPage extends ConsumerStatefulWidget {
  const SearchFilterPage({super.key});

  @override
  ConsumerState<SearchFilterPage> createState() => _SearchFilterPageState();
}

class _SearchFilterPageState extends ConsumerState<SearchFilterPage> {
  final List<String> categories = [
    'Fiction',
    'Sci-fi',
    'Biography',
    'Music',
    'Non-fiction',
    'Programming',
    'Business',
    'History',
    'Psychology',
    'Cooking'
  ];

  List<String> selectedCategories = ['Fiction'];
  double minPrice = 90;
  double maxPrice = 200;
  double minRating = 0;
  bool showDiscountedOnly = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // App Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    'Search Filter',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                    ),
                  ),
                ),
                const SizedBox(width: 48), // Balance the close button
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Categories Section
                  Text(
                    'Categories',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((category) {
                      final isSelected = selectedCategories.contains(category);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              selectedCategories.remove(category);
                            } else {
                              selectedCategories.add(category);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF3D5CFF)
                                : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            category,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 32),

                  // Price Range Section
                  Text(
                    'Price Range',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 16),
                  RangeSlider(
                    values: RangeValues(minPrice, maxPrice),
                    min: 50,
                    max: 500,
                    divisions: 45,
                    activeColor: const Color(0xFF3D5CFF),
                    labels: RangeLabels(
                      '₹${minPrice.round()}',
                      '₹${maxPrice.round()}',
                    ),
                    onChanged: (RangeValues values) {
                      setState(() {
                        minPrice = values.start;
                        maxPrice = values.end;
                      });
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${minPrice.round()}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      Text(
                        '₹${maxPrice.round()}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Action Buttons (Fixed at bottom)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        selectedCategories.clear();
                        selectedCategories.add('Fiction');
                        minPrice = 90;
                        maxPrice = 200;
                        minRating = 0;
                        showDiscountedOnly = false;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF3D5CFF)),
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Clear',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: const Color(0xFF3D5CFF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Filters applied: ${selectedCategories.length} categories, '
                            '₹${minPrice.round()}-₹${maxPrice.round()}',
                          ),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3D5CFF),
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Apply Filter',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
