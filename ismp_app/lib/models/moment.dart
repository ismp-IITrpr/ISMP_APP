class MomentModel {
  final String id;
  final String imageUrl;
  final String title;

  MomentModel({
    required this.id,
    required this.imageUrl,
    required this.title,
  });

  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'title': title,
    };
  }

  factory MomentModel.fromMap(Map<String, dynamic> map, String docId) {
    return MomentModel(
      id: docId,
      imageUrl: map['imageUrl'] ?? '',
      title: map['title'] ?? '',
    );
  }
}
