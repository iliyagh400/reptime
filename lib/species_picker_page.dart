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

class SpeciesPickerPage extends StatefulWidget {
  const SpeciesPickerPage({super.key});

  @override
  State<SpeciesPickerPage> createState() => _SpeciesPickerPageState();
}

class _SpeciesPickerPageState extends State<SpeciesPickerPage> {
  final _searchController = TextEditingController();
  String _query = '';

  static const _green = Color(0xFF3F5D45);

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
              child: Text(
                'چیزی پیدا نشد',
                style: TextStyle(color: Colors.grey[600]),
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

    return Scaffold(
      appBar: AppBar(title: const Text('انتخاب گونه')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'جستجوی گونه یا نوع...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFC9D0BA)),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                ...content,
                const SizedBox(height: 8),
                _customOptionTile(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryHeader(String name, String emoji) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _speciesLeadingIcon(String categoryEmoji, Species species) {
    final imagePath = '$speciesImageFolder/${species.assetKey}.png';
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 32,
        height: 32,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC9D0BA)),
      ),
      child: ListTile(
        leading: _speciesLeadingIcon(emoji, species),
        title: Text(species.label),
        subtitle: _query.trim().isNotEmpty
            ? Text(categoryName,
                style: TextStyle(fontSize: 11, color: Colors.grey[500]))
            : null,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _green, width: 1.2),
      ),
      child: ListTile(
        leading: const Icon(Icons.edit, color: _green, size: 20),
        title: const Text(
          'دیگر (خودم می‌نویسم)',
          style: TextStyle(fontWeight: FontWeight.w600, color: _green),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: const Border.fromBorderSide(
            BorderSide(color: _green, width: 1.4)),
      ),
      child: ListTile(
        leading: const Icon(Icons.edit, color: _green),
        title: const Text(
          'نوع/دسته‌ی دیگه‌ای هم نیست (خودم می‌نویسم)',
          style: TextStyle(fontWeight: FontWeight.w600, color: _green),
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