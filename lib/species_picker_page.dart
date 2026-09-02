import 'package:flutter/material.dart';
import 'species_data.dart';

/// Result returned when the user picks a species: category (نوع/گروه) and
/// the specific species name (گونه/نژاد). If the user chooses "خودم
/// می‌نویسم", [isCustom] is true and [speciesName] is empty — the calling
/// page should show its own free-text field in that case.
class SpeciesPickResult {
  final String categoryName;
  final String speciesName;
  final bool isCustom;
  const SpeciesPickResult({
    required this.categoryName,
    required this.speciesName,
    this.isCustom = false,
  });
}

/// Premium redesigned SpeciesPickerPage.
///
/// The existing search/filter logic, category navigation and the
/// SpeciesPickResult payloads are preserved. This file focuses on
/// presentation, matching the dark terrarium style of HomePage.
class SpeciesPickerPage extends StatefulWidget {
  const SpeciesPickerPage({super.key});

  @override
  State<SpeciesPickerPage> createState() => _SpeciesPickerPageState();
}

class _SpeciesPickerPageState extends State<SpeciesPickerPage> {
  // Dark Terrarium palette — visual styling only.
  static const _ink = Color(0xFFECE8DD);
  static const _muted = Color(0xFFA8A99A);
  static const _forest = Color(0xFF6E8B52);
  static const _cream = Color(0xFF141C17);
  static const _line = Color(0xFF3A463C);
  static const _terracotta = Color(0xFFB86F4D);
  static const _leaf = Color(0xFF486344);
  static const _surface = Color(0xFF263229);
  static const _surfaceRaised = Color(0xFF2D3930);
  static const _inputBg = Color(0xFF1C2621);

  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim();

    final List<Widget> content = [];

    if (query.isEmpty) {
      for (final category in speciesCategories) {
        content.add(_categoryHeader(category.name, category.emoji));
        for (final species in category.species) {
          content.add(
              _speciesTile(category.name, category.emoji, species));
        }
        content.add(_customWithinCategoryTile(category.name));
      }
    } else {
      final results = allSpeciesFlat().where((r) {
        return r.species.label.contains(query) ||
            r.categoryName.contains(query);
      }).toList();

      if (results.isEmpty) {
        content.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: _surface,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.search_off_rounded,
                      color: _forest,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'چیزی پیدا نشد',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        for (final r in results) {
          content.add(_speciesTile(r.categoryName, r.categoryEmoji, r.species));
        }
      }
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _cream,
        appBar: AppBar(
          backgroundColor: _cream,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: const IconThemeData(color: _ink),
          title: const Text(
            'انتخاب گونه',
            style: TextStyle(
              color: _ink,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                cursorColor: _terracotta,
                decoration: InputDecoration(
                  hintText: 'جستجوی گونه یا نوع...',
                  hintStyle: TextStyle(
                    color: _muted.withOpacity(.8),
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: _muted,
                    size: 21,
                  ),
                  suffixIcon: query.isNotEmpty
                      ? IconButton(
                          splashRadius: 18,
                          icon: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: _muted,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: _inputBg,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: _line.withOpacity(.6)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _forest, width: 1.6),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  ...content,
                  const SizedBox(height: 8),
                  _customOptionTile(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryHeader(String name, String emoji) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 10),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _leaf.withOpacity(.22),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 15)),
            ),
          ),
          const SizedBox(width: 9),
          Text(
            name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(height: 1, color: _line.withOpacity(.5)),
          ),
        ],
      ),
    );
  }

  Widget _speciesLeadingIcon(String categoryEmoji, Species species) {
    final imagePath = '$speciesImageFolder/${species.assetKey}.png';
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 34,
        height: 34,
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Text(categoryEmoji, style: const TextStyle(fontSize: 20)),
            );
          },
        ),
      ),
    );
  }

  Widget _speciesTile(String categoryName, String emoji, Species species) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line.withOpacity(.78)),
      ),
      child: ListTile(
        leading: _speciesLeadingIcon(emoji, species),
        title: Text(
          species.label,
          style: const TextStyle(
            color: _ink,
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: _query.trim().isNotEmpty
            ? Text(
                categoryName,
                style: const TextStyle(fontSize: 11, color: _muted),
              )
            : null,
        trailing: const Icon(
          Icons.chevron_left_rounded,
          color: _muted,
          size: 20,
        ),
        onTap: () {
          Navigator.pop(
            context,
            SpeciesPickResult(
              categoryName: categoryName,
              speciesName: species.label,
            ),
          );
        },
      ),
    );
  }

  Widget _customWithinCategoryTile(String categoryName) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _forest, width: 1.2),
      ),
      child: ListTile(
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _forest.withOpacity(.18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.edit_rounded, color: _forest, size: 18),
        ),
        title: const Text(
          'دیگر (خودم می‌نویسم)',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: _forest,
            fontSize: 13.5,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_left_rounded,
          color: _muted,
          size: 20,
        ),
        onTap: () {
          Navigator.pop(
            context,
            SpeciesPickResult(
              categoryName: categoryName,
              speciesName: '',
              isCustom: true,
            ),
          );
        },
      ),
    );
  }

  Widget _customOptionTile() {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceRaised,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _terracotta, width: 1.3),
      ),
      child: ListTile(
        leading: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _terracotta.withOpacity(.16),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.edit_rounded, color: _terracotta, size: 19),
        ),
        title: const Text(
          'نوع/دسته‌ی دیگه‌ای هم نیست (خودم می‌نویسم)',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: _terracotta,
            fontSize: 13,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_left_rounded,
          color: _muted,
          size: 20,
        ),
        onTap: () {
          Navigator.pop(
            context,
            const SpeciesPickResult(
              categoryName: '',
              speciesName: '',
              isCustom: true,
            ),
          );
        },
      ),
    );
  }
}
