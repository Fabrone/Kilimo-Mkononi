import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:kilimomkononi/screens/farming_tips_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kilimomkononi/screens/user_profile.dart';
import 'package:kilimomkononi/screens/weather_screen.dart';
import 'package:kilimomkononi/screens/market_price_prediction_widget.dart';
import 'package:kilimomkononi/authentication/login.dart'; 
import 'dart:convert';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _userData;

  final List<String> _carouselImages = [
    'assets/weather_forecast.jpg',
    'assets/field_data_collection.jpg',
    'assets/pest_management.jpg',
    'assets/farm_management.jpg',
    'assets/manuals.jpg',
    'assets/farming_tips.png',
    'assets/soil.png',
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .get();
      if (userSnapshot.exists) {
        setState(() {
          _userData = userSnapshot.data() as Map<String, dynamic>;
        });
      }
    }
  }

  // Logout functionality
  Future<void> _handleLogout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pop(context); // Close drawer
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: $e')),
        );
      }
    }
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(MediaQuery.of(context).size.height * 0.08),
        child: AppBar(
          title: const Text(
            'KilimoMkononi',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold, 
            ),
          ),
          backgroundColor: const Color.fromARGB(255, 3, 39, 4),
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(
                Icons.menu,
                color: Colors.white, 
                size: 40, // Double the default size (24 -> 48)
              ),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.notifications,
                color: Colors.white,
                size: 40, // Double the default size (24 -> 48)
              ),
              onPressed: () {
                // Notification functionality
              },
            ),
            IconButton(
              icon: const Icon(
                Icons.search,
                color: Colors.white,
                size: 40, // Double the default size (24 -> 48)
              ),
              onPressed: () {
                // Search functionality
              },
            ),
          ],
        ),
      ),
      drawer: _buildDrawer(),
      body: Container(
        color: Colors.grey[200],
        child: Column(
          children: [
            _buildCarousel(),
            _buildClickableSections(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildCarousel() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.4,
      child: CarouselSlider(
        options: CarouselOptions(
          height: MediaQuery.of(context).size.height * 0.4,
          autoPlay: true,
          enlargeCenterPage: true,
          aspectRatio: 16 / 9,
          autoPlayCurve: Curves.fastOutSlowIn,
          enableInfiniteScroll: true,
          autoPlayAnimationDuration: const Duration(milliseconds: 800),
          viewportFraction: 0.8,
        ),
        items: _carouselImages.map((image) {
          int index = _carouselImages.indexOf(image);
          List<String> labels = [
            'Get Weather Forecasts',
            'Record Field Data Collected',
            'Enhance Pest Management',
            'Effectively Manage Farming funds ',
            'Explore Farming Information',
            'Get Better Farming Tips',
            'Understand Soil Information',
          ];
          return Stack(
            children: [
              Container(
                margin: const EdgeInsets.all(5.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  image: DecorationImage(
                    image: AssetImage(image),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                left: 10,
                child: Container(
                  color: Colors.black54,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Text(
                    labels[index],
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildClickableSections() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        children: [
          _buildClickableCard('Farming Tips', Icons.lightbulb, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => FarmingTipsWidget()),
            );
          }),
          _buildClickableCard('Market Prices', Icons.shopping_cart, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MarketPricePredictionWidget()),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildClickableCard(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(76, 175, 80, 0.1),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(128, 128, 128, 0.5),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: const Color.fromARGB(255, 3, 39, 4),),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.book),
          label: 'Manuals',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.group),
          label: 'Community',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.article),
          label: 'Blog',
        ),
      ],
      currentIndex: _selectedIndex,
      selectedItemColor: const Color.fromARGB(255, 3, 39, 4),
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserProfileScreen()),
              );
            },
            child: UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 3, 39, 4),
              ),
              accountName: Text(
                _userData?['fullName'] ?? 'Loading...',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold,),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: _userData?['profileImage'] != null
                    ? ClipOval(
                        child: Image.memory(
                          base64Decode(_userData!['profileImage']),
                          fit: BoxFit.cover,
                          width: 60,
                          height: 60,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.person, size: 40, color: Color.fromARGB(255, 3, 39, 4)),
                        ),
                      )
                    : const Icon(Icons.person, size: 40, color: Color.fromARGB(255, 3, 39, 4)),
              ),
              accountEmail: null,
            ),
          ),
          _buildDrawerItem(Icons.home, 'Home', () {
            Navigator.pop(context);
            setState(() {});
          }),
          _buildDrawerItem(Icons.cloud, 'Weather Forecast', () { 
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const WeatherScreen()),
            );
          }),
          _buildDrawerItem(Icons.input, 'Field Data Input', () {
            // Navigate to Field Data Input
          }),
          _buildDrawerItem(Icons.pest_control, 'Pest Management', () {
           /* Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MaizeScanScreen()),
            );*/
          }),
          _buildDrawerItem(Icons.supervisor_account, 'Farm Management', () {
            // Navigate to Farm Management
          }),
          _buildDrawerItem(Icons.book, 'Manuals', () {
            // Navigate to Crop Manuals
          }),
          _buildDrawerItem(Icons.settings, 'Settings', () {
            // Navigate to Settings
          }),
          _buildDrawerItem(Icons.logout, 'Logout', _handleLogout), 
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }
}