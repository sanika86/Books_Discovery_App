import 'package:ds_books_app/features/home/presentation/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;

import '../models/analytics_models.dart';

// Genre Distribution Provider
final genreDistributionProvider = Provider<List<GenreData>>((ref) {
  // Get books from the home page analytics data
  final analyticsBooks = ref.watch(analyticsDataProvider);
  
  // Define colors for genres
  const genreColors = {
    'Fiction': Color(0xFF3D5CFF),
    'Non-fiction': Color(0xFF06D6A0),
    'Romance': Color(0xFFFF6B6B),
    'Sci-fi': Color(0xFF4ECDC4),
    'Thriller': Color(0xFFFFE66D),
    'History': Color(0xFF95E1D3),
    'Biography': Color(0xFFE056FD),
  };

  // Count books by genre from real data or use dummy data
  Map<String, int> genreCounts = {};
  
  if (analyticsBooks.isNotEmpty) {
    // Use real data from searched books
    for (final book in analyticsBooks) {
      for (final category in book.categories) {
        String normalizedGenre = _normalizeGenre(category);
        genreCounts[normalizedGenre] = (genreCounts[normalizedGenre] ?? 0) + 1;
      }
    }
  } else {
    // Use dummy data if no real data available
    genreCounts = {
      'Fiction': 35,
      'Non-fiction': 28,
      'Romance': 18,
      'Sci-fi': 15,
      'Thriller': 12,
      'History': 8,
      'Biography': 6,
    };
  }

  return genreCounts.entries
      .map((entry) => GenreData(
            genre: entry.key,
            count: entry.value,
            color: genreColors[entry.key] ?? Colors.grey,
          ))
      .toList()
    ..sort((a, b) => b.count.compareTo(a.count));
});

String _normalizeGenre(String category) {
  final normalized = category.toLowerCase();
  if (normalized.contains('fiction') && !normalized.contains('non')) return 'Fiction';
  if (normalized.contains('non-fiction') || normalized.contains('nonfiction')) return 'Non-fiction';
  if (normalized.contains('romance')) return 'Romance';
  if (normalized.contains('science') || normalized.contains('sci-fi')) return 'Sci-fi';
  if (normalized.contains('thriller') || normalized.contains('mystery')) return 'Thriller';
  if (normalized.contains('history')) return 'History';
  if (normalized.contains('biography') || normalized.contains('memoir')) return 'Biography';
  return 'Fiction'; // Default fallback
}

// Publishing Trend Provider
final publishingTrendProvider = Provider<List<PublishingTrendData>>((ref) {
  return [
    PublishingTrendData(year: 2021, bookCount: 850),
    PublishingTrendData(year: 2022, bookCount: 920),
    PublishingTrendData(year: 2023, bookCount: 1150),
    PublishingTrendData(year: 2024, bookCount: 1280),
    PublishingTrendData(year: 2025, bookCount: 1100), // Projected
  ];
});

// Sales Overview Provider
final salesOverviewProvider = Provider<List<SalesData>>((ref) {
  return [
    SalesData(period: 'Jan', revenue: 12500, month: 1),
    SalesData(period: 'Feb', revenue: 15800, month: 2),
    SalesData(period: 'Mar', revenue: 18200, month: 3),
    SalesData(period: 'Apr', revenue: 22100, month: 4),
    SalesData(period: 'May', revenue: 19800, month: 5),
    SalesData(period: 'Jun', revenue: 25600, month: 6),
    SalesData(period: 'Jul', revenue: 28900, month: 7),
    SalesData(period: 'Aug', revenue: 31200, month: 8),
    SalesData(period: 'Sep', revenue: 27800, month: 9),
    SalesData(period: 'Oct', revenue: 33500, month: 10),
    SalesData(period: 'Nov', revenue: 36700, month: 11),
    SalesData(period: 'Dec', revenue: 42100, month: 12),
  ];
});