import 'douban_movie.dart';
import 'play_record.dart';
import 'search_result.dart';

class PlayerRequest {
  const PlayerRequest({
    required this.title,
    this.source,
    this.id,
    this.year,
    this.searchTitle,
    this.type,
    this.prefer = false,
  });

  final String title;
  final String? source;
  final String? id;
  final String? year;
  final String? searchTitle;
  final String? type;
  final bool prefer;
}

class PlayerSourceSpeed {
  const PlayerSourceSpeed({
    required this.quality,
    required this.loadSpeed,
    required this.pingTime,
  });

  final String quality;
  final String loadSpeed;
  final String pingTime;
}

class PreferredPlayerSource {
  const PreferredPlayerSource({required this.source, required this.speeds});

  final SearchResult source;
  final Map<String, PlayerSourceSpeed> speeds;
}

class PlayerResume {
  const PlayerResume({required this.episodeIndex, required this.playTime});

  final int episodeIndex;
  final int playTime;
}

class PlayerMetadata {
  const PlayerMetadata({required this.details});

  final DoubanMovieDetails details;
}

typedef PlayRecordFactory = PlayRecord Function();
