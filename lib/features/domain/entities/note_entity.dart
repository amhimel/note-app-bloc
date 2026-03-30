import 'package:flutter/material.dart';

class NoteEntity {
  final String id;
  final String title;
  final String content;
  final Color color;
  final DateTime createdAt;
  final DateTime updatedAt;

  NoteEntity({
    required this.id,
    required this.title,
    required this.content,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  NoteEntity copyWith({
    String? id,
    String? title,
    String? content,
    Color? color,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NoteEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is NoteEntity && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'NoteEntity(id: $id, title: $title)';
  }
}
