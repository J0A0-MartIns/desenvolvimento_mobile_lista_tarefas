class ItemModel {
  String id;
  String title;
  String description;
  bool isCompleted;
  DateTime? dueDate;

  ItemModel({
    required this.id,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    this.dueDate,
  });

  ItemModel copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? dueDate,
  }) {
    return ItemModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: dueDate ?? this.dueDate,
    );
  }
}
