import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:front/models/search_model.dart';

class SearchService {
  static const String _searchHistoryKey = 'search_history';
  static const int _maxHistoryItems = 10;

  // 검색 기록 저장
  static Future<void> addSearchHistory(String query) async {
    if (query.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final history = await getSearchHistory();

    // 중복 제거
    history.removeWhere((item) => item.query == query);

    // 새 검색어 추가
    history.insert(0, SearchHistory(query: query, timestamp: DateTime.now()));

    // 최대 개수 제한
    if (history.length > _maxHistoryItems) {
      history.removeRange(_maxHistoryItems, history.length);
    }

    // 저장
    final jsonList = history.map((item) => item.toJson()).toList();
    await prefs.setString(_searchHistoryKey, jsonEncode(jsonList));
  }

  // 검색 기록 가져오기
  static Future<List<SearchHistory>> getSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_searchHistoryKey);

    if (jsonString == null) return [];

    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((json) => SearchHistory.fromJson(json)).toList();
  }

  // 검색 기록 삭제
  static Future<void> removeSearchHistory(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getSearchHistory();

    history.removeWhere((item) => item.query == query);

    final jsonList = history.map((item) => item.toJson()).toList();
    await prefs.setString(_searchHistoryKey, jsonEncode(jsonList));
  }

  // 모든 검색 기록 삭제
  static Future<void> clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_searchHistoryKey);
  }
}
