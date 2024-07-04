import 'package:flutter/material.dart';
import 'foodcreate.dart';
import 'foodsave.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class FoodRoutineCreatePage extends StatefulWidget {
  const FoodRoutineCreatePage({super.key});

  @override
  State<FoodRoutineCreatePage> createState() => _FoodRoutineCreatePageState();
}

class _FoodRoutineCreatePageState extends State<FoodRoutineCreatePage> {
  List<Map<String, dynamic>> meals = [];
  TextEditingController _titleController = TextEditingController();

  Future<void> _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('meals', json.encode(meals));
  }

  Future<void> _navigateAndAddSubMeal(BuildContext context, int mealIndex) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddMealPage()),
    );
    if (result != null && result is String) {
      setState(() {
        meals[mealIndex]['subMeals'].add(result);
        _saveData();
      });
    }
  }

  void _addMeal() {
    setState(() {
      meals.add({
        'name': '${meals.length + 1}번째 끼니',
        'subMeals': [],
        'isExpanded': false,
      });
      _saveData();
    });
  }

  void _removeMeal(int index) {
    setState(() {
      meals.removeAt(index);
      // 끼니 이름 재정렬
      for (int i = 0; i < meals.length; i++) {
        meals[i]['name'] = '${i + 1}번째 끼니';
      }
      _saveData();
    });
  }

  void _removeSubMeal(int mealIndex, int subMealIndex) {
    setState(() {
      meals[mealIndex]['subMeals'].removeAt(subMealIndex);
      _saveData();
    });
  }

  Future<void> _editMealName(BuildContext context, int mealIndex) async {
    TextEditingController _editController = TextEditingController();
    _editController.text = meals[mealIndex]['name'];
    final result = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('끼니 이름 수정'),
          content: TextField(
            controller: _editController,
            decoration: InputDecoration(
              labelText: '끼니 이름 입력',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, _editController.text);
              },
              child: Text('저장'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('취소'),
            ),
          ],
        );
      },
    );

    if (result != null && result is String) {
      setState(() {
        meals[mealIndex]['name'] = result;
        _saveData();
      });
    }
  }

  

  void _toggleExpansion(int index, bool isExpanded) {
    setState(() {
      meals[index]['isExpanded'] = isExpanded;
    });
  }

  void _saveTitleAndMeals() {
    String title = _titleController.text;
    if (title.isNotEmpty) {
      Map<String, dynamic> data = {
        'title': title,
        'meals': meals,
      };
      _saveToSharedPreferences(data);
      setState(() {
        _titleController.clear();
        meals = [];
      });
    }
  }

  Future<void> _saveToSharedPreferences(Map<String, dynamic> data) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? savedData = prefs.getStringList('savedMeals');
    if (savedData == null) {
      savedData = [];
    }
    savedData.add(json.encode(data));
    await prefs.setStringList('savedMeals', savedData);
  }

  void _saveAndNavigateToSavePage() {
    _saveTitleAndMeals();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('식단 루틴 생성'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FoodCreatePage()),
              );
            },
            child: Text('식단 추가'),
          ),
          ElevatedButton(
            onPressed: _saveAndNavigateToSavePage,
            child: Text('저장'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: '제목 입력',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addMeal,
              child: Text('끼니 추가'),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: meals.length,
                itemBuilder: (context, index) {
                  return ExpansionTile(
                    title: Text(meals[index]['name']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () {
                            _editMealName(context, index);
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () {
                            _navigateAndAddSubMeal(context, index);
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.remove),
                          onPressed: () {
                            _removeMeal(index);
                          },
                        ),
                        Icon(meals[index]['isExpanded']
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down),
                      ],
                    ),
                    onExpansionChanged: (isExpanded) {
                      _toggleExpansion(index, isExpanded);
                    },
                    children: meals[index]['subMeals'].asMap().entries.map<Widget>((entry) {
                      int subMealIndex = entry.key;
                      String subMeal = entry.value;
                      return ListTile(
                        title: Text(subMeal),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            
                            IconButton(
                              icon: Icon(Icons.remove),
                              onPressed: () {
                                _removeSubMeal(index, subMealIndex);
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _saveTitleAndMeals,
              child: Text('저장'),
            ),
          ],
        ),
      ),
    );
  }
}

class AddMealPage extends StatelessWidget {
  final TextEditingController _mealController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('끼니 추가'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _mealController,
              decoration: InputDecoration(
                labelText: '끼니 이름 입력',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, _mealController.text);
              },
              child: Text('추가'),
            ),
          ],
        ),
      ),
    );
  }
}
