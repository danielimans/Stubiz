import 'package:flutter/material.dart';
import 'screens/marketplace/marketplace_home.dart';
import 'screens/exchange/exchange_home.dart';
import 'screens/promotion/promotion_home.dart';
import 'screens/chat/chat_list.dart';
import 'screens/profile/profile_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _index = 0;

  final screens = const [
    MarketplaceHome(),
    ExchangeHome(),
    PromotionHome(),
    ChatList(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Market'),
          BottomNavigationBarItem(icon: Icon(Icons.swap_horiz), label: 'Exchange'),
          BottomNavigationBarItem(icon: Icon(Icons.campaign), label: 'Promote'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
