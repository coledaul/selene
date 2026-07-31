abstract final class AppLinks {
  static const releaseAssetProxyOrigin = 'https://gh-proxy.com';
  static const repositorySlug = 'coledaul/selene';
  static const repositoryUrl = 'https://github.com/$repositorySlug';

  static final repositoryUri = Uri.parse(repositoryUrl);

  static final latestReleaseApiUri = Uri.https(
    'api.github.com',
    '/repos/$repositorySlug/releases/latest',
  );

  static bool isReleaseUri(Uri uri, {required String tag}) {
    final segments = uri.pathSegments;
    return uri.scheme == 'https' &&
        uri.host == 'github.com' &&
        uri.userInfo.isEmpty &&
        !uri.hasPort &&
        uri.query.isEmpty &&
        uri.fragment.isEmpty &&
        segments.length == 5 &&
        segments[0].toLowerCase() == 'coledaul' &&
        segments[1].toLowerCase() == 'selene' &&
        segments[2] == 'releases' &&
        segments[3] == 'tag' &&
        segments[4] == tag;
  }

  static bool isReleaseAssetUri(Uri uri, {required String tag}) {
    final segments = uri.pathSegments;
    return uri.scheme == 'https' &&
        uri.host == 'github.com' &&
        uri.userInfo.isEmpty &&
        !uri.hasPort &&
        uri.query.isEmpty &&
        uri.fragment.isEmpty &&
        segments.length == 6 &&
        segments[0].toLowerCase() == 'coledaul' &&
        segments[1].toLowerCase() == 'selene' &&
        segments[2] == 'releases' &&
        segments[3] == 'download' &&
        segments[4] == tag &&
        segments[5].isNotEmpty;
  }

  static Uri releaseAssetProxyUri(Uri original) =>
      Uri.parse('$releaseAssetProxyOrigin/$original');
}
