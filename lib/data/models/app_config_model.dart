// ignore_for_file: sort_constructors_first

class AppConfigModel {
  AppConfigModel({
    required this.categories,
    required this.tones,
    required this.templateCategories,
    required this.templates,
    required this.homeFeatures,
    required this.visualAssets,
  });

  final List<CategoryConfig> categories;
  final List<ToneConfig> tones;
  final List<TemplateCategoryConfig> templateCategories;
  final List<TemplateConfig> templates;
  final List<HomeFeatureConfig> homeFeatures;
  final List<VisualAssetConfig> visualAssets;

  factory AppConfigModel.fromJson(Map<String, dynamic> json) {
    return AppConfigModel(
      categories:
          (json['categories'] as List<dynamic>? ?? [])
              .map(
                (item) => CategoryConfig.fromJson(item as Map<String, dynamic>),
              )
              .toList()
            ..sort((a, b) => a.order.compareTo(b.order)),
      tones:
          (json['tones'] as List<dynamic>? ?? [])
              .map((item) => ToneConfig.fromJson(item as Map<String, dynamic>))
              .toList()
            ..sort((a, b) => a.order.compareTo(b.order)),
      templateCategories:
          (json['templateCategories'] as List<dynamic>? ?? [])
              .map(
                (item) => TemplateCategoryConfig.fromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList()
            ..sort((a, b) => a.order.compareTo(b.order)),
      templates: (json['templates'] as List<dynamic>? ?? [])
          .map((item) => TemplateConfig.fromJson(item as Map<String, dynamic>))
          .toList(),
      homeFeatures: (json['homeFeatures'] as List<dynamic>? ?? [])
          .map(
            (item) => HomeFeatureConfig.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      visualAssets: (json['visualAssets'] as List<dynamic>? ?? [])
          .map(
            (item) => VisualAssetConfig.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  factory AppConfigModel.bootstrap() {
    return AppConfigModel.fromJson({
      'categories': [
        {
          'id': 'coding',
          'label': 'Coding',
          'iconKey': 'code',
          'visualStyle': 'mint',
          'order': 0,
          'enabled': true,
        },
        {
          'id': 'general',
          'label': 'General',
          'iconKey': 'sparkles',
          'visualStyle': 'lavender',
          'order': 1,
          'enabled': true,
        },
        {
          'id': 'writing',
          'label': 'Writing',
          'iconKey': 'edit',
          'visualStyle': 'blush',
          'order': 2,
          'enabled': true,
        },
        {
          'id': 'image-generation',
          'label': 'Image',
          'iconKey': 'image',
          'visualStyle': 'lime',
          'order': 3,
          'enabled': true,
        },
        {
          'id': 'business',
          'label': 'Business',
          'iconKey': 'briefcase',
          'visualStyle': 'sky',
          'order': 4,
          'enabled': true,
        },
      ],
      'tones': [
        {
          'id': 'auto',
          'label': 'Auto',
          'iconKey': 'sparkles',
          'premiumOnly': false,
          'order': 0,
          'promptPolicyKey': 'auto',
        },
        {
          'id': 'professional',
          'label': 'Professional',
          'iconKey': 'briefcase',
          'premiumOnly': true,
          'order': 1,
          'promptPolicyKey': 'professional',
        },
        {
          'id': 'creative',
          'label': 'Creative',
          'iconKey': 'palette',
          'premiumOnly': true,
          'order': 2,
          'promptPolicyKey': 'creative',
        },
        {
          'id': 'casual',
          'label': 'Casual',
          'iconKey': 'chat',
          'premiumOnly': true,
          'order': 3,
          'promptPolicyKey': 'casual',
        },
        {
          'id': 'persuasive',
          'label': 'Persuasive',
          'iconKey': 'megaphone',
          'premiumOnly': true,
          'order': 4,
          'promptPolicyKey': 'persuasive',
        },
        {
          'id': 'technical',
          'label': 'Technical',
          'iconKey': 'settings',
          'premiumOnly': true,
          'order': 5,
          'promptPolicyKey': 'technical',
        },
      ],
      'templateCategories': [
        {'id': 'coding', 'label': 'Coding', 'iconKey': 'code', 'order': 0},
        {
          'id': 'general',
          'label': 'General',
          'iconKey': 'sparkles',
          'order': 1,
        },
        {'id': 'writing', 'label': 'Writing', 'iconKey': 'edit', 'order': 2},
        {
          'id': 'image-generation',
          'label': 'Image',
          'iconKey': 'image',
          'order': 3,
        },
        {
          'id': 'business',
          'label': 'Business',
          'iconKey': 'briefcase',
          'order': 4,
        },
      ],
      'templates': [
        {
          'id': 'coding-add-feature',
          'categoryId': 'coding',
          'title': 'Add a Feature',
          'summary': 'Describe a new feature for an existing app or project.',
          'promptBody': 'I want to add [feature] to my [framework] app',
          'isQuick': true,
          'enabled': true,
        },
        {
          'id': 'coding-fix-bug',
          'categoryId': 'coding',
          'title': 'Fix a Bug',
          'summary': 'Explain the bug, trigger, and current behavior.',
          'promptBody': 'I have a bug where [problem] happens when [trigger]',
          'isQuick': true,
          'enabled': true,
        },
        {
          'id': 'coding-build-screen',
          'categoryId': 'coding',
          'title': 'Build a Screen',
          'summary': 'Outline a full screen with UI and behavior requirements.',
          'promptBody': 'Build a [screen name] screen with [requirements]',
          'isQuick': true,
          'enabled': true,
        },
        {
          'id': 'coding-refactor',
          'categoryId': 'coding',
          'title': 'Refactor Code',
          'summary': 'Improve structure, readability, or maintainability.',
          'promptBody': 'Refactor my [component] to [improvement goal]',
          'isQuick': false,
          'enabled': true,
        },
        {
          'id': 'coding-auth',
          'categoryId': 'coding',
          'title': 'Add Authentication',
          'summary': 'Set up sign-in and access control flows.',
          'promptBody': 'Add [auth type] to my [framework] app',
          'isQuick': false,
          'enabled': true,
        },
        {
          'id': 'coding-api',
          'categoryId': 'coding',
          'title': 'Connect to API',
          'summary': 'Integrate an external API into your app flow.',
          'promptBody': 'Connect my app to [API] to [functionality]',
          'isQuick': false,
          'enabled': true,
        },
        {
          'id': 'coding-database',
          'categoryId': 'coding',
          'title': 'Set Up Database',
          'summary': 'Define storage, schema, and integration needs.',
          'promptBody': 'Set up [database] for [use case] in my app',
          'isQuick': false,
          'enabled': true,
        },
        {
          'id': 'coding-debug',
          'categoryId': 'coding',
          'title': 'Debug an Error',
          'summary': 'Investigate an error message with runtime context.',
          'promptBody': 'I\'m getting [error] when [action happens]',
          'isQuick': false,
          'enabled': true,
        },
        {
          'id': 'coding-performance',
          'categoryId': 'coding',
          'title': 'Improve Performance',
          'summary': 'Optimize slow experiences or inefficient logic.',
          'promptBody': 'My [feature] is slow, help me optimize it',
          'isQuick': false,
          'enabled': true,
        },
        {
          'id': 'coding-tests',
          'categoryId': 'coding',
          'title': 'Write Tests',
          'summary': 'Generate tests with clear coverage goals.',
          'promptBody': 'Write [test type] tests for [component]',
          'isQuick': false,
          'enabled': true,
        },
        {
          'id': 'general-explain',
          'categoryId': 'general',
          'title': 'Explain a concept',
          'summary': 'Turn a rough idea into a simple explanation.',
          'promptBody': 'Explain [concept] in simple terms with examples.',
          'isQuick': true,
          'enabled': true,
        },
        {
          'id': 'coding-review',
          'categoryId': 'coding',
          'title': 'Code review',
          'summary': 'Review code for bugs, clarity, and performance.',
          'promptBody':
              'Review this code and suggest fixes, improvements, and edge cases...',
          'isQuick': true,
          'enabled': true,
        },
        {
          'id': 'writing-blog-post',
          'categoryId': 'writing',
          'title': 'Blog Post',
          'summary': 'Write a focused article for a specific audience.',
          'promptBody': 'Write a blog post about [topic] for [audience]',
          'isQuick': false,
          'enabled': true,
        },
        {
          'id': 'writing-social-caption',
          'categoryId': 'writing',
          'title': 'Social Caption',
          'summary': 'Create platform-specific social copy with clear intent.',
          'promptBody':
              'Write a [platform] caption for [content] targeting [audience]',
          'isQuick': false,
          'enabled': true,
        },
        {
          'id': 'writing-marketing-email',
          'categoryId': 'writing',
          'title': 'Marketing Email',
          'summary': 'Draft conversion-focused email copy.',
          'promptBody': 'Write a marketing email for [product] to [audience]',
          'isQuick': false,
          'enabled': true,
        },
        {
          'id': 'writing-product-description',
          'categoryId': 'writing',
          'title': 'Product Description',
          'summary': 'Highlight benefits with persuasive product copy.',
          'promptBody':
              'Write a product description for [product] highlighting [benefits]',
          'isQuick': false,
          'enabled': true,
        },
        {
          'id': 'writing-email',
          'categoryId': 'writing',
          'title': 'Professional email',
          'summary': 'Write a clear, polished email.',
          'promptBody': 'Write a professional email about...',
          'isQuick': true,
          'enabled': true,
        },
        {
          'id': 'image-realistic-photo',
          'categoryId': 'image-generation',
          'title': 'Realistic Photo',
          'summary': 'Build a photorealistic scene with clear setting details.',
          'promptBody':
              'Create a photorealistic image of [subject] in [setting]',
          'isQuick': false,
          'enabled': true,
        },
        {
          'id': 'image-digital-art',
          'categoryId': 'image-generation',
          'title': 'Digital Art',
          'summary': 'Create stylized artwork with mood and style direction.',
          'promptBody':
              'Create digital art of [subject] in [style] with [mood]',
          'isQuick': false,
          'enabled': true,
        },
        {
          'id': 'image-logo-design',
          'categoryId': 'image-generation',
          'title': 'Logo Design',
          'summary': 'Describe a brand mark with strong aesthetic cues.',
          'promptBody': 'Design a logo for [brand] that feels [adjectives]',
          'isQuick': false,
          'enabled': true,
        },
        {
          'id': 'image-ui-screenshot',
          'categoryId': 'image-generation',
          'title': 'UI Screenshot',
          'summary': 'Create a polished product mockup or interface concept.',
          'promptBody': 'Create a UI mockup of [screen type] app with [style]',
          'isQuick': false,
          'enabled': true,
        },
        {
          'id': 'image-portrait',
          'categoryId': 'image-generation',
          'title': 'Image prompt',
          'summary': 'Describe a polished image prompt with style and mood.',
          'promptBody': 'Create a detailed image prompt for...',
          'isQuick': false,
          'enabled': true,
        },
        {
          'id': 'business-plan',
          'categoryId': 'business',
          'title': 'Business plan',
          'summary': 'Outline a clear plan with goals and structure.',
          'promptBody': 'Create a business plan for...',
          'isQuick': false,
          'enabled': true,
        },
      ],
      'homeFeatures': [
        {
          'id': 'refine',
          'title': 'Refine your prompt',
          'subtitle':
              'Start from a rough idea and turn it into a polished ask.',
          'iconKey': 'sparkles',
          'imageAssetKey': 'orb',
          'actionType': 'compose',
          'visualSize': 'large',
        },
        {
          'id': 'voice',
          'title': 'Speak instead',
          'subtitle': 'Capture your thought naturally with voice.',
          'iconKey': 'mic',
          'imageAssetKey': 'voice',
          'actionType': 'voice',
          'visualSize': 'medium',
        },
        {
          'id': 'templates',
          'title': 'Use templates',
          'subtitle': 'Start with proven prompt structures.',
          'iconKey': 'grid',
          'imageAssetKey': 'template',
          'actionType': 'templates',
          'visualSize': 'medium',
        },
      ],
      'visualAssets': [
        {
          'id': 'home-orb',
          'placement': 'home-hero',
          'lightAssetUrl': '',
          'darkAssetUrl': '',
          'altText': 'Abstract orb illustration',
        },
      ],
    });
  }
}

class CategoryConfig {
  CategoryConfig({
    required this.id,
    required this.label,
    required this.iconKey,
    required this.visualStyle,
    required this.order,
    required this.enabled,
  });

  final String id;
  final String label;
  final String iconKey;
  final String visualStyle;
  final int order;
  final bool enabled;

  factory CategoryConfig.fromJson(Map<String, dynamic> json) {
    return CategoryConfig(
      id: json['id'] as String,
      label: json['label'] as String,
      iconKey: json['iconKey'] as String,
      visualStyle: json['visualStyle'] as String? ?? 'lavender',
      order: json['order'] as int? ?? 0,
      enabled: json['enabled'] as bool? ?? true,
    );
  }
}

class ToneConfig {
  ToneConfig({
    required this.id,
    required this.label,
    required this.iconKey,
    required this.premiumOnly,
    required this.order,
    required this.promptPolicyKey,
  });

  final String id;
  final String label;
  final String iconKey;
  final bool premiumOnly;
  final int order;
  final String promptPolicyKey;

  factory ToneConfig.fromJson(Map<String, dynamic> json) {
    return ToneConfig(
      id: json['id'] as String,
      label: json['label'] as String,
      iconKey: json['iconKey'] as String,
      premiumOnly: json['premiumOnly'] as bool? ?? false,
      order: json['order'] as int? ?? 0,
      promptPolicyKey: json['promptPolicyKey'] as String,
    );
  }
}

class TemplateCategoryConfig {
  TemplateCategoryConfig({
    required this.id,
    required this.label,
    required this.iconKey,
    required this.order,
  });

  final String id;
  final String label;
  final String iconKey;
  final int order;

  factory TemplateCategoryConfig.fromJson(Map<String, dynamic> json) {
    return TemplateCategoryConfig(
      id: json['id'] as String,
      label: json['label'] as String,
      iconKey: json['iconKey'] as String,
      order: json['order'] as int? ?? 0,
    );
  }
}

class TemplateConfig {
  TemplateConfig({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.summary,
    required this.promptBody,
    required this.isQuick,
    required this.enabled,
  });

  final String id;
  final String categoryId;
  final String title;
  final String summary;
  final String promptBody;
  final bool isQuick;
  final bool enabled;

  factory TemplateConfig.fromJson(Map<String, dynamic> json) {
    return TemplateConfig(
      id: json['id'] as String,
      categoryId: json['categoryId'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String,
      promptBody: json['promptBody'] as String,
      isQuick: json['isQuick'] as bool? ?? false,
      enabled: json['enabled'] as bool? ?? true,
    );
  }
}

class HomeFeatureConfig {
  HomeFeatureConfig({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.iconKey,
    required this.imageAssetKey,
    required this.actionType,
    required this.visualSize,
  });

  final String id;
  final String title;
  final String subtitle;
  final String iconKey;
  final String imageAssetKey;
  final String actionType;
  final String visualSize;

  factory HomeFeatureConfig.fromJson(Map<String, dynamic> json) {
    return HomeFeatureConfig(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      iconKey: json['iconKey'] as String,
      imageAssetKey: json['imageAssetKey'] as String? ?? '',
      actionType: json['actionType'] as String,
      visualSize: json['visualSize'] as String? ?? 'medium',
    );
  }
}

class VisualAssetConfig {
  VisualAssetConfig({
    required this.id,
    required this.placement,
    required this.lightAssetUrl,
    required this.darkAssetUrl,
    required this.altText,
  });

  final String id;
  final String placement;
  final String lightAssetUrl;
  final String darkAssetUrl;
  final String altText;

  factory VisualAssetConfig.fromJson(Map<String, dynamic> json) {
    return VisualAssetConfig(
      id: json['id'] as String,
      placement: json['placement'] as String,
      lightAssetUrl: json['lightAssetUrl'] as String? ?? '',
      darkAssetUrl: json['darkAssetUrl'] as String? ?? '',
      altText: json['altText'] as String? ?? '',
    );
  }
}
