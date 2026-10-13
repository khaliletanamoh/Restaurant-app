import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'user_repository.dart';

/// Holds the set of favorite menu item ids for the signed-in user.
class FavoritesCubit extends Cubit<Set<String>> {
  FavoritesCubit(this._repo, this._uid) : super(const {}) {
    _sub = _repo.watchProfile(_uid).listen((p) => emit(p.favoriteItemIds));
  }

  final UserRepository _repo;
  final String _uid;
  late final StreamSubscription<UserProfile> _sub;

  Future<void> toggle(String itemId) {
    final isFavorite = state.contains(itemId);
    // Optimistic update; the Firestore stream confirms it.
    emit(isFavorite ? ({...state}..remove(itemId)) : {...state, itemId});
    return _repo.setFavorite(_uid, itemId, value: !isFavorite);
  }

  @override
  Future<void> close() async {
    await _sub.cancel();
    return super.close();
  }
}
