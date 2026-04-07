class ItemModel {
  String id;
  String title;
  String description;
  bool isCompleted;

  ItemModel({
    required this.id,
    required this.title,
    this.description = '',
    this.isCompleted = false,
  });

  ItemModel copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
  }) {
    return ItemModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
