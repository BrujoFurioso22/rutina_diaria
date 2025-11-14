import 'package:flutter/material.dart';

/// Conversión de cadenas persistidas a iconos materiales.
class IconMapper {
  static IconData resolve(String name) {
    switch (name) {
      case 'sunny':
        return Icons.wb_sunny_rounded;
      case 'nightlight':
        return Icons.nightlight_round;
      case 'fitness_center':
        return Icons.fitness_center_rounded;
      case 'self_improvement':
        return Icons.self_improvement;
      case 'spa':
        return Icons.spa_rounded;
      case 'work':
        return Icons.work_history_rounded;
      case 'study':
        return Icons.menu_book_rounded;
      case 'custom':
        return Icons.auto_awesome_rounded;
      case 'coffee':
        return Icons.coffee_rounded;
      case 'breakfast_dining':
        return Icons.breakfast_dining_rounded;
      case 'local_dining':
        return Icons.local_dining_rounded;
      case 'bedtime':
        return Icons.bedtime_rounded;
      case 'alarm':
        return Icons.alarm_rounded;
      case 'water_drop':
        return Icons.water_drop_rounded;
      case 'favorite':
        return Icons.favorite_rounded;
      case 'music_note':
        return Icons.music_note_rounded;
      case 'book':
        return Icons.book_rounded;
      case 'school':
        return Icons.school_rounded;
      case 'sports_soccer':
        return Icons.sports_soccer_rounded;
      case 'directions_run':
        return Icons.directions_run_rounded;
      case 'pool':
        return Icons.pool_rounded;
      case 'beach_access':
        return Icons.beach_access_rounded;
      case 'shopping_cart':
        return Icons.shopping_cart_rounded;
      case 'cleaning_services':
        return Icons.cleaning_services_rounded;
      case 'pets':
        return Icons.pets_rounded;
      case 'family_restroom':
        return Icons.family_restroom_rounded;
      case 'celebration':
        return Icons.celebration_rounded;
      case 'cake':
        return Icons.cake_rounded;
      case 'flight':
        return Icons.flight_rounded;
      case 'directions_car':
        return Icons.directions_car_rounded;
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'movie':
        return Icons.movie_rounded;
      case 'games':
        return Icons.games_rounded;
      case 'brush':
        return Icons.brush_rounded;
      case 'palette':
        return Icons.palette_rounded;
      case 'photo_camera':
        return Icons.photo_camera_rounded;
      case 'videocam':
        return Icons.videocam_rounded;
      case 'headphones':
        return Icons.headphones_rounded;
      case 'phone':
        return Icons.phone_rounded;
      case 'mail':
        return Icons.mail_rounded;
      case 'chat':
        return Icons.chat_rounded;
      case 'shopping_bag':
        return Icons.shopping_bag_rounded;
      case 'local_grocery_store':
        return Icons.local_grocery_store_rounded;
      case 'home':
        return Icons.home_rounded;
      case 'work_outline':
        return Icons.work_outline_rounded;
      case 'fitness_center_outline':
        return Icons.fitness_center_outlined;
      case 'spa_outline':
        return Icons.spa_outlined;
      case 'nature':
        return Icons.nature_rounded;
      case 'park':
        return Icons.park_rounded;
      case 'star':
        return Icons.star_rounded;
      case 'lightbulb':
        return Icons.lightbulb_rounded;
      case 'flash_on':
        return Icons.flash_on_rounded;
      case 'bolt':
        return Icons.bolt_rounded;
      case 'favorite_border':
        return Icons.favorite_border_rounded;
      case 'thumb_up':
        return Icons.thumb_up_rounded;
      case 'mood':
        return Icons.mood_rounded;
      case 'sentiment_satisfied':
        return Icons.sentiment_satisfied_rounded;
      case 'check_circle':
        return Icons.check_circle_rounded;
      case 'task_alt':
        return Icons.task_alt_rounded;
      default:
        return Icons.task_alt_rounded;
    }
  }

  static List<String> availableIconNames() {
    return const [
      'sunny',
      'nightlight',
      'fitness_center',
      'self_improvement',
      'spa',
      'work',
      'study',
      'custom',
    ];
  }

  static List<String> allIconNames() {
    return const [
      'sunny',
      'nightlight',
      'fitness_center',
      'self_improvement',
      'spa',
      'work',
      'study',
      'custom',
      'coffee',
      'breakfast_dining',
      'local_dining',
      'bedtime',
      'alarm',
      'water_drop',
      'favorite',
      'music_note',
      'book',
      'school',
      'sports_soccer',
      'directions_run',
      'pool',
      'beach_access',
      'shopping_cart',
      'cleaning_services',
      'pets',
      'family_restroom',
      'celebration',
      'cake',
      'flight',
      'directions_car',
      'restaurant',
      'movie',
      'games',
      'brush',
      'palette',
      'photo_camera',
      'videocam',
      'headphones',
      'phone',
      'mail',
      'chat',
      'shopping_bag',
      'local_grocery_store',
      'home',
      'work_outline',
      'fitness_center_outline',
      'spa_outline',
      'nature',
      'park',
      'star',
      'lightbulb',
      'flash_on',
      'bolt',
      'favorite_border',
      'thumb_up',
      'mood',
      'sentiment_satisfied',
      'check_circle',
      'task_alt',
    ];
  }
}
