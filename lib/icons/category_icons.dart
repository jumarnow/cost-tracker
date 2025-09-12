import 'package:flutter/material.dart';

// Central registry of allowed category icons. Referencing these constants
// ensures Flutter can tree-shake fonts correctly.
const List<IconData> allowedCategoryIcons = [
  Icons.restaurant,
  Icons.directions_bus,
  Icons.receipt_long,
  Icons.shopping_bag,
  Icons.attach_money,
  Icons.movie,
  Icons.health_and_safety,
  Icons.category,
  Icons.coffee,
  Icons.home,
  Icons.savings,
  Icons.sports_esports,
  Icons.school,
  Icons.pets,
  Icons.card_giftcard,
  Icons.audio_file,
];

IconData categoryIconFromCodePoint(int codePoint) {
  return allowedCategoryIcons.firstWhere(
    (icon) => icon.codePoint == codePoint,
    orElse: () => Icons.category,
  );
}
