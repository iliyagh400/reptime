/// A single specific species (شown as "گونه/نژاد"), e.g. 'کورن اسنیک'.
/// [assetKey] is the English filename slug used to look up an optional
/// custom image at assets/icons/species/<assetKey>.png. Not every species
/// needs an image yet — anywhere the image is used falls back to the
/// category emoji automatically if the file doesn't exist.
class Species {
  final String label;
  final String assetKey;
  const Species(this.label, this.assetKey);
}

/// A broad category of exotic pet (shown as "نوع/گروه"), with its emoji
/// and the list of specific species within it. More categories get
/// appended here over time — the picker UI and search automatically pick
/// up anything added to this list.
class SpeciesCategory {
  final String name;
  final String emoji;
  final List<Species> species;
  const SpeciesCategory(this.name, this.emoji, this.species);
}

const List<SpeciesCategory> speciesCategories = [
  SpeciesCategory('مار', '🐍', [
    Species('کورن اسنیک', 'corn_snake'),
    Species('بال پایتون', 'ball_python'),
    Species('کینگ اسنیک', 'king_snake'),
    Species('برمیز پایتون', 'burmese_python'),
    Species('بوآ', 'boa'),
    Species('گرین تری پایتون', 'green_tree_python'),
    Species('بوآی درختی', 'tree_boa'),
    Species('میلک اسنیک', 'milk_snake'),
    Species('رتیکولیتد پایتون', 'reticulated_python'),
    Species('هاگنوز اسنیک', 'hognose_snake'),
    Species('رت اسنیک', 'rat_snake'),
    Species('رینبو بوآ', 'rainbow_boa'),
  ]),
  SpeciesCategory('سوسمار', '🦎', [
    Species('ایگوانا', 'iguana'),
    Species('بیردد دراگون', 'bearded_dragon'),
    Species('مانیتور', 'monitor'),
    Species('آفتاب‌پرست', 'chameleon'),
    Species('اسکینک', 'skink'),
    Species('تگو', 'tegu'),
  ]),
  SpeciesCategory('گکو', '🦎', [
    Species('لپرد گکو', 'leopard_gecko'),
    Species('فت تیل گکو', 'fat_tail_gecko'),
    Species('دی گکو', 'day_gecko'),
    Species('کرستد گکو', 'crested_gecko'),
    Species('گارگویل گکو', 'gargoyle_gecko'),
  ]),
  SpeciesCategory('لاک‌پشت', '🐢', [
    Species('سولکاتا', 'sulcata'),
    Species('گوش قرمز', 'red_eared_slider'),
    Species('پیگ نوز', 'pig_nose_turtle'),
    Species('سافت شل', 'softshell_turtle'),
    Species('مپ', 'map_turtle'),
    Species('همیلتون', 'hamilton_turtle'),
    Species('کامان اسنپینگ', 'common_snapping_turtle'),
    Species('الیگیتور اسنپینگ', 'alligator_snapping_turtle'),
    Species('فلوریدا اسنپینگ', 'florida_snapping_turtle'),
    Species('پینک بلی', 'pink_belly_turtle'),
    Species('یلو اسپاتد', 'yellow_spotted_turtle'),
    Species('لاک‌پشت آبی', 'aquatic_turtle'),
    Species('لاک‌پشت خاکی', 'tortoise'),
  ]),
  SpeciesCategory('بندپایان', '🕷️', [
    Species('تارانتولا', 'tarantula'),
    Species('عقرب', 'scorpion'),
    Species('سانتیپید', 'centipede'),
    Species('میلیپید', 'millipede'),
    Species('سوسک', 'roach'),
    Species('جیرجیرک', 'cricket'),
    Species('کرم', 'worm'),
  ]),
  SpeciesCategory('آکواریوم', '🐠', [
    Species('ماهی', 'fish'),
    Species('حلزون', 'snail'),
    Species('گیاه آبی', 'aquatic_plant'),
    Species('خرچنگ', 'crab'),
    Species('شریمپ', 'shrimp'),
  ]),
  SpeciesCategory('دوزیست', '🐸', [
    Species('قورباغه', 'frog'),
    Species('وزغ', 'toad'),
    Species('سمندر', 'salamander'),
  ]),
];

const String otherSpeciesLabel = 'دیگر (خودم می‌نویسم)';
const String defaultSpeciesEmoji = '🐾';
const String speciesImageFolder = 'assets/icons/species';



/// آیکون پیش‌فرض گروه — وقتی کاربر «دیگر» انتخاب کرده یا breed ناشناخته‌ست
const Map<String, String> defaultSpeciesAssetForGroup = {
  'مار':      'default_snake',
  'سوسمار':   'default_lizard',
  'گکو':      'default_gecko',
  'لاک‌پشت':  'default_turtle',
  'بندپایان': 'default_arthropod',
  'آکواریوم': 'default_aquatic',
  'دوزیست':   'default_amphibian',
};
/// آیکون پیش‌فرض برای گزینه «دیگر» در هر دسته
String? defaultImagePathForGroup(String categoryName) {
  const map = {
    'مار': 'default_snake',     
  'سوسمار':   'default_lizard',
  'گکو':      'default_gecko',
  'لاک‌پشت':  'default_turtle',
  'بندپایان': 'default_arthropod',
  'آکواریوم': 'default_aquatic',
  'دوزیست':   'default_amphibian',
    // ... باقی دسته‌ها را با assetKey آیکون پیش‌فرض خودتان پر کنید
  };
  final key = map[categoryName];
  return key == null ? null : '$speciesImageFolder/$key.png';
}


/// Returns the emoji matching a pet's stored species_group (category)
/// text. Falls back to a generic paw print for anything custom/typed
/// manually that isn't in the known category list.
String emojiForSpeciesGroup(String? speciesGroup) {
  if (speciesGroup == null) return defaultSpeciesEmoji;
  for (final category in speciesCategories) {
    if (category.name == speciesGroup) return category.emoji;
  }
  return defaultSpeciesEmoji;
}


String? imagePathForBreed(String? breed, {String? speciesGroup}) {
  if (breed == null || breed.trim().isEmpty) return null;

  // جستجوی دقیق در لیست گونه‌های شناخته‌شده
  for (final category in speciesCategories) {
    for (final species in category.species) {
      if (species.label == breed) {
        return '$speciesImageFolder/${species.assetKey}.png';
      }
    }
  }

  // breed ناشناخته یا «دیگر» → آیکون پیش‌فرض گروه
  return _defaultAssetForGroup(speciesGroup);
}

String? _defaultAssetForGroup(String? speciesGroup) {
  if (speciesGroup == null) return null;
  final assetKey = defaultSpeciesAssetForGroup[speciesGroup];
  if (assetKey == null) return null;
  return '$speciesImageFolder/$assetKey.png';
}

/// A single search-result row: which category a species belongs to, plus
/// the species itself. Used to build the flat, searchable list in the
/// species picker page.
class SpeciesSearchResult {
  final String categoryName;
  final String categoryEmoji;
  final Species species;
  const SpeciesSearchResult(
      this.categoryName, this.categoryEmoji, this.species);
}

List<SpeciesSearchResult> allSpeciesFlat() {
  final List<SpeciesSearchResult> results = [];
  for (final category in speciesCategories) {
    for (final species in category.species) {
      results.add(SpeciesSearchResult(category.name, category.emoji, species));
    }
  }
  return results;
}