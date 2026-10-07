class JobSite {
  const JobSite({
    required this.id,
    required this.name,
    required this.note,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String note;
  final DateTime createdAt;

  JobSite copyWith({String? name, String? note}) {
    return JobSite(
      id: id,
      name: name ?? this.name,
      note: note ?? this.note,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'note': note,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };

  factory JobSite.fromJson(Map<String, dynamic> json) {
    return JobSite(
      id: json['id'] as String,
      name: json['name'] as String,
      note: (json['note'] as String?) ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
    );
  }
}

class SitePhoto {
  const SitePhoto({
    required this.id,
    required this.siteId,
    required this.fileName,
    required this.memo,
    required this.takenAt,
  });

  final String id;
  final String siteId;
  final String fileName;
  final String memo;
  final DateTime takenAt;

  SitePhoto copyWith({String? memo, DateTime? takenAt}) {
    return SitePhoto(
      id: id,
      siteId: siteId,
      fileName: fileName,
      memo: memo ?? this.memo,
      takenAt: takenAt ?? this.takenAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'siteId': siteId,
    'fileName': fileName,
    'memo': memo,
    'takenAt': takenAt.millisecondsSinceEpoch,
  };

  factory SitePhoto.fromJson(Map<String, dynamic> json) {
    return SitePhoto(
      id: json['id'] as String,
      siteId: json['siteId'] as String,
      fileName: json['fileName'] as String,
      memo: (json['memo'] as String?) ?? '',
      takenAt: DateTime.fromMillisecondsSinceEpoch(json['takenAt'] as int),
    );
  }
}

class SavedReport {
  const SavedReport({
    required this.id,
    required this.siteId,
    required this.siteName,
    required this.reportDate,
    required this.createdAt,
    required this.photoCount,
    required this.summary,
    required this.pdfFileName,
  });

  final String id;
  final String siteId;
  final String siteName;
  final DateTime reportDate;
  final DateTime createdAt;
  final int photoCount;
  final String summary;
  final String pdfFileName;

  Map<String, dynamic> toJson() => {
    'id': id,
    'siteId': siteId,
    'siteName': siteName,
    'reportDate': reportDate.millisecondsSinceEpoch,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'photoCount': photoCount,
    'summary': summary,
    'pdfFileName': pdfFileName,
  };

  factory SavedReport.fromJson(Map<String, dynamic> json) {
    return SavedReport(
      id: json['id'] as String,
      siteId: json['siteId'] as String,
      siteName: json['siteName'] as String,
      reportDate: DateTime.fromMillisecondsSinceEpoch(
        json['reportDate'] as int,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      photoCount: json['photoCount'] as int,
      summary: (json['summary'] as String?) ?? '',
      pdfFileName: json['pdfFileName'] as String,
    );
  }
}
