import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../domain/entities/note_entity.dart';

// Model = Entity + Database conversion logic।


class NoteModel extends NoteEntity {
  // Color Hive এ store করা যায় না, তাই int হিসেবে রাখি
  final int colorValue;

  NoteModel({
    required String id,
    required String title,
    required String content,
    required this.colorValue,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(
         id: id,
         title: title,
         content: content,
         color: Color(colorValue),
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  factory NoteModel.fromEntity(NoteEntity entity) => NoteModel(
    id: entity.id,
    title: entity.title,
    content: entity.content,
    colorValue: entity.color.value,
    createdAt: entity.createdAt,
    updatedAt: entity.updatedAt,
  );

  NoteEntity toEntity() => NoteEntity(
    id: id,
    title: title,
    content: content,
    color: Color(colorValue),
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}


// Hive নিজে Custom class জানে না।
// TypeAdapter বলে দেয়: "NoteModel কীভাবে read/write করবে।"
//
// typeId: 0 → প্রতিটি Model এর জন্য আলাদা unique int দিতে হবে।
//
// গুরুত্বপূর্ণ নিয়ম:
//   write() এ যে order এ লিখবে,
//   read()  এ ঠিক সেই order এ পড়তে হবে।

class NoteModelAdapter extends TypeAdapter<NoteModel> {
  @override
  final int typeId = 0;

  // Hive থেকে bytes পড়ে NoteModel তৈরি করো
  @override
  NoteModel read(BinaryReader reader) {
    final id = reader.readString();
    final title = reader.readString();
    final content = reader.readString();
    final colorValue = reader.readInt();
    // DateTime Hive এ int হিসেবে store হয়, তাই convert করতে হয়
    final createdAt = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    final updatedAt = DateTime.fromMillisecondsSinceEpoch(reader.readInt());

    return NoteModel(
      id: id,
      title: title,
      content: content,
      colorValue: colorValue,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // NoteModel কে bytes এ রূপান্তর করে Hive এ সংরক্ষণ করো
  @override
  void write(BinaryWriter writer, NoteModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.title);
    writer.writeString(obj.content);
    writer.writeInt(obj.colorValue);
    // DateTime → int (milliseconds since epoch)
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    writer.writeInt(obj.updatedAt.millisecondsSinceEpoch);
  }
}
