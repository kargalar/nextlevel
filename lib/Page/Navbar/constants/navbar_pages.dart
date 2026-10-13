import 'package:flutter/material.dart';
import 'package:next_level/Page/Home/home_page.dart';
import 'package:next_level/Page/Inbox/inbox_page.dart';
import 'package:next_level/Page/Store/store_page.dart';
import 'package:next_level/Page/Notes/notes_page.dart';
import 'package:next_level/Page/Projects/projects_page.dart';
import 'package:next_level/Page/Profile/profile_page.dart';

class NavbarPages {
  /// Get all pages in correct order
  static List<Widget> getAllPages() {
    return [
      const StorePage(),           // Index 0
      const HomePage(),            // Index 1
      const InboxPage(),           // Index 2
      const NotesPage(),           // Index 3
      const ProjectsPage(),        // Index 4
      const ProfilePage(),         // Index 5
    ];
  }
}
