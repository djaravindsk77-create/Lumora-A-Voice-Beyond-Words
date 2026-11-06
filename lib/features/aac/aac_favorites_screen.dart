import 'package:flutter/material.dart';

import 'aac_board_screen.dart';

/// Favorites board - same interaction as a category board, but shows the
/// child's favourite cards across all categories.
class AacFavoritesScreen extends StatelessWidget {
  const AacFavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AacBoardScreen(categoryId: 'favorites');
  }
}
