// lib/models/completion_model.dart

class Completion {
  final int id;
  final DateTime createdAt;
  final String? userId;
  final int routineId;
  final int? petId;
  final DateTime completedAt;
  final String status; // 'completed', 'skipped', etc.
  final String? note;

  Completion({
    required this.id,
    required this.createdAt,
    this.userId,
    required this.routineId,
    this.petId,
    required this.completedAt,
    this.status = 'completed',
    this.note,
  });

  factory Completion.fromJson(Map<String, dynamic> json) {
    return Completion(
      id: json['id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      userId: json['user_id'] as String?,
      routineId: json['routine_id'] as int,
      petId: json['pet_id'] as int?,
      completedAt: DateTime.parse(json['completed_at'] as String),
      status: (json['status'] as String?) ?? 'completed',
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson({String? currentUserId}) {
    final map = <String, dynamic>{
      'routine_id': routineId,
      'pet_id': petId,
      'completed_at': completedAt.toIso8601String(),
      'status': status,
      'note': note,
    };

    if (currentUserId != null) {
      map['user_id'] = currentUserId;
    }

    return map;
  }
}
