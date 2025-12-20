import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/news.dart';
import '../repository/news_repository.dart';
import 'news_states.dart';

class NewsCubit extends Cubit<NewsState> {
  final NewsRepository _repository;

  NewsCubit(this._repository) : super(const NewsState());

  Future<void> fetchNews() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final news = await _repository.getNews();
      emit(state.copyWith(news: news, isLoading: false));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to fetch news: $e', isLoading: false));
    }
  }

  Future<void> addNews(News news) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      await _repository.addNews(news);
      await fetchNews();
    } catch (e) {
      emit(state.copyWith(error: 'Failed to add news: $e', isLoading: false));
    }
  }

  Future<void> updateNews(News news) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      await _repository.updateNews(news);
      await fetchNews();
    } catch (e) {
      emit(state.copyWith(error: 'Failed to update news: $e', isLoading: false));
    }
  }

  Future<void> deleteNews(String id) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      await _repository.deleteNews(id);
      await fetchNews();
    } catch (e) {
      emit(state.copyWith(error: 'Failed to delete news: $e', isLoading: false));
    }
  }
}

