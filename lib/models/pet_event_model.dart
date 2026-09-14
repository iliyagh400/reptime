// lib/models/pet_event_model.dart

class PetEvent {
  final int id;
  final DateTime createdAt;
  final String? userId;
  final int petId;
  final String description;
  final DateTime eventDate;

  PetEvent({
    required this.id,
    required this.createdAt,
    this.userId,
    required this.petId,
    required this.description,
    required this.eventDate,
  });

  factory PetEvent.fromJson(Map<String, dynamic> json) {
    return PetEvent(
      id: json['id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      userId: json['user_id'] as String?,
      petId: json['pet_id'] as int,
      description: (json['description'] as String?) ?? '',
      eventDate: DateTime.parse(json['event_date'] as String),
    );
  }

  Map<String, dynamic> toJson({String? currentUserId}) {
    final map = <String, dynamic>{
      'pet_id': petId,
      'description': description,
      'event_date': eventDate.toIso8601String(),
    };

    if (currentUserId != null) {
      map['user_id'] = currentUserId;
    }

    return map;
  }
}
