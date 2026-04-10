class ItemModel {
  String id;
  String title;
  String description;
  bool isCompleted;
  DateTime? dueDate;
  String ownerEmail;

  ItemModel({
    required this.id,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    this.dueDate,
    required this.ownerEmail,
  });

  ItemModel copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? dueDate,
    String? ownerEmail,
  }) {
    return ItemModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: dueDate ?? this.dueDate,
      ownerEmail: ownerEmail ?? this.ownerEmail,
    );
  }
}
