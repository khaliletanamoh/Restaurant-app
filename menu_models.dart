import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class MenuCategory extends Equatable {
  const MenuCategory({
    required this.id,
    required this.name,
    required this.sortOrder,
    this.isActive = true,
  });

  final String id;
  final String name;
  final int sortOrder;
  final bool isActive;

  factory MenuCategory.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    return MenuCategory(
      id: doc.id,
      name: m['name'] as String? ?? '',
      sortOrder: (m['sortOrder'] as num?)?.toInt() ?? 0,
      isActive: m['isActive'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [id, name, sortOrder, isActive];
}

class MenuItem extends Equatable {
  const MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.priceEtb,
    required this.categoryId,
    this.imageUrl,
    this.isAvailable = true,
    this.isFasting = false,
  });

  final String id;
  final String name;
  final String description;
  final int priceEtb;
  final String categoryId;
  final String? imageUrl;
  final bool isAvailable;
  final bool isFasting;

  factory MenuItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    return MenuItem(
      id: doc.id,
      name: m['name'] as String? ?? '',
      description: m['description'] as String? ?? '',
      priceEtb: (m['priceEtb'] as num?)?.toInt() ?? 0,
      categoryId: m['categoryId'] as String? ?? '',
      imageUrl: m['imageUrl'] as String?,
      isAvailable: m['isAvailable'] as bool? ?? true,
      isFasting: m['isFasting'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, description, priceEtb, categoryId, imageUrl, isAvailable, isFasting];
}
