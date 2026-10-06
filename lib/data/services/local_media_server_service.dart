import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../../domain/models/local_media_lease.dart';
import '../../utils/result.dart';

abstract interface class LocalMediaServerService {
  Future<Result<LocalMediaLease>> publishFile({
    required String filePath,
    required String targetHost,
  });

  Future<Result<void>> release(LocalMediaLease lease);

  Future<void> dispose();
}

final class DefaultLocalMediaServerService implements LocalMediaServerService {
  DefaultLocalMediaServerService({
    Future<InternetAddress?> Function(String targetHost)? addressResolver,
  }) : _addressResolver = addressResolver;

  final Future<InternetAddress?> Function(String targetHost)? _addressResolver;
  HttpServer? _server;
  LocalMediaLease? _lease;
  String? _token;
  bool _disposed = false;
  Future<void> _operationTail = Future<void>.value();

  @override
  Future<Result<LocalMediaLease>> publishFile({
    required String filePath,
    required String targetHost,
  }) =>
      _enqueue(() => _publishFile(filePath: filePath, targetHost: targetHost));

  Future<Result<LocalMediaLease>> _publishFile({
    required String filePath,
    required String targetHost,
  }) async {
    if (_disposed) {
      return const FailureResult<LocalMediaLease>(
        AppFailure(kind: FailureKind.cancellation, message: '本地媒体服务已关闭'),
      );
    }

    final file = File(filePath);
    try {
      final stat = await file.stat();
      if (stat.type != FileSystemEntityType.file || stat.size <= 0) {
        return const FailureResult<LocalMediaLease>(
          AppFailure(kind: FailureKind.storage, message: '本地视频文件不可用'),
        );
      }

      await _closeServer();
      final address =
          await (_addressResolver?.call(targetHost) ??
              _findLocalAddress(targetHost));
      if (address == null) {
        return const FailureResult<LocalMediaLease>(
          AppFailure(kind: FailureKind.network, message: '手机与电视不在可互通的局域网中'),
        );
      }

      final server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
      final token = _randomToken();
      final fileName = _safeFileName(file.uri.pathSegments.last);
      final lease = LocalMediaLease(
        url: Uri(
          scheme: 'http',
          host: address.address,
          port: server.port,
          path: '/selene-media/$token/$fileName',
        ),
        filePath: filePath,
      );
      _server = server;
      _lease = lease;
      _token = token;
      unawaited(server.forEach(_handleRequest));
      return Success<LocalMediaLease>(lease);
    } on SocketException catch (error, stackTrace) {
      return FailureResult<LocalMediaLease>(
        AppFailure(
          kind: FailureKind.network,
          message: '无法启动本地投屏服务',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    } on FileSystemException catch (error, stackTrace) {
      return FailureResult<LocalMediaLease>(
        AppFailure(
          kind: FailureKind.storage,
          message: '读取本地视频失败',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    } catch (error, stackTrace) {
      return FailureResult<LocalMediaLease>(
        AppFailure(
          kind: FailureKind.network,
          message: '准备本地投屏服务失败',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Result<void>> release(LocalMediaLease lease) =>
      _enqueue(() => _release(lease));

  Future<Result<void>> _release(LocalMediaLease lease) async {
    if (!identical(_lease, lease) && _lease?.url != lease.url) {
      return const Success<void>(null);
    }
    try {
      await _closeServer();
      return const Success<void>(null);
    } on SocketException catch (error, stackTrace) {
      return FailureResult<void>(
        AppFailure(
          kind: FailureKind.network,
          message: '关闭本地投屏服务失败',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  Future<void> _handleRequest(HttpRequest request) async {
    final lease = _lease;
    final token = _token;
    if (lease == null ||
        token == null ||
        request.uri.pathSegments.length != 3) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }

    final segments = request.uri.pathSegments;
    if (segments[0] != 'selene-media' ||
        segments[1] != token ||
        segments[2] != lease.url.pathSegments[2]) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }

    if (request.method != 'GET' && request.method != 'HEAD') {
      request.response
        ..statusCode = HttpStatus.methodNotAllowed
        ..headers.set(HttpHeaders.allowHeader, 'GET, HEAD');
      await request.response.close();
      return;
    }

    final file = File(lease.filePath);
    try {
      final length = (await file.stat()).size;
      final range = _parseRange(
        request.headers.value(HttpHeaders.rangeHeader),
        length,
      );
      if (range == null &&
          request.headers.value(HttpHeaders.rangeHeader) != null) {
        request.response
          ..statusCode = HttpStatus.requestedRangeNotSatisfiable
          ..headers.set(HttpHeaders.contentRangeHeader, 'bytes */$length');
        await request.response.close();
        return;
      }

      final start = range?.$1 ?? 0;
      final end = range?.$2 ?? length - 1;
      request.response
        ..statusCode = range == null ? HttpStatus.ok : HttpStatus.partialContent
        ..headers.contentType = ContentType('video', 'x-matroska')
        ..headers.contentLength = end - start + 1
        ..headers.set(HttpHeaders.acceptRangesHeader, 'bytes')
        ..headers.set(HttpHeaders.cacheControlHeader, 'no-store');
      if (range != null) {
        request.response.headers.set(
          HttpHeaders.contentRangeHeader,
          'bytes $start-$end/$length',
        );
      }
      if (request.method == 'GET') {
        await request.response.addStream(file.openRead(start, end + 1));
      }
      await request.response.close();
    } on FileSystemException {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
    } catch (_) {
      await request.response.close();
    }
  }

  Future<InternetAddress?> _findLocalAddress(String targetHost) async {
    final target = InternetAddress.tryParse(targetHost);
    final interfaces = await NetworkInterface.list(
      includeLoopback: false,
      includeLinkLocal: false,
      type: InternetAddressType.IPv4,
    );
    final addresses = interfaces
        .expand((network) => network.addresses)
        .where(_isPrivateIpv4)
        .toList(growable: false);
    if (addresses.isEmpty) return null;
    if (target == null) return addresses.length == 1 ? addresses.first : null;
    if (addresses.length == 1) return addresses.first;
    final matching = addresses
        .where((address) => _sameSubnet(address, target))
        .toList(growable: false);
    return matching.isEmpty ? null : matching.first;
  }

  bool _sameSubnet(InternetAddress left, InternetAddress right) {
    final a = left.rawAddress;
    final b = right.rawAddress;
    return a.length == 4 &&
        b.length == 4 &&
        a[0] == b[0] &&
        a[1] == b[1] &&
        a[2] == b[2];
  }

  bool _isPrivateIpv4(InternetAddress address) {
    final bytes = address.rawAddress;
    if (bytes.length != 4) return false;
    return bytes[0] == 10 ||
        (bytes[0] == 172 && bytes[1] >= 16 && bytes[1] <= 31) ||
        (bytes[0] == 192 && bytes[1] == 168);
  }

  String _randomToken() {
    final bytes = List<int>.generate(18, (_) => Random.secure().nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  String _safeFileName(String value) =>
      value.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');

  (int, int)? _parseRange(String? value, int length) {
    if (value == null || !value.startsWith('bytes=') || length <= 0) {
      return null;
    }
    final parts = value.substring(6).split(',');
    if (parts.length != 1) return null;
    final bounds = parts.single.trim().split('-');
    if (bounds.length != 2) return null;
    final startText = bounds[0].trim();
    final endText = bounds[1].trim();
    int start;
    int end;
    if (startText.isEmpty) {
      final suffix = int.tryParse(endText);
      if (suffix == null || suffix <= 0) return null;
      start = suffix >= length ? 0 : length - suffix;
      end = length - 1;
    } else {
      start = int.tryParse(startText) ?? -1;
      end = endText.isEmpty ? length - 1 : int.tryParse(endText) ?? -1;
      if (start < 0 || start >= length || end < start) return null;
      if (end >= length) end = length - 1;
    }
    return (start, end);
  }

  Future<void> _closeServer() async {
    final server = _server;
    _server = null;
    _lease = null;
    _token = null;
    await server?.close(force: true);
  }

  @override
  Future<void> dispose() {
    if (_disposed) return _operationTail;
    _disposed = true;
    return _enqueue(_closeServer);
  }

  Future<T> _enqueue<T>(Future<T> Function() action) {
    final operation = _operationTail.then<T>(
      (_) => action(),
      onError: (_, _) => action(),
    );
    _operationTail = operation.then<void>((_) {}, onError: (_, _) {});
    return operation;
  }
}
