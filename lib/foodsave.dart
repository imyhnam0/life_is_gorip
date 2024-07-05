import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'foodcreate.dart';
import 'foodroutinestart.dart';
import 'addmeal.dart';

class FoodSavePage extends StatefulWidget {
  @override
  _FoodSavePageState createState() => _FoodSavePageState();
}

class _FoodSavePageState extends State<FoodSavePage> {
  List<Map<String, dynamic>> savedRoutines = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? savedData = prefs.getStringList('savedMeals');
    if (savedData != null) {
      setState(() {
        savedRoutines = savedData
            .map((data) => Map<String, dynamic>.from(json.decode(data)))
            .toList();
      });
    }
  }

  Future<void> _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> savedData =
        savedRoutines.map((data) => json.encode(data)).toList();
    await prefs.setStringList('savedMeals', savedData);
  }

  Future<void> _navigateAndAddSubMeal(BuildContext context, int routineIndex,
      int mealIndex, StateSetter setModalState) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddMealPage()),
    );
    if (result != null && result is Map<String, dynamic>) {
      setModalState(() {
        savedRoutines[routineIndex]['meals'][mealIndex]['subMeals'].add(result);
      });
      _saveData();
    }
  }

  void _addMeal(int routineIndex, StateSetter setModalState) {
    setModalState(() {
      savedRoutines[routineIndex]['meals'].add({
        'name': '${savedRoutines[routineIndex]['meals'].length + 1}번째 끼니',
        'subMeals': <Map<String, dynamic>>[],
        'isExpanded': false,
      });
    });
    _saveData();
  }

  void _removeMeal(int routineIndex, int mealIndex, StateSetter setModalState) {
    setModalState(() {
      savedRoutines[routineIndex]['meals'].removeAt(mealIndex);
      // 끼니 이름 재정렬
      for (int i = 0; i < savedRoutines[routineIndex]['meals'].length; i++) {
        savedRoutines[routineIndex]['meals'][i]['name'] = '${i + 1}번째 끼니';
      }
    });
    _saveData();
  }

  void _removeSubMeal(int routineIndex, int mealIndex, int subMealIndex,
      StateSetter setModalState) {
    setModalState(() {
      savedRoutines[routineIndex]['meals'][mealIndex]['subMeals']
          .removeAt(subMealIndex);
    });
    _saveData();
  }

  Future<void> _editMealName(BuildContext context, int routineIndex,
      int mealIndex, StateSetter setModalState) async {
    TextEditingController _editController = TextEditingController();
    _editController.text =
        savedRoutines[routineIndex]['meals'][mealIndex]['name'];
    final result = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('끼니 이름 수정'),
          content: TextField(
            controller: _editController,
            decoration: const InputDecoration(
              labelText: '끼니 이름 입력',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, _editController.text);
              },
              child: const Text('저장'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('취소'),
            ),
          ],
        );
      },
    );

    if (result != null && result is String) {
      setModalState(() {
        savedRoutines[routineIndex]['meals'][mealIndex]['name'] = result;
      });
      _saveData();
    }
  }

  Map<String, double> _calculateTotalNutrients(List<Map<String, dynamic>> subMeals) {
    double totalCalories = 0;
    double totalCarbs = 0;
    double totalProtein = 0;
    double totalFat = 0;

    for (var meal in subMeals) {
      totalCalories += meal['calories'] as double;
      totalCarbs += meal['carbs'] as double;
      totalProtein += meal['protein'] as double;
      totalFat += meal['fat'] as double;
    }

    return {
      'calories': totalCalories,
      'carbs': totalCarbs,
      'protein': totalProtein,
      'fat': totalFat,
    };
  }

  Map<String, double> _calculateTotalRoutineNutrients(Map<String, dynamic> routine) {
    double totalCalories = 0;
    double totalCarbs = 0;
    double totalProtein = 0;
    double totalFat = 0;

    for (var meal in routine['meals']) {
      final nutrients = _calculateTotalNutrients(meal['subMeals'].cast<Map<String, dynamic>>());
      totalCalories += nutrients['calories']!;
      totalCarbs += nutrients['carbs']!;
      totalProtein += nutrients['protein']!;
      totalFat += nutrients['fat']!;
    }

    return {
      'calories': totalCalories,
      'carbs': totalCarbs,
      'protein': totalProtein,
      'fat': totalFat,
    };
  }

  void _showMeals(
      BuildContext context, int routineIndex, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final totalRoutineNutrients = _calculateTotalRoutineNutrients(data);
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    '루틴 총 칼로리: ${totalRoutineNutrients['calories']} 총 탄: ${totalRoutineNutrients['carbs']} 총 단: ${totalRoutineNutrients['protein']} 총 지: ${totalRoutineNutrients['fat']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: data['meals'].length,
                    itemBuilder: (context, mealIndex) {
                      Map<String, dynamic> meal = data['meals'][mealIndex];
                      final totalNutrients = _calculateTotalNutrients(meal['subMeals'].cast<Map<String, dynamic>>());
                      return ExpansionTile(
                        title: Text(
                          '${meal['name']} - 총 칼로리: ${totalNutrients['calories']} 총 탄: ${totalNutrients['carbs']} 총 단: ${totalNutrients['protein']} 총 지: ${totalNutrients['fat']}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                _editMealName(context, routineIndex, mealIndex,
                                    setModalState);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                _navigateAndAddSubMeal(context, routineIndex,
                                    mealIndex, setModalState);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                _removeMeal(
                                    routineIndex, mealIndex, setModalState);
                              },
                            ),
                          ],
                        ),
                        children: List.generate(meal['subMeals'].length, (subMealIndex) {
                          Map<String, dynamic> subMeal = meal['subMeals'][subMealIndex];
                          return ListTile(
                            title: Text('${subMeal['name']} (${subMeal['grams']}g)'),
                            subtitle: Text(
                              'Calories: ${subMeal['calories']} Carbs: ${subMeal['carbs']} Protein: ${subMeal['protein']} Fat: ${subMeal['fat']}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                _removeSubMeal(routineIndex, mealIndex,
                                    subMealIndex, setModalState);
                              },
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ),
                Positioned(
                  bottom: 16,
                  right: 150,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FloatingActionButton(
                        onPressed: () async {
                           SharedPreferences prefs = await SharedPreferences.getInstance();
                          await prefs.setString('currentRoutineTitle', data['title']);
                          await prefs.setString('currentRoutineMeals', json.encode(data['meals']));
                          
                          
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        child: const Text('시작'),
                      ),
                      const SizedBox(width: 16), // 버튼 사이의 간격
                      FloatingActionButton(
                        onPressed: () {
                          _addMeal(routineIndex, setModalState);
                        },
                        child: const Icon(Icons.add),
                      ),
                    ],
                  ),
                )
              ],
            );
          },
        );
      },
    ).whenComplete(() {
      setState(() {});
    });
  }

  void _addRoutine() {
    setState(() {
      savedRoutines.add({
        'title': '새로운 식단',
        'meals': [],
      });
      _saveData();
    });
  }

  void _removeRoutine(int index) {
    setState(() {
      savedRoutines.removeAt(index);
      _saveData();
    });
  }

  Future<void> _editRoutineTitle(BuildContext context, int index) async {
    TextEditingController _editController = TextEditingController();
    _editController.text = savedRoutines[index]['title'];
    final result = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('식단 이름 수정'),
          content: TextField(
            controller: _editController,
            decoration: const InputDecoration(
              labelText: '식단 이름 입력',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, _editController.text);
              },
              child: const Text('저장'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('취소'),
            ),
          ],
        );
      },
    );

    if (result != null && result is String) {
      setState(() {
        savedRoutines[index]['title'] = result;
        _saveData();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('저장된 식단'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addRoutine,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: savedRoutines.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(savedRoutines[index]['title']),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    _editRoutineTitle(context, index);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    _removeRoutine(index);
                  },
                ),
              ],
            ),
            onTap: () {
              _showMeals(context, index, savedRoutines[index]);
            },
          );
        },
      ),
    );
  }
}
