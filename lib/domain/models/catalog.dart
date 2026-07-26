enum CatalogType { movie, tv, show }

final class CatalogFilterOption {
  const CatalogFilterOption(this.label, this.value);

  final String label;
  final String value;
}

final class CatalogDefinition {
  const CatalogDefinition({
    required this.type,
    required this.title,
    required this.countSuffix,
    required this.apiKind,
    required this.advancedFormat,
    required this.initialCategory,
    required this.initialSecondary,
    required this.primaryOptions,
    required this.secondaryOptions,
    required this.typeOptions,
    required this.regionOptions,
    required this.yearOptions,
    required this.platformOptions,
    required this.sortOptions,
  });

  final CatalogType type;
  final String title;
  final String countSuffix;
  final String apiKind;
  final String? advancedFormat;
  final String initialCategory;
  final String initialSecondary;
  final List<CatalogFilterOption> primaryOptions;
  final List<CatalogFilterOption> secondaryOptions;
  final List<CatalogFilterOption> typeOptions;
  final List<CatalogFilterOption> regionOptions;
  final List<CatalogFilterOption> yearOptions;
  final List<CatalogFilterOption> platformOptions;
  final List<CatalogFilterOption> sortOptions;

  bool get supportsPlatform => platformOptions.isNotEmpty;

  String labelFor(List<CatalogFilterOption> options, String value) => options
      .firstWhere(
        (option) => option.value == value,
        orElse: () => options.first,
      )
      .label;

  static const movie = CatalogDefinition(
    type: CatalogType.movie,
    title: '电影',
    countSuffix: '部电影',
    apiKind: 'movie',
    advancedFormat: null,
    initialCategory: '热门',
    initialSecondary: '全部',
    primaryOptions: <CatalogFilterOption>[
      CatalogFilterOption('全部', '全部'),
      CatalogFilterOption('热门电影', '热门'),
      CatalogFilterOption('最新电影', '最新'),
      CatalogFilterOption('豆瓣高分', '豆瓣高分'),
      CatalogFilterOption('冷门佳片', '冷门佳片'),
    ],
    secondaryOptions: <CatalogFilterOption>[
      CatalogFilterOption('全部', '全部'),
      CatalogFilterOption('华语', '华语'),
      CatalogFilterOption('欧美', '欧美'),
      CatalogFilterOption('韩国', '韩国'),
      CatalogFilterOption('日本', '日本'),
    ],
    typeOptions: _movieTypes,
    regionOptions: _movieRegions,
    yearOptions: _years,
    platformOptions: <CatalogFilterOption>[],
    sortOptions: _movieSorts,
  );

  static const tv = CatalogDefinition(
    type: CatalogType.tv,
    title: '电视剧',
    countSuffix: '部电视剧',
    apiKind: 'tv',
    advancedFormat: '电视剧',
    initialCategory: '最近热门',
    initialSecondary: 'tv',
    primaryOptions: <CatalogFilterOption>[
      CatalogFilterOption('全部', '全部'),
      CatalogFilterOption('最近热门', '最近热门'),
    ],
    secondaryOptions: <CatalogFilterOption>[
      CatalogFilterOption('全部', 'tv'),
      CatalogFilterOption('国产', 'tv_domestic'),
      CatalogFilterOption('欧美', 'tv_american'),
      CatalogFilterOption('日本', 'tv_japanese'),
      CatalogFilterOption('韩国', 'tv_korean'),
      CatalogFilterOption('动漫', 'tv_animation'),
      CatalogFilterOption('纪录片', 'tv_documentary'),
    ],
    typeOptions: _tvTypes,
    regionOptions: _seriesRegions,
    yearOptions: _years,
    platformOptions: _platforms,
    sortOptions: _broadcastSorts,
  );

  static const show = CatalogDefinition(
    type: CatalogType.show,
    title: '综艺',
    countSuffix: '档综艺',
    apiKind: 'tv',
    advancedFormat: '综艺',
    initialCategory: '最近热门',
    initialSecondary: 'show',
    primaryOptions: <CatalogFilterOption>[
      CatalogFilterOption('全部', '全部'),
      CatalogFilterOption('最近热门', '最近热门'),
    ],
    secondaryOptions: <CatalogFilterOption>[
      CatalogFilterOption('全部', 'show'),
      CatalogFilterOption('国内', 'show_domestic'),
      CatalogFilterOption('国外', 'show_foreign'),
    ],
    typeOptions: <CatalogFilterOption>[
      CatalogFilterOption('全部', 'all'),
      CatalogFilterOption('真人秀', 'reality'),
      CatalogFilterOption('脱口秀', 'talkshow'),
      CatalogFilterOption('音乐', 'music'),
      CatalogFilterOption('歌舞', 'musical'),
    ],
    regionOptions: _seriesRegions,
    yearOptions: _years,
    platformOptions: _platforms,
    sortOptions: _broadcastSorts,
  );
}

