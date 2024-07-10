import 'package:flutter/material.dart';
import 'foodcreate.dart';
import 'foodsave.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'addmeal.dart';


class FoodRoutineCreatePage extends StatefulWidget {
  const FoodRoutineCreatePage({super.key});

  @override
  State<FoodRoutineCreatePage> createState() => _FoodRoutineCreatePageState();
}

class _FoodRoutineCreatePageState extends State<FoodRoutineCreatePage> {
  List<Map<String, dynamic>> meals = [];
  final TextEditingController _titleController = TextEditingController();

  Future<void> _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('meals', json.encode(meals));
  }

  Future<void> _navigateAndAddSubMeal(
      BuildContext context, int mealIndex) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => const AddMealPage()), // AddMealPage로 이동
    );
    if (result != null && result is Map<String, dynamic>) {
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
        'subMeals': <Map<String, dynamic>>[],
        'isExpanded': false,
      });
      _saveData();
    });
  }

 void _removeMeal(int index) {
  setState(() {
    meals.removeAt(index);
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
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      backgroundColor: Colors.blueGrey.shade900,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _editController,
                style: TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: '끼니 이름 입력',
                  labelStyle: TextStyle(color: Colors.white),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.cyan),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        meals[mealIndex]['name'] = _editController.text;
                        _saveData();
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('이름 수정'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _navigateAndAddSubMeal(context, mealIndex);
                    },
                    child: const Text('음식 추가', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold,
                        fontFamily: 'Oswald',)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onPressed: () {
                      _removeMeal(mealIndex);
                      Navigator.pop(context);
                    },
                    child: const Text('끼니 삭제'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
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

  Map<String, double> _calculateTotalNutrients(
      List<Map<String, dynamic>> subMeals) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '나만의 식단 생성',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Oswald',
          ),
        ),
        backgroundColor: Colors.blueGrey.shade900,
         leading: IconButton(
    icon: Icon(
      Icons.arrow_back,
      color: Colors.white,
      size: 28, // 아이콘 크기를 키움
    ),
    onPressed: () {
      Navigator.pop(context);
    },
    tooltip: '뒤로 가기', // 아이콘에 툴팁 추가
  ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FoodCreatePage()),
              );
            },
            child: const Text('음식 추가', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              minimumSize: Size(60, 40),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.blueGrey.shade900,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              style: TextStyle(color: Colors.white),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                labelText: '제목 입력',
                labelStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white70),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white70),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _addMeal,
                  child: const Text('끼니 추가',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Oswald',
                      )),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey.shade700,
                  ),
                ),
                ElevatedButton(
                  onPressed: _saveAndNavigateToSavePage,
                  child: const Text('루틴 저장',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Oswald',
                      )),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: meals.length,
                itemBuilder: (context, index) {
                  final totalNutrients =
                      _calculateTotalNutrients(meals[index]['subMeals']);
                  return ExpansionTile(
                    backgroundColor: Colors.blueGrey.shade800,
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${meals[index]['name']}',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '총 칼로리: ${totalNutrients['calories']}',
                              style: TextStyle(color: Colors.white),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text('총 탄수화물: ${totalNutrients['carbs']}  ',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 10)),
                                Text('총 단백질: ${totalNutrients['protein']}  ',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 10)),
                                Text(
                                  '총 지방: ${totalNutrients['fat']}',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 10),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon:
                              const Icon(Icons.more_horiz, color: Colors.white),
                          onPressed: () {
                            _editMealName(context, index);
                          },
                        ),
                        Icon(
                          meals[index]['isExpanded']
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: Colors.white,
                        ),
                      ],
                    ),
                    onExpansionChanged: (isExpanded) {
                      _toggleExpansion(index, isExpanded);
                    },
                    children: meals[index]['subMeals']
                        .asMap()
                        .entries
                        .map<Widget>((entry) {
                      int subMealIndex = entry.key;
                      Map<String, dynamic> subMeal = entry.value;
                      return ListTile(
                        title: Text(
                          '${subMeal['name']} (${subMeal['grams']}g)',
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          'Calories: ${subMeal['calories']} Carbs: ${subMeal['carbs']} Protein: ${subMeal['protein']} Fat: ${subMeal['fat']}',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove, color: Colors.white),
                          onPressed: () {
                            _removeSubMeal(index, subMealIndex);
                          },
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  bottom: 30.0), // 아래쪽 여백을 주어 텍스트를 위로 올립니다.
              child: Text(
                "*만약 검색에서 음식이 없으면 직접 음식 영양 정보를 추가해주세요",
                style: TextStyle(fontSize: 10, color: Colors.white70),
              ),
            )
          ],
        ),
      ),
    );
  }
}
