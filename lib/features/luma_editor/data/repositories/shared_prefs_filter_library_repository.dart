import 'dart:convert';

import 'package:lama/features/luma_editor/domain/entities/filter_item.dart';
import 'package:lama/features/luma_editor/domain/repositories/filter_library_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsFilterLibraryRepository implements FilterLibraryRepository {
  static const _customFiltersKey = 'luma_custom_filters_v3';
  static const _favoritesKey = 'luma_favorites_v3';

  @override
  Future<List<FilterItem>> loadCustomFilters() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_customFiltersKey);
    if (raw == null || raw.trim().isEmpty) {
      return [];
    }

    try {
      final decoded = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      return decoded.map(FilterItem.fromJson).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<Set<String>> loadFavorites() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_favoritesKey);
    if (raw == null || raw.trim().isEmpty) {
      return <String>{};
    }

    try {
      final decoded = (jsonDecode(raw) as List).cast<String>();
      return decoded.toSet();
    } catch (_) {
      return <String>{};
    }
  }

  @override
  Future<void> saveCustomFilters(List<FilterItem> customs) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = jsonEncode(customs.map((filter) => filter.toJson()).toList());
    await preferences.setString(_customFiltersKey, raw);
  }

  @override
  Future<void> saveFavorites(Set<String> ids) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_favoritesKey, jsonEncode(ids.toList()));
  }
}
