import 'package:flutter/material.dart';
import 'package:stretchnow/core/constants/app_constants.dart';
import 'package:stretchnow/core/models/stretch_model.dart';
import 'package:stretchnow/core/services/storage_service.dart';

class StretchesViewModel extends ChangeNotifier {
  final StorageService _storageService;

  StretchesViewModel(this._storageService) {
    _storageService.addListener(_onStorageChanged);
    _loadState();
  }

  RoutineBlock? _selectedBlock;
  RoutineBlock? get selectedBlock => _selectedBlock;

  bool _favoritesOnly = false;
  bool get favoritesOnly => _favoritesOnly;

  RoutineTier _selectedTier = RoutineTier.sweatless;
  RoutineTier get selectedTier => _selectedTier;

  final Set<String> _favoriteIds = {};
  Set<String> get favoriteIds => Set.unmodifiable(_favoriteIds);

  List<StretchExercise> get filteredExercises {
    Iterable<StretchExercise> list = StretchExercise.routine;
    if (_favoritesOnly) {
      list = list.where((e) => _favoriteIds.contains(e.id));
    } else if (_selectedBlock != null) {
      list = list.where((e) => e.block == _selectedBlock);
    }
    return list.toList();
  }

  bool isFavorite(String id) => _favoriteIds.contains(id);

  void selectAll() {
    _selectedBlock = null;
    _favoritesOnly = false;
    notifyListeners();
  }

  void selectBlock(RoutineBlock block) {
    _selectedBlock = block;
    _favoritesOnly = false;
    notifyListeners();
  }

  void selectFavoritesOnly() {
    _favoritesOnly = true;
    _selectedBlock = null;
    notifyListeners();
  }

  Future<void> selectTier(RoutineTier tier) async {
    _selectedTier = tier;
    await _storageService.saveSettingString(
      AppConstants.keySelectedTier,
      tier.id,
    );
  }

  Future<void> toggleFavorite(String id) async {
    if (_favoriteIds.contains(id)) {
      _favoriteIds.remove(id);
    } else {
      _favoriteIds.add(id);
    }
    await _storageService.saveString(
      AppConstants.keyFavoriteStretches,
      _favoriteIds.join(','),
    );
  }

  void _onStorageChanged() => _loadState();

  void _loadState() {
    _selectedTier = RoutineTier.fromId(
      _storageService.getSettingString(AppConstants.keySelectedTier),
    );
    final stored =
        _storageService.getString(AppConstants.keyFavoriteStretches) ?? '';
    _favoriteIds
      ..clear()
      ..addAll(stored.split(',').where((e) => e.trim().isNotEmpty));
    notifyListeners();
  }

  @override
  void dispose() {
    _storageService.removeListener(_onStorageChanged);
    super.dispose();
  }
}
