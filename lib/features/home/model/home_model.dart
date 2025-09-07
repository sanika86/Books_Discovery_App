
// Book Model
class Book {
  final String id;
  final String title;
  final List<String> authors;
  final String? description;
  final String? thumbnail;
  final String? publishedDate;
  final int? pageCount;
  final List<String> categories;
  final double? averageRating;
  final String? language;
  final String? publisher;

  Book({
    required this.id,
    required this.title,
    required this.authors,
    this.description,
    this.thumbnail,
    this.publishedDate,
    this.pageCount,
    required this.categories,
    this.averageRating,
    this.language,
    this.publisher,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    final volumeInfo = json['volumeInfo'] ?? {};

    return Book(
      id: json['id'] ?? '',
      title: volumeInfo['title'] ?? 'Unknown Title',
      authors: List<String>.from(volumeInfo['authors'] ?? []),
      description: volumeInfo['description'],
      thumbnail:
          volumeInfo['imageLinks']?['thumbnail']?.replaceAll('http:', 'https:'),
      publishedDate: volumeInfo['publishedDate'],
      pageCount: volumeInfo['pageCount'],
      categories: List<String>.from(volumeInfo['categories'] ?? []),
      averageRating: volumeInfo['averageRating']?.toDouble(),
      language: volumeInfo['language'],
      publisher: volumeInfo['publisher'],
    );
  }
}
