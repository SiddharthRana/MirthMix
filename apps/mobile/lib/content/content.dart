import 'dart:convert';

import 'package:flutter/services.dart';

/// Mirrors packages/content/src/schema.ts. The packs are validated there in CI; the app
/// re-checks the essentials so a damaged asset becomes an error screen, not a crash.
enum Tier { free, premium }

enum AgeRating { all, teen }

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.description,
    required this.tier,
    required this.ageRating,
    required this.region,
    this.contentNote,
  });

  final String id;
  final String name;
  final String description;
  final Tier tier;
  final AgeRating ageRating;
  final String region;
  final String? contentNote;

  factory Category.fromJson(Map<String, dynamic> j) => Category(
    id: j['id'] as String,
    name: j['name'] as String,
    description: j['description'] as String,
    tier: Tier.values.byName(j['tier'] as String),
    ageRating: j['ageRating'] == '13+' ? AgeRating.teen : AgeRating.all,
    region: j['region'] as String,
    contentNote: j['contentNote'] as String?,
  );
}

class WyrItem {
  const WyrItem({required this.id, required this.category, required this.a, required this.b});

  final String id;
  final String category;
  final String a;
  final String b;

  factory WyrItem.fromJson(Map<String, dynamic> j) =>
      WyrItem(id: j['id'] as String, category: j['category'] as String, a: j['a'] as String, b: j['b'] as String);
}

class WyrPack {
  WyrPack({required this.categories, required this.items}) : _byId = {for (final i in items) i.id: i};

  final List<Category> categories;
  final List<WyrItem> items;
  final Map<String, WyrItem> _byId;

  WyrItem? item(String id) => _byId[id];
  Category? category(String id) => categories.where((c) => c.id == id).firstOrNull;
  int countIn(Iterable<String> categoryIds) {
    final wanted = categoryIds.toSet();
    return items.where((i) => wanted.contains(i.category)).length;
  }

  /// Parses and checks a pack. Throws [FormatException] on anything the game can't use.
  factory WyrPack.parse(String source) {
    final Object? json;
    try {
      json = jsonDecode(source);
    } on FormatException catch (e) {
      throw FormatException('Invalid JSON: ${e.message}');
    }
    if (json is! Map<String, dynamic> || json['mode'] != 'would-you-rather') {
      throw const FormatException('Not a Would You Rather pack');
    }
    try {
      final categories = (json['categories'] as List<dynamic>)
          .map((c) => Category.fromJson(c as Map<String, dynamic>))
          .toList();
      final items = (json['items'] as List<dynamic>).map((i) => WyrItem.fromJson(i as Map<String, dynamic>)).toList();
      final ids = categories.map((c) => c.id).toSet();
      final seen = <String>{};
      for (final i in items) {
        if (!ids.contains(i.category)) throw FormatException('${i.id}: unknown category ${i.category}');
        if (!seen.add(i.id)) throw FormatException('duplicate id ${i.id}');
        if (i.a.trim().isEmpty || i.b.trim().isEmpty) throw FormatException('${i.id}: empty option');
      }
      if (categories.isEmpty || items.isEmpty) throw const FormatException('Pack is empty');
      return WyrPack(categories: categories, items: items);
    } on TypeError catch (e) {
      throw FormatException('Malformed pack: $e');
    } on ArgumentError catch (e) {
      throw FormatException('Malformed pack: ${e.message}');
    }
  }
}

/// Everything the app can play. Loaded once at startup.
class ContentLibrary {
  const ContentLibrary({required this.wyr});

  final WyrPack wyr;

  static Future<ContentLibrary> load(AssetBundle bundle) async {
    final wyr = WyrPack.parse(await bundle.loadString('assets/content/would-you-rather.json'));
    return ContentLibrary(wyr: wyr);
  }
}
