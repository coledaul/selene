import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:selene/data/services/local_media_server_service.dart';
import 'package:selene/utils/result.dart';

void main() {
  late Directory directory;
  late File file;
  late DefaultLocalMediaServerService service;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('selene-local-media-');
    file = File('${directory.path}/episode.mkv');
    await file.writeAsBytes(utf8.encode('0123456789'), flush: true);
    service = DefaultLocalMediaServerService(
      addressResolver: (_) async => InternetAddress.loopbackIPv4,
    );
  });

  tearDown(() async {
    await service.dispose();
    await directory.delete(recursive: true);
  });

  test('发布本地文件并支持 HEAD、全量 GET 和 Range GET', () async {
    final published = await service.publishFile(
      filePath: file.path,
      targetHost: '127.0.0.1',
    );
    expect(published, isA<Success>());
    final url = published.valueOrNull!.url;
    final client = HttpClient();
    addTearDown(client.close);

    final headRequest = await client.openUrl('HEAD', url);
    final head = await headRequest.close();
    expect(head.statusCode, HttpStatus.ok);
    expect(head.contentLength, 10);
    expect(head.headers.value(HttpHeaders.acceptRangesHeader), 'bytes');

    final getRequest = await client.getUrl(url);
    final get = await getRequest.close();
    expect(await utf8.decoder.bind(get).join(), '0123456789');

    final rangeRequest = await client.getUrl(url);
    rangeRequest.headers.set(HttpHeaders.rangeHeader, 'bytes=2-5');
    final range = await rangeRequest.close();
    expect(range.statusCode, HttpStatus.partialContent);
    expect(await utf8.decoder.bind(range).join(), '2345');
    expect(range.headers.value(HttpHeaders.contentRangeHeader), 'bytes 2-5/10');
  });

  test('拒绝非法 token 和非法范围', () async {
    final published = await service.publishFile(
      filePath: file.path,
      targetHost: '127.0.0.1',
    );
    final url = published.valueOrNull!.url;
    final client = HttpClient();
    addTearDown(client.close);

    final invalidRequest = await client.getUrl(
      url.replace(path: '${url.path}-invalid'),
    );
    expect((await invalidRequest.close()).statusCode, HttpStatus.notFound);

    final rangeRequest = await client.getUrl(url);
    rangeRequest.headers.set(HttpHeaders.rangeHeader, 'bytes=99-100');
    final range = await rangeRequest.close();
    expect(range.statusCode, HttpStatus.requestedRangeNotSatisfiable);
  });

  test('释放租约后 URL 不再可访问', () async {
    final published = await service.publishFile(
      filePath: file.path,
      targetHost: '127.0.0.1',
    );
    final lease = published.valueOrNull!;
    expect((await service.release(lease)).isSuccess, isTrue);

    final client = HttpClient();
    addTearDown(client.close);
    expect(client.getUrl(lease.url), throwsA(isA<SocketException>()));
  });
}
