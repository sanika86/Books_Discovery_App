
import 'package:flutter/material.dart';

class GenreData {
  final String genre;
  final int count;
  final Color color;

  GenreData({
    required this.genre,
    required this.count,
    required this.color,
  });
}

class PublishingTrendData {
  final int year;
  final int bookCount;

  PublishingTrendData({
    required this.year,
    required this.bookCount,
  });
}

class SalesData {
  final String period;
  final double revenue;
  final int month; // For sorting

  SalesData({
    required this.period,
    required this.revenue,
    required this.month,
  });
}