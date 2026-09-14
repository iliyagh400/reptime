// lib/models/pet_checkin_model.dart

class PetCheckin {
  final int id;
  final DateTime createdAt;
  final String? userId;
  final int petId;
  final double? weight;
  final int? healthScore;
  final String? note;
  final DateTime checkinDate;

  PetCheckin({
    required this.id,
    required this.createdAt,
    this.userId,
    required this.petId,
    this.weight,
    this.healthScore,
    this.note,
    required this.checkinDate,
  });

  factory PetCheckin.fromJson(Map<String, dynamic> json) {
    return PetCheckin(
      id: json['id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      userId: json['user_id'] as String?,
      petId: json['pet_id'] as int,
      weight: (json['weight'] as num?)?.toDouble(),
      healthScore: json['health_score'] as int?,
      note: json['note'] as String?,
      checkinDate: DateTime.parse(json['checkin_date'] as String),
    );
  }

  Map<String, dynamic> toJson({String? currentUserId}) {
    final map = <String, dynamic>{
      'pet_id': petId,
      'weight': weight,
      'health_score': healthScore,
      'note': note,
      'checkin_date': checkinDate.toIso8601String(),
    };

    if (currentUserId != null) {
      map['user_id'] = currentUserId;
    }

    return map;
  }
}

