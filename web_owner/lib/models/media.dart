class PetMedia {
  final String id;
  final String petId;
  final String uploadedBy;
  final String? uploadedByName;
  final String? medicalRecordId;
  final String? recordTitle;
  final String mediaType;
  final String filename;
  final String? originalName;
  final String mimeType;
  final int fileSize;
  final String url;
  final String? title;
  final String? description;
  final bool isPrivate;
  final DateTime createdAt;

  const PetMedia({
    required this.id,
    required this.petId,
    required this.uploadedBy,
    this.uploadedByName,
    this.medicalRecordId,
    this.recordTitle,
    required this.mediaType,
    required this.filename,
    this.originalName,
    required this.mimeType,
    required this.fileSize,
    required this.url,
    this.title,
    this.description,
    required this.isPrivate,
    required this.createdAt,
  });

  factory PetMedia.fromJson(Map<String, dynamic> j) => PetMedia(
        id: j['id'] as String,
        petId: j['pet_id'] as String,
        uploadedBy: j['uploaded_by'] as String,
        uploadedByName: j['uploaded_by_name'] as String?,
        medicalRecordId: j['medical_record_id'] as String?,
        recordTitle: j['record_title'] as String?,
        mediaType: j['media_type'] as String,
        filename: j['filename'] as String,
        originalName: j['original_name'] as String?,
        mimeType: j['mime_type'] as String,
        fileSize: (j['file_size'] as num).toInt(),
        url: j['url'] as String,
        title: j['title'] as String?,
        description: j['description'] as String?,
        isPrivate: j['is_private'] as bool? ?? false,
        createdAt: DateTime.parse(j['created_at'] as String),
      );

  String get displayName => title ?? originalName ?? filename;

  String get sizeLabel {
    if (fileSize < 1024) return '${fileSize} B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  bool get isImage =>
      mimeType.startsWith('image/') || mediaType == 'image' || mediaType == 'xray';
}
