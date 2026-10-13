import 'package:cloud_firestore/cloud_firestore.dart';

import 'menu_models.dart';

class MenuRepository {
  MenuRepository({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Stream<List<MenuCategory>> categories() => _db
      .collection('menuCategories')
      .orderBy('sortOrder')
      .snapshots()
      .map((s) => s.docs.map(MenuCategory.fromDoc).where((c) => c.isActive).toList());

  /// The whole menu is one live list (small collection, served from cache when offline).
  Stream<List<MenuItem>> items() => _db
      .collection('menuItems')
      .orderBy('sortOrder')
      .snapshots()
      .map((s) => s.docs.map(MenuItem.fromDoc).toList());
}
