import 'package:flutter/material.dart';
import 'package:google_auth/components/navigation_menu.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        centerTitle: true,
      ),
      drawer: const SideNavigationDrawer(),
      body: const Center(
        child: Text('This is Home Page'),
      ),
    );
  }
}