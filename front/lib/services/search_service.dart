import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:front/models/search_model.dart';
import 'package:front/models/sharehouse_model.dart';

class SearchService {
  static const String _searchHistoryKey = 'search_history';
  static const String _recentViewedKey = 'recent_viewed';
  static const int _maxHistoryItems = 10;
  static const int _maxRecentViewed = 20;

  // ──────────────────────────────────────────
  // 검색 기록
  // ──────────────────────────────────────────

  static Future<void> addSearchHistory(String query) async {
    if (query.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final history = await getSearchHistory();

    history.removeWhere((item) => item.query == query);
    history.insert(0, SearchHistory(query: query, timestamp: DateTime.now()));

    if (history.length > _maxHistoryItems) {
      history.removeRange(_maxHistoryItems, history.length);
    }

    final jsonList = history.map((item) => item.toJson()).toList();
    await prefs.setString(_searchHistoryKey, jsonEncode(jsonList));
  }

  static Future<List<SearchHistory>> getSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_searchHistoryKey);
    if (jsonString == null) return [];

    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((json) => SearchHistory.fromJson(json)).toList();
  }

  static Future<void> removeSearchHistory(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getSearchHistory();
    history.removeWhere((item) => item.query == query);

    final jsonList = history.map((item) => item.toJson()).toList();
    await prefs.setString(_searchHistoryKey, jsonEncode(jsonList));
  }

  static Future<void> clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_searchHistoryKey);
  }

  // ──────────────────────────────────────────
  // 최근 본 매물
  // ──────────────────────────────────────────

  /// 매물 상세 페이지에 진입할 때 호출
  static Future<void> addRecentViewed(SharehouseModel house) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getRecentViewed();

    // 중복 제거 (id 기준)
    list.removeWhere((h) => h.id == house.id);
    list.insert(0, house);

    if (list.length > _maxRecentViewed) {
      list.removeRange(_maxRecentViewed, list.length);
    }

    final jsonList = list.map((h) => h.toJson()).toList();
    await prefs.setString(_recentViewedKey, jsonEncode(jsonList));
  }

  static Future<List<SharehouseModel>> getRecentViewed() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_recentViewedKey);
    if (jsonString == null) return [];

    final jsonList = jsonDecode(jsonString) as List;
    return jsonList
        .map((json) => SharehouseModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<void> clearRecentViewed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentViewedKey);
  }
}
