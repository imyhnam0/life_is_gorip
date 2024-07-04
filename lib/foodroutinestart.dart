import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class FoodroutinestartPage extends StatefulWidget {
  @override
  _FoodroutinestartPageState createState() => _FoodroutinestartPageState();
}

class _FoodroutinestartPageState extends State<FoodroutinestartPage> {
  String? title;
  List<Map<String, dynamic>> meals = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? loadedTitle = prefs.getString('currentRoutineTitle');
    String? loadedMeals = prefs.getString('currentRoutineMeals');

    if (loadedTitle != null && loadedMeals != null) {
      setState(() {
        title = loadedTitle;
        meals = List<Map<String, dynamic>>.from(json.decode(loadedMeals));
      });
    }
  }

  Future<void> _clearData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('currentRoutineTitle');
    await prefs.remove('currentRoutineMeals');
  }

  @override
  Widget build(BuildContext context) {
    if (title == null || meals.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('none'),
        ),
        body: Center(
          child: Text('아직 실행중인 식단이 없습니다.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title!),
      ),
      body: ListView.builder(
        itemCount: meals.length,
        itemBuilder: (context, index) {
          return ExpansionTile(
            title: Text(meals[index]['name']),
            children: meals[index]['subMeals'].map<Widget>((subMeal) {
              return CheckboxListTile(
                title: Text(subMeal),
                value: meals[index]['checkedMeals'] != null && meals[index]['checkedMeals'].contains(subMeal),
                onChanged: (bool? value) {
                  setState(() {
                    if (meals[index]['checkedMeals'] == null) {
                      meals[index]['checkedMeals'] = [];
                    }
                    if (value == true) {
                      meals[index]['checkedMeals'].add(subMeal);
                    } else {
                      meals[index]['checkedMeals'].remove(subMeal);
                    }
                  });
                },
              );
            }).toList(),
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            onPressed: () async {
              await _clearData();
              Navigator.pop(context);
            },
            child: Text('완료'),
          ),
        ),
      ),
    );
  }
}
