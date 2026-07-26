import 'dart:async';

import '../../../data/repositories/search_repository.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../core/view_models/view_model.dart';
import 'shell_ui_state.dart';

final class ShellViewModel extends ViewModel {
  ShellViewModel({
    required SearchRepository searchRepository,
    required SettingsRepository settingsRepository,
    this.debounceDuration = const Duration(milliseconds: 500),
  }) : _searchRepository = searchRepository,
       _settingsRepository = settingsRepository;

  final SearchRepository _searchRepository;
  final SettingsRepository _settingsRepository;
  final Duration debounceDuration;
  ShellUiState _state = const ShellUiState();
  Timer? _debounce;
  int _generation = 0;

  ShellUiState get state => _state;

  void updateQuery(String value) {
    _debounce?.cancel();
    final query = value.trim();
    final generation = ++_generation;
    if (query.isEmpty) {
      _setState(const ShellUiState());
      return;
    }
    _setState(
      _state.copyWith(
        query: value,
        suggestions: const <String>[],
        loadingSuggestions: true,
      ),
    );
    _debounce = Timer(debounceDuration, () => _load(query, generation));
  }

  void clearSuggestions() {
    _debounce?.cancel();
    _generation++;
    _setState(_state.copyWith(suggestions: const <String>[]));
  }

  Future<void> _load(String query, int generation) async {
    final settings = await _settingsRepository.load();
    if (generation != _generation) return;
    if (settings.isFailure) {
      _setState(_state.copyWith(loadingSuggestions: false));
      return;
    }
    final result = await _searchRepository.getSuggestions(
      query,
      localSearchEnabled: settings.valueOrNull!.localSearch,
    );
    if (generation != _generation) return;
    _setState(
      _state.copyWith(
        suggestions:
            result.valueOrNull?.take(8).toList(growable: false) ??
            const <String>[],
        loadingSuggestions: false,
      ),
    );
  }

  void _setState(ShellUiState value) =>
      updateState(_state, value, (next) => _state = next);

  @override
  void dispose() {
    _debounce?.cancel();
    _generation++;
    super.dispose();
  }
}
