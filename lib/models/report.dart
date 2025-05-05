
enum ReportType {
  daily,
  weekly,
  monthly,
  yearly,
  custom
}

enum ReportStatus {
  draft,
  submitted,
  reviewed
}

class Report {
  final String id;
  final String? userId;
  final String? title;
  final String? description;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime createdAt;
  final ReportType type;
  final ReportStatus status;
  final ReportContent content;

  Report({
    required this.id,
    this.userId,
    this.title,
    this.description,
    this.startDate,
    this.endDate,
    required this.createdAt,
    required this.type,
    required this.status,
    required this.content,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate'] as String) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      type: ReportType.values.firstWhere(
        (e) => e.toString() == 'ReportType.${json['type']}',
        orElse: () => ReportType.custom,
      ),
      status: ReportStatus.values.firstWhere(
        (e) => e.toString() == 'ReportStatus.${json['status']}',
        orElse: () => ReportStatus.draft,
      ),
      content: ReportContent.fromJson(json['content'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'content': content.toJson(),
    };
  }
}

class ReportContent {
  final String text;
  final List<String>? attachments;
  final String? notes;

  ReportContent({
    required this.text,
    this.attachments,
    this.notes,
  });

  factory ReportContent.fromJson(Map<String, dynamic> json) {
    return ReportContent(
      text: json['text'] as String? ?? '',
      attachments: (json['attachments'] as List<dynamic>?)?.cast<String>(),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'attachments': attachments,
      'notes': notes,
    };
  }
} 