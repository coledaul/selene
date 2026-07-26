import 'package:freezed_annotation/freezed_annotation.dart';

part 'search_progress.freezed.dart';

@freezed
abstract class SearchProgress with _$SearchProgress {
  const SearchProgress._();

  const factory SearchProgress({
    required int totalSources,
    required int completedSources,
    String? currentSource,
    required bool isComplete,
    @Default(false) bool isFailure,
    String? error,
  }) = _SearchProgress;

  double get progressPercentage => totalSources <= 0
      ? 0
      : (completedSources / totalSources).clamp(0, 1).toDouble();

  bool get hasError => error != null;

  String get progressDescription {
    if (isFailure) {
      return error ?? '搜索失败';
    }
    if (isComplete) {
      return '搜索完成';
    }
    if (currentSource != null) {
      return '正在搜索: $currentSource';
    }
    return '准备搜索...';
  }
}