const _movieTypes = <CatalogFilterOption>[
  CatalogFilterOption('全部', 'all'),
  CatalogFilterOption('喜剧', 'comedy'),
  CatalogFilterOption('爱情', 'romance'),
  CatalogFilterOption('动作', 'action'),
  CatalogFilterOption('科幻', 'sci-fi'),
  CatalogFilterOption('悬疑', 'suspense'),
  CatalogFilterOption('犯罪', 'crime'),
  CatalogFilterOption('惊悚', 'thriller'),
  CatalogFilterOption('冒险', 'adventure'),
  CatalogFilterOption('音乐', 'music'),
  CatalogFilterOption('历史', 'history'),
  CatalogFilterOption('奇幻', 'fantasy'),
  CatalogFilterOption('恐怖', 'horror'),
  CatalogFilterOption('战争', 'war'),
  CatalogFilterOption('传记', 'biography'),
  CatalogFilterOption('歌舞', 'musical'),
  CatalogFilterOption('武侠', 'wuxia'),
  CatalogFilterOption('情色', 'erotic'),
  CatalogFilterOption('灾难', 'disaster'),
  CatalogFilterOption('西部', 'western'),
  CatalogFilterOption('纪录片', 'documentary'),
  CatalogFilterOption('短片', 'short'),
];

const _tvTypes = <CatalogFilterOption>[
  CatalogFilterOption('全部', 'all'),
  CatalogFilterOption('喜剧', 'comedy'),
  CatalogFilterOption('爱情', 'romance'),
  CatalogFilterOption('悬疑', 'suspense'),
  CatalogFilterOption('武侠', 'wuxia'),
  CatalogFilterOption('古装', 'costume'),
  CatalogFilterOption('家庭', 'family'),
  CatalogFilterOption('犯罪', 'crime'),
  CatalogFilterOption('科幻', 'sci-fi'),
  CatalogFilterOption('恐怖', 'horror'),
  CatalogFilterOption('历史', 'history'),
  CatalogFilterOption('战争', 'war'),
  CatalogFilterOption('动作', 'action'),
  CatalogFilterOption('冒险', 'adventure'),
  CatalogFilterOption('传记', 'biography'),
  CatalogFilterOption('剧情', 'drama'),
  CatalogFilterOption('奇幻', 'fantasy'),
  CatalogFilterOption('惊悚', 'thriller'),
  CatalogFilterOption('灾难', 'disaster'),
  CatalogFilterOption('歌舞', 'musical'),
  CatalogFilterOption('音乐', 'music'),
];

const _movieRegions = <CatalogFilterOption>[
  CatalogFilterOption('全部', 'all'),
  CatalogFilterOption('华语', 'chinese'),
  CatalogFilterOption('欧美', 'western'),
  CatalogFilterOption('韩国', 'korean'),
  CatalogFilterOption('日本', 'japanese'),
  CatalogFilterOption('中国大陆', 'mainland_china'),
  CatalogFilterOption('美国', 'usa'),
  CatalogFilterOption('中国香港', 'hong_kong'),
  CatalogFilterOption('中国台湾', 'taiwan'),
  CatalogFilterOption('英国', 'uk'),
  CatalogFilterOption('法国', 'france'),
  CatalogFilterOption('德国', 'germany'),
  CatalogFilterOption('意大利', 'italy'),
  CatalogFilterOption('西班牙', 'spain'),
  CatalogFilterOption('印度', 'india'),
  CatalogFilterOption('泰国', 'thailand'),
  CatalogFilterOption('俄罗斯', 'russia'),
  CatalogFilterOption('加拿大', 'canada'),
  CatalogFilterOption('澳大利亚', 'australia'),
  CatalogFilterOption('爱尔兰', 'ireland'),
  CatalogFilterOption('瑞典', 'sweden'),
  CatalogFilterOption('巴西', 'brazil'),
  CatalogFilterOption('丹麦', 'denmark'),
];

