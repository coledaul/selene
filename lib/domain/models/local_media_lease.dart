import 'package:flutter/foundation.dart';

/// A temporary URL that exposes one local media file to a LAN player.
@immutable
final class LocalMediaLease {
  const LocalMediaLease({required this.url, required this.filePath});

  final Uri url;
  final String filePath;
}
