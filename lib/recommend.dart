import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class RecommendPage extends StatefulWidget {
  const RecommendPage({super.key});

  @override
  State<RecommendPage> createState() => _RecommendPageState();
}

class _RecommendPageState extends State<RecommendPage> {
  Map<String, int> routineCounts = {};

  @override
  void initState() {
    super.initState();
    _loadRoutineCounts();
  }

  Future<void> _loadRoutineCounts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? routineCountsString = prefs.getString('routineCounts');

    setState(() {
      routineCounts = routineCountsString != null
          ? Map<String, int>.from(jsonDecode(routineCountsString))
          : {};
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recommend Page'),
      ),
      body: ListView.builder(
        itemCount: routineCounts.length,
        itemBuilder: (context, index) {
          String routineName = routineCounts.keys.elementAt(index);
          int count = routineCounts[routineName]!;
          return ListTile(
            title: Text('$routineName: $count회'),
          );
        },
      ),
    );
  }
}
