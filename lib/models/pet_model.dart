// lib/models/pet_model.dart

class Pet {
  final int id;
  final DateTime createdAt;
  final String? userId;
  final String? name;
  final String? speciesGroup;
  final String? breed;
  final int? gender;
  final String? age;
  final double? weight;
  final String? photoUrl;
  final DateTime? birthDate;
  final String? morph;

  Pet({
    required this.id,
    required this.createdAt,
    this.userId,
    this.name,
    this.speciesGroup,
    this.breed,
    this.gender,
    this.age,
    this.weight,
    this.photoUrl,
    this.birthDate,
    this.morph,
  });

  // تبدیل دیتای خام Supabase (Map) به آبجکت Pet
  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      id: json['id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      userId: json['user_id'] as String?,
      name: json['name'] as String?,
      speciesGroup: json['species_group'] as String?,
      breed: json['breed'] as String?,
      gender: json['gender'] as int?,
      age: json['age'] as String?,
      weight: (json['weight'] as num?)?.toDouble(), // تبدیل int به double
      photoUrl: json['photo'] as String?, // نام ستون در دیتابیس photo است
      birthDate: json['birthDate'] != null ? DateTime.parse(json['birthDate'] as String) : null,
      morph: json['morph'] as String?,
    );
  }

  // تبدیل آبجکت Pet به فرمت قابل ارسال به Supabase
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'species_group': speciesGroup,
      'breed': breed,
      'gender': gender,
      'age': age,
      'weight': weight,
      'photo': photoUrl,
      'birthDate': birthDate?.toIso8601String(),
      'morph': morph,
    };
  }
}