const _seriesRegions = <CatalogFilterOption>[
  CatalogFilterOption('全部', 'all'),
  CatalogFilterOption('华语', 'chinese'),
  CatalogFilterOption('欧美', 'western'),
  CatalogFilterOption('国外', 'foreign'),
  CatalogFilterOption('韩国', 'korean'),
  CatalogFilterOption('日本', 'japanese'),
  CatalogFilterOption('中国大陆', 'mainland_china'),
  CatalogFilterOption('中国香港', 'hong_kong'),
  CatalogFilterOption('美国', 'usa'),
  CatalogFilterOption('英国', 'uk'),
  CatalogFilterOption('泰国', 'thailand'),
  CatalogFilterOption('中国台湾', 'taiwan'),
  CatalogFilterOption('意大利', 'italy'),
  CatalogFilterOption('法国', 'france'),
  CatalogFilterOption('德国', 'germany'),
  CatalogFilterOption('西班牙', 'spain'),
  CatalogFilterOption('俄罗斯', 'russia'),
  CatalogFilterOption('瑞典', 'sweden'),
  CatalogFilterOption('巴西', 'brazil'),
  CatalogFilterOption('丹麦', 'denmark'),
  CatalogFilterOption('印度', 'india'),
  CatalogFilterOption('加拿大', 'canada'),
  CatalogFilterOption('爱尔兰', 'ireland'),
  CatalogFilterOption('澳大利亚', 'australia'),
];

const _years = <CatalogFilterOption>[
  CatalogFilterOption('全部', 'all'),
  CatalogFilterOption('2020年代', '2020s'),
  CatalogFilterOption('2025', '2025'),
  CatalogFilterOption('2024', '2024'),
  CatalogFilterOption('2023', '2023'),
  CatalogFilterOption('2022', '2022'),
  CatalogFilterOption('2021', '2021'),
  CatalogFilterOption('2020', '2020'),
  CatalogFilterOption('2019', '2019'),
  CatalogFilterOption('2010年代', '2010s'),
  CatalogFilterOption('2000年代', '2000s'),
  CatalogFilterOption('90年代', '1990s'),
  CatalogFilterOption('80年代', '1980s'),
  CatalogFilterOption('70年代', '1970s'),
  CatalogFilterOption('60年代', '1960s'),
  CatalogFilterOption('更早', 'earlier'),
];

const _platforms = <CatalogFilterOption>[
  CatalogFilterOption('全部', 'all'),
  CatalogFilterOption('腾讯视频', 'tencent'),
  CatalogFilterOption('爱奇艺', 'iqiyi'),
  CatalogFilterOption('优酷', 'youku'),
  CatalogFilterOption('湖南卫视', 'hunan_tv'),
  CatalogFilterOption('Netflix', 'netflix'),
  CatalogFilterOption('HBO', 'hbo'),
  CatalogFilterOption('BBC', 'bbc'),
  CatalogFilterOption('NHK', 'nhk'),
  CatalogFilterOption('CBS', 'cbs'),
  CatalogFilterOption('NBC', 'nbc'),
  CatalogFilterOption('tvN', 'tvn'),
];

const _movieSorts = <CatalogFilterOption>[
  CatalogFilterOption('综合排序', 'T'),
  CatalogFilterOption('近期热度', 'U'),
  CatalogFilterOption('上映时间', 'R'),
  CatalogFilterOption('高分优先', 'S'),
];

const _broadcastSorts = <CatalogFilterOption>[
  CatalogFilterOption('综合排序', 'T'),
  CatalogFilterOption('近期热度', 'U'),
  CatalogFilterOption('首播时间', 'R'),
  CatalogFilterOption('高分优先', 'S'),
];

final class CatalogQuery {
  const CatalogQuery({
    required this.definition,
    required this.category,
    required this.secondary,
    required this.type,
    required this.region,
    required this.year,
    required this.platform,
    required this.sort,
    required this.page,
    required this.pageLimit,
  });

  final CatalogDefinition definition;
  final String category;
  final String secondary;
  final String type;
  final String region;
  final String year;
  final String platform;
  final String sort;
  final int page;
  final int pageLimit;

  bool get advanced => category == '全部';
}
