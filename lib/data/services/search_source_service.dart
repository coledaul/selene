import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/models/search_resource.dart';
import '../../domain/models/search_result.dart';
import 'downstream_service.dart';
import 'local_mode_storage_service.dart';

/// 本地搜索源与下游站点访问端口。
abstract interface class SearchSourceService {
  Future<List<SearchResource>> getLocalSources();
  Future<List<SearchResult>> search(SearchResource resource, String query);
  Future<SearchResult> fetchDetail(SearchResource resource, String id);
}

final class DefaultSearchSourceService implements SearchSourceService {
  const DefaultSearchSourceService();

  @override
  Future<List<SearchResource>> getLocalSources() =>
      LocalModeStorageService.getSearchSources();

  @override
  Future<List<SearchResult>> search(SearchResource resource, String query) =>
      DownstreamService.searchFromApi(resource, query);

  @override
  Future<SearchResult> fetchDetail(SearchResource resource, String id) async {
    if (resource.detail.isNotEmpty) {
      return _fetchHtmlDetail(resource, id);
    }
    final response = await http
        .get(
          Uri.parse('${resource.api}?ac=videolist&ids=$id'),
          headers: const <String, String>{
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/122.0.0.0 Safari/537.36',
            'Accept': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('详情请求失败: ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> ||
        decoded['list'] is! List ||
        (decoded['list'] as List).isEmpty) {
      throw const FormatException('获取到的详情内容无效');
    }
    final raw = (decoded['list'] as List).first;
    if (raw is! Map<String, dynamic>) {
      throw const FormatException('详情数据格式无效');
    }
    return _parseApiDetail(resource, id, raw);
  }

  SearchResult _parseApiDetail(
    SearchResource resource,
    String id,
    Map<String, dynamic> raw,
  ) {
    var episodes = <String>[];
    var titles = <String>[];
    final playUrl = raw['vod_play_url'];
    if (playUrl is String) {
      for (final group in playUrl.split('\$\$\$')) {
        final groupEpisodes = <String>[];
        final groupTitles = <String>[];
        for (final entry in group.split('#')) {
          final separator = entry.indexOf('\$');
          if (separator <= 0 || separator == entry.length - 1) continue;
          final url = entry.substring(separator + 1);
          if (!url.toLowerCase().contains('.m3u8')) continue;
          groupTitles.add(entry.substring(0, separator));
          groupEpisodes.add(url);
        }
        if (groupEpisodes.length > episodes.length) {
          episodes = groupEpisodes;
          titles = groupTitles;
        }
      }
    }
    final content = raw['vod_content']?.toString() ?? '';
    if (episodes.isEmpty) {
      episodes = RegExp(r'https?://[^\s<>"]+\.m3u8')
          .allMatches(content)
          .map((match) => match.group(0)!)
          .toList(growable: false);
    }
    final rawYear = raw['vod_year']?.toString() ?? '';
    final year = RegExp(r'\d{4}').firstMatch(rawYear)?.group(0) ?? 'unknown';
    return SearchResult(
      id: id,
      title: raw['vod_name']?.toString() ?? '',
      poster: raw['vod_pic']?.toString() ?? '',
      episodes: episodes,
      episodesTitles: titles,
      source: resource.key,
      sourceName: resource.name,
      class_: raw['vod_class']?.toString(),
      year: year,
      desc: _cleanHtml(raw['vod_content']?.toString() ?? ''),
      typeName: raw['type_name']?.toString(),
      doubanId: int.tryParse(raw['vod_douban_id']?.toString() ?? ''),
    );
  }

  Future<SearchResult> _fetchHtmlDetail(
    SearchResource resource,
    String id,
  ) async {
    final response = await http
        .get(
          Uri.parse('${resource.detail}/index.php/vod/detail/id/$id.html'),
          headers: const <String, String>{
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/122.0.0.0 Safari/537.36',
            'Accept': 'text/html',
          },
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('详情页请求失败: ${response.statusCode}');
    }
    final html = response.body;
    var matches = resource.key == 'ffzy'
        ? RegExp(
            r'\$(https?://[^"\x27\s]+?/\d{8}/\d+_[a-f0-9]+/index\.m3u8)',
          ).allMatches(html).map((match) => match.group(1)!).toList()
        : <String>[];
    if (matches.isEmpty) {
      matches = RegExp(
        r'\$(https?://[^"\x27\s]+?\.m3u8)',
      ).allMatches(html).map((match) => match.group(1)!).toList();
    }
    final episodes = matches
        .map((url) => url.split('(').first)
        .toSet()
        .toList(growable: false);
    return SearchResult(
      id: id,
      title:
          RegExp(r'<h1[^>]*>([^<]+)</h1>').firstMatch(html)?.group(1)?.trim() ??
          '',
      poster:
          RegExp(r'(https?://[^"\x27\s]+?\.jpg)').firstMatch(html)?.group(1) ??
          '',
      episodes: episodes,
      episodesTitles: List<String>.generate(
        episodes.length,
        (index) => '${index + 1}',
        growable: false,
      ),
      source: resource.key,
      sourceName: resource.name,
      year: RegExp(r'>(\d{4})<').firstMatch(html)?.group(1) ?? 'unknown',
      desc: _cleanHtml(
        RegExp(
              r'<div[^>]*class=["\x27]sketch["\x27][^>]*>([\s\S]*?)</div>',
            ).firstMatch(html)?.group(1) ??
            '',
      ),
    );
  }

  String _cleanHtml(String value) => value
      .replaceAll(RegExp(r'<[^>]+>'), '\n')
      .replaceAll(RegExp(r'\n+'), '\n')
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .trim()
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&nbsp;', ' ');
}
