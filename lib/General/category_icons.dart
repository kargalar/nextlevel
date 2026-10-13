import 'package:flutter/material.dart';

/// Predefined icons for categories to enable tree shaking
class CategoryIcons {
  // Common category icons
  static const IconData category = Icons.category;
  static const IconData work = Icons.work;
  static const IconData home = Icons.home;
  static const IconData school = Icons.school;
  static const IconData shoppingCart = Icons.shopping_cart;
  static const IconData fitnessCenter = Icons.fitness_center;
  static const IconData restaurant = Icons.restaurant;
  static const IconData localCafe = Icons.local_cafe;
  static const IconData flight = Icons.flight;
  static const IconData beachAccess = Icons.beach_access;
  static const IconData musicNote = Icons.music_note;
  static const IconData movie = Icons.movie;
  static const IconData sportsSoccer = Icons.sports_soccer;
  static const IconData pets = Icons.pets;
  static const IconData favorite = Icons.favorite;
  static const IconData star = Icons.star;
  static const IconData lightbulb = Icons.lightbulb;
  static const IconData palette = Icons.palette;
  static const IconData code = Icons.code;
  static const IconData computer = Icons.computer;
  static const IconData phone = Icons.phone;
  static const IconData email = Icons.email;
  static const IconData chat = Icons.chat;
  static const IconData notifications = Icons.notifications;
  static const IconData calendarToday = Icons.calendar_today;
  static const IconData event = Icons.event;
  static const IconData alarm = Icons.alarm;
  static const IconData accessTime = Icons.access_time;
  static const IconData attachMoney = Icons.attach_money;
  static const IconData accountBalance = Icons.account_balance;
  static const IconData creditCard = Icons.credit_card;
  static const IconData localHospital = Icons.local_hospital;
  static const IconData medicalServices = Icons.medical_services;
  static const IconData healing = Icons.healing;
  static const IconData directionsCar = Icons.directions_car;
  static const IconData directionsBike = Icons.directions_bike;
  static const IconData directionsBus = Icons.directions_bus;
  static const IconData train = Icons.train;
  static const IconData localShipping = Icons.local_shipping;
  static const IconData book = Icons.book;
  static const IconData menuBook = Icons.menu_book;
  static const IconData libraryBooks = Icons.library_books;
  static const IconData article = Icons.article;
  static const IconData description = Icons.description;
  static const IconData folder = Icons.folder;
  static const IconData folderOpen = Icons.folder_open;
  static const IconData insertDriveFile = Icons.insert_drive_file;
  static const IconData cloud = Icons.cloud;
  static const IconData cloudUpload = Icons.cloud_upload;
  static const IconData cloudDownload = Icons.cloud_download;

  /// All available icons for category selection
  static const List<IconData> allIcons = [
    category,
    work,
    home,
    school,
    shoppingCart,
    fitnessCenter,
    restaurant,
    localCafe,
    flight,
    beachAccess,
    musicNote,
    movie,
    sportsSoccer,
    pets,
    favorite,
    star,
    lightbulb,
    palette,
    code,
    computer,
    phone,
    email,
    chat,
    notifications,
    calendarToday,
    event,
    alarm,
    accessTime,
    attachMoney,
    accountBalance,
    creditCard,
    localHospital,
    medicalServices,
    healing,
    directionsCar,
    directionsBike,
    directionsBus,
    train,
    localShipping,
    book,
    menuBook,
    libraryBooks,
    article,
    description,
    folder,
    folderOpen,
    insertDriveFile,
    cloud,
    cloudUpload,
    cloudDownload,
  ];

  /// Get IconData by code point for tree shaking compatibility
  static IconData? getIconByCodePoint(int? codePoint) {
    if (codePoint == null) return null;

    // Find the icon with matching code point
    for (final icon in allIcons) {
      if (icon.codePoint == codePoint) {
        return icon;
      }
    }

    // Fallback to category icon if not found
    return category;
  }
}
