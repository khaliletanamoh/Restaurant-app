import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'menu_models.dart';
import 'menu_repository.dart';

const _unset = Object();

class MenuState extends Equatable {
  const MenuState({
    this.loading = true,
    this.error,
    this.categories = const [],
    this.items = const [],
    this.categoryId,
    this.query = '',
    this.fastingOnly = false,
  });

  final bool loading;
  final String? error;
  final List<MenuCategory> categories;
  final List<MenuItem> items;
  final String? categoryId;
  final String query;
  final bool fastingOnly;

  List<MenuItem> get visibleItems {
    final q = query.trim().toLowerCase();
    return items.where((i) {
      if (categoryId != null && i.categoryId != categoryId) return false;
      if (fastingOnly && !i.isFasting) return false;
      if (q.isNotEmpty && !i.name.toLowerCase().contains(q)) return false;
      return true;
    }).toList();
  }

  MenuState copyWith({
    bool? loading,
    Object? error = _unset,
    List<MenuCategory>? categories,
    List<MenuItem>? items,
    Object? categoryId = _unset,
    String? query,
    bool? fastingOnly,
  }) {
    return MenuState(
      loading: loading ?? this.loading,
      error: identical(error, _unset) ? this.error : error as String?,
      categories: categories ?? this.categories,
      items: items ?? this.items,
      categoryId: identical(categoryId, _unset) ? this.categoryId : categoryId as String?,
      query: query ?? this.query,
      fastingOnly: fastingOnly ?? this.fastingOnly,
    );
  }

  @override
  List<Object?> get props => [loading, error, categories, items, categoryId, query, fastingOnly];
}

class MenuCubit extends Cubit<MenuState> {
  MenuCubit(this._repo) : super(const MenuState()) {
    _catSub = _repo.categories().listen((c) {
      _cats = c;
      _publish();
    }, onError: _fail);
    _itemSub = _repo.items().listen((i) {
      _items = i;
      _publish();
    }, onError: _fail);
  }

  final MenuRepository _repo;
  late final StreamSubscription<List<MenuCategory>> _catSub;
  late final StreamSubscription<List<MenuItem>> _itemSub;
  List<MenuCategory>? _cats;
  List<MenuItem>? _items;

  void _publish() {
    if (_cats == null || _items == null) return;
    emit(state.copyWith(loading: false, error: null, categories: _cats, items: _items));
  }

  void _fail(Object _) => emit(state.copyWith(loading: false, error: 'Could not load the menu'));

  void setQuery(String query) => emit(state.copyWith(query: query));
  void selectCategory(String? id) => emit(state.copyWith(categoryId: id));
  void toggleFasting() => emit(state.copyWith(fastingOnly: !state.fastingOnly));

  @override
  Future<void> close() async {
    await _catSub.cancel();
    await _itemSub.cancel();
    return super.close();
  }
}
