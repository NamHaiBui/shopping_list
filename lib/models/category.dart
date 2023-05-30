import 'package:flutter/material.dart';

enum Categories {
  vegetables,
  fruit,
  meat,
  dairy,
  carbs,
  sweets,
  spices,
  hygiene,
  convenience,
  other,
}

class Category {
  final Color color;
  final String title;
  const Category(this.title, this.color);
}
