import '../models/news.dart';

class NewsState {
  final List<News> news;
  final bool isLoading;
  final String? error;

  const NewsState({
    this.news = const [],
    this.isLoading = false,
    this.error,
  });

  NewsState copyWith({
    List<News>? news,
    bool? isLoading,
    String? error,
  }) {
    return NewsState(
      news: news ?? this.news,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

