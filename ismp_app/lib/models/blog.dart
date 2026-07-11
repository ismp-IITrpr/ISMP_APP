import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum BlogTag { club, academic, sports, tech, campus }

extension BlogTagExtension on BlogTag {
  String get label {
    switch (this) {
      case BlogTag.club:
        return 'Clubs';
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

  Color get color => AppColors.secondaryAccent;

  Color get bgColor => AppColors.primaryWith(0.3);
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
        orElse: () => BlogTag.club,
      ),
    );
  }
}


