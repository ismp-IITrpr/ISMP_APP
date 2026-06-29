import 'package:flutter/material.dart';

enum BlogTag { cluv, academic, sports, tech, campus }

extension BlogTagExtension on BlogTag {
  String get label {
    switch (this) {
      case BlogTag.cluv:
        return 'CLUV';
      case BlogTag.academic:
        return 'Academic';
      case BlogTag.sports:
        return 'Sports';
      case BlogTag.tech:
        return 'Tech';
      case BlogTag.campus:
        return 'Campus Life';
    }
  }

  Color get color {
    switch (this) {
      case BlogTag.cluv:
        return const Color(0xFF8B78FF);
      case BlogTag.academic:
        return const Color(0xFF2196F3);
      case BlogTag.sports:
        return const Color(0xFFFF9800);
      case BlogTag.tech:
        return const Color(0xFF4CAF50);
      case BlogTag.campus:
        return const Color(0xFFE91E63);
    }
  }

  Color get bgColor {
    switch (this) {
      case BlogTag.cluv:
        return const Color(0xFF2E2A4A);
      case BlogTag.academic:
        return const Color(0xFF1A2E42);
      case BlogTag.sports:
        return const Color(0xFF3A2800);
      case BlogTag.tech:
        return const Color(0xFF1A3020);
      case BlogTag.campus:
        return const Color(0xFF3A1525);
    }
  }
}

class BlogPost {
  final String id;
  final String title;
  final String summary;
  final String content;
  final String author;
  final String date;
  final int readMinutes;
  final BlogTag tag;

  const BlogPost({
    required this.id,
    required this.title,
    required this.summary,
    required this.content,
    required this.author,
    required this.date,
    required this.readMinutes,
    required this.tag,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'summary': summary,
      'content': content,
      'author': author,
      'date': date,
      'readMinutes': readMinutes,
      'tag': tag.name,
    };
  }

  factory BlogPost.fromMap(Map<String, dynamic> map, String documentId) {
    return BlogPost(
      id: documentId,
      title: map['title'] ?? '',
      summary: map['summary'] ?? '',
      content: map['content'] ?? '',
      author: map['author'] ?? '',
      date: map['date'] ?? '',
      readMinutes: map['readMinutes'] ?? 0,
      tag: BlogTag.values.firstWhere(
        (t) => t.name == map['tag'],
        orElse: () => BlogTag.cluv,
      ),
    );
  }
}


