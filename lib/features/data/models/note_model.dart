import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../../domain/entities/note_entity.dart';

class NoteModel extends NoteEntity {
  // Color Hive এ store করা যায় না, তাই int হিসেবে রাখি
  final int colorValue;
  final bool synced;

  NoteModel({
    required super.id,
    required super.title,
    required super.content,
    required this.colorValue,
    required super.createdAt,
    required super.updatedAt,
    this.synced = false,
  }) : super(color: Color(colorValue), isSynced: synced);

  factory NoteModel.fromEntity(NoteEntity entity) => NoteModel(
    id: entity.id,
    title: entity.title,
    content: entity.content,
    colorValue: entity.color.value,
    createdAt: entity.createdAt,
    updatedAt: entity.updatedAt,
    synced: entity.isSynced,
  );

  // Firestore Document → NoteModel
  // Firestore থেকে data আনার সময় এই factory ব্যবহার হবে।
  // Firestore এ DateTime, Timestamp হিসেবে store হয়।
  factory NoteModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return NoteModel(
      id: doc.id,
      title: data['title'] as String,
      content: data['content'] as String,
      colorValue: data['color'] as int,
      // Firestore Timestamp → DateTime
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      synced: true,
    );
  }

  // NoteModel → Firestore Map
  Map<String, dynamic> toFirestore() => {
    'title': title,
    'content': content,
    'color': colorValue,
    // DateTime → Firestore Timestamp
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  NoteEntity toEntity() => NoteEntity(
    id: id,
    title: title,
    content: content,
    color: Color(colorValue),
    createdAt: createdAt,
    updatedAt: updatedAt,
    isSynced: synced,
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
    final synced = reader.availableBytes > 0 ? reader.readBool() : false;

    return NoteModel(
      id: id,
      title: title,
      content: content,
      colorValue: colorValue,
      createdAt: createdAt,
      updatedAt: updatedAt,
      synced: synced,
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
    writer.writeBool(obj.synced);
  }
}
