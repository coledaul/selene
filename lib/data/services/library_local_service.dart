import '../../domain/models/favorite_item.dart';
import '../../domain/models/play_record.dart';
import 'local_mode_storage_service.dart';

/// 本地模式下播放记录、收藏和搜索历史的持久化端口。
abstract interface class LibraryLocalService {
  Future<List<PlayRecord>> getPlayRecords();
  Future<void> savePlayRecord(PlayRecord record);
  Future<void> deletePlayRecord(String source, String id);
  Future<void> clearPlayRecords();
  Future<List<FavoriteItem>> getFavorites();
  Future<void> saveFavorite(FavoriteItem favorite);
  Future<void> deleteFavorite(String source, String id);
  bool isFavorite(String source, String id);
  Future<List<String>> getSearchHistory();
  Future<void> addSearchHistory(String query);
  Future<void> deleteSearchHistory(String query);
  Future<void> clearSearchHistory();
}

final class DefaultLibraryLocalService implements LibraryLocalService {
  const DefaultLibraryLocalService();

  @override
  Future<List<PlayRecord>> getPlayRecords() =>
      LocalModeStorageService.getPlayRecords();
  @override
  Future<void> savePlayRecord(PlayRecord record) =>
      LocalModeStorageService.savePlayRecord(record);
  @override
  Future<void> deletePlayRecord(String source, String id) =>
      LocalModeStorageService.deletePlayRecord(source, id);
  @override
  Future<void> clearPlayRecords() => LocalModeStorageService.clearPlayRecords();
  @override
  Future<List<FavoriteItem>> getFavorites() =>
      LocalModeStorageService.getFavorites();
  @override
  Future<void> saveFavorite(FavoriteItem favorite) =>
      LocalModeStorageService.saveFavorite(favorite);
  @override
  Future<void> deleteFavorite(String source, String id) =>
      LocalModeStorageService.deleteFavorite(source, id);
  @override
  bool isFavorite(String source, String id) =>
      LocalModeStorageService.isFavoriteSync(source, id);
  @override
  Future<List<String>> getSearchHistory() =>
      LocalModeStorageService.getSearchHistory();
  @override
  Future<void> addSearchHistory(String query) =>
      LocalModeStorageService.addSearchHistory(query);
  @override
  Future<void> deleteSearchHistory(String query) =>
      LocalModeStorageService.deleteSearchHistory(query);
  @override
  Future<void> clearSearchHistory() =>
      LocalModeStorageService.clearSearchHistory();
}
