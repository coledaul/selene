import 'catalog.dart';

enum AnimeCatalogType { calendar, series, movie }

final class AnimeCatalogFilterDefinition {
  const AnimeCatalogFilterDefinition({
    required this.typeOptions,
    required this.regionOptions,
    required this.yearOptions,
    required this.platformOptions,
    required this.sortOptions,
  });

  final List<CatalogFilterOption> typeOptions;
  final List<CatalogFilterOption> regionOptions;
  final List<CatalogFilterOption> yearOptions;
  final List<CatalogFilterOption> platformOptions;
  final List<CatalogFilterOption> sortOptions;
}

final class AnimeCatalogDefinition {
  const AnimeCatalogDefinition._();

  static final series = AnimeCatalogFilterDefinition(
    typeOptions: _seriesTypes,
    regionOptions: CatalogDefinition.tv.regionOptions,
    yearOptions: CatalogDefinition.tv.yearOptions,
    platformOptions: CatalogDefinition.tv.platformOptions,
    sortOptions: CatalogDefinition.tv.sortOptions,
  );

  static final movie = AnimeCatalogFilterDefinition(
    typeOptions: _movieTypes,
    regionOptions: CatalogDefinition.movie.regionOptions,
    yearOptions: CatalogDefinition.movie.yearOptions,
    platformOptions: const <CatalogFilterOption>[],
    sortOptions: CatalogDefinition.movie.sortOptions,
  );

  static AnimeCatalogFilterDefinition forType(AnimeCatalogType type) =>
      switch (type) {
        AnimeCatalogType.series => series,
        AnimeCatalogType.movie => movie,
        AnimeCatalogType.calendar => throw ArgumentError.value(
          type,
          'type',
          '每日放送不使用目录筛选配置',
        ),
      };
}

final class AnimeCatalogQuery {
  const AnimeCatalogQuery({
    required this.type,
    required this.genre,
    required this.region,
    required this.year,
    required this.platform,
    required this.sort,
    required this.page,
    required this.pageLimit,
  });

  final AnimeCatalogType type;
  final String genre;
  final String region;
  final String year;
  final String platform;
  final String sort;
  final int page;
  final int pageLimit;
}

const _seriesTypes = <CatalogFilterOption>[
  CatalogFilterOption('全部', 'all'),
  CatalogFilterOption('黑色幽默', 'dark_humor'),
  CatalogFilterOption('历史', 'history'),
  CatalogFilterOption('歌舞', 'musical'),
  CatalogFilterOption('励志', 'inspirational'),
  CatalogFilterOption('恶搞', 'parody'),
  CatalogFilterOption('治愈', 'healing'),
  CatalogFilterOption('运动', 'sports'),
  CatalogFilterOption('后宫', 'harem'),
  CatalogFilterOption('情色', 'erotic'),
  CatalogFilterOption('国漫', 'chinese_anime'),
  CatalogFilterOption('人性', 'human_nature'),
  CatalogFilterOption('悬疑', 'suspense'),
  CatalogFilterOption('恋爱', 'love'),
  CatalogFilterOption('魔幻', 'fantasy'),
  CatalogFilterOption('科幻', 'sci_fi'),
];

const _movieTypes = <CatalogFilterOption>[
  CatalogFilterOption('全部', 'all'),
  CatalogFilterOption('定格动画', 'stop_motion'),
  CatalogFilterOption('传记', 'biography'),
  CatalogFilterOption('美国动画', 'us_animation'),
  CatalogFilterOption('爱情', 'romance'),
  CatalogFilterOption('黑色幽默', 'dark_humor'),
  CatalogFilterOption('歌舞', 'musical'),
  CatalogFilterOption('儿童', 'children'),
  CatalogFilterOption('二次元', 'anime'),
  CatalogFilterOption('动物', 'animal'),
  CatalogFilterOption('青春', 'youth'),
  CatalogFilterOption('历史', 'history'),
  CatalogFilterOption('励志', 'inspirational'),
  CatalogFilterOption('恶搞', 'parody'),
  CatalogFilterOption('治愈', 'healing'),
  CatalogFilterOption('运动', 'sports'),
  CatalogFilterOption('后宫', 'harem'),
  CatalogFilterOption('情色', 'erotic'),
  CatalogFilterOption('人性', 'human_nature'),
  CatalogFilterOption('悬疑', 'suspense'),
  CatalogFilterOption('恋爱', 'love'),
  CatalogFilterOption('魔幻', 'fantasy'),
  CatalogFilterOption('科幻', 'sci_fi'),
];
