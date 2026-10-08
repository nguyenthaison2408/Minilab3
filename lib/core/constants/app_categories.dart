import 'package:flutter/material.dart';
import 'app_colors.dart';

enum ExpenseCategory {
  food,
  study,
  travel,
  gear,
  entertainment,
}

extension ExpenseCategoryExtension on ExpenseCategory {
  String get nameString {
    switch (this) {
      case ExpenseCategory.food:
        return 'Food';
      case ExpenseCategory.study:
        return 'Study';
      case ExpenseCategory.travel:
        return 'Travel';
      case ExpenseCategory.gear:
        return 'Gear';
      case ExpenseCategory.entertainment:
        return 'Entertainment';
    }
  }

  String get displayNameVi {
    switch (this) {
      case ExpenseCategory.food:
        return 'Ăn uống';
      case ExpenseCategory.study:
        return 'Học tập';
      case ExpenseCategory.travel:
        return 'Di chuyển';
      case ExpenseCategory.gear:
        return 'Thiết bị';
      case ExpenseCategory.entertainment:
        return 'Giải trí';
    }
  }

  IconData get icon {
    switch (this) {
      case ExpenseCategory.food:
        return Icons.restaurant_rounded;
      case ExpenseCategory.study:
        return Icons.menu_book_rounded;
      case ExpenseCategory.travel:
        return Icons.directions_car_rounded;
      case ExpenseCategory.gear:
        return Icons.devices_rounded;
      case ExpenseCategory.entertainment:
        return Icons.movie_filter_rounded;
    }
  }

  Color get color {
    switch (this) {
      case ExpenseCategory.food:
        return AppColors.food;
      case ExpenseCategory.study:
        return AppColors.study;
      case ExpenseCategory.travel:
        return AppColors.travel;
      case ExpenseCategory.gear:
        return AppColors.gear;
      case ExpenseCategory.entertainment:
        return AppColors.entertainment;
    }
  }

  static ExpenseCategory fromString(String category) {
    final lower = category.toLowerCase().trim();
    switch (lower) {
      case 'food':
      case 'ăn uống':
      case 'ẩm thực':
        return ExpenseCategory.food;
      case 'study':
      case 'học tập':
      case 'sách':
        return ExpenseCategory.study;
      case 'travel':
      case 'di chuyển':
      case 'xe':
      case 'xăng':
        return ExpenseCategory.travel;
      case 'gear':
      case 'thiết bị':
      case 'công nghệ':
        return ExpenseCategory.gear;
      case 'entertainment':
      case 'giải trí':
      case 'xem phim':
        return ExpenseCategory.entertainment;
      default:
        return ExpenseCategory.food;
    }
  }
}

