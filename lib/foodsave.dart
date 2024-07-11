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
        String currentName = savedRoutines[routineIndex]['meals'][i]['name'];
        if (currentName.endsWith('번째 끼니')) {
          savedRoutines[routineIndex]['meals'][i]['name'] = '${i + 1}번째 끼니';
        }
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
          backgroundColor: Colors.blueGrey.shade900,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: Text(
            '끼니 이름 수정',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _editController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: '끼니 이름 입력',
                  labelStyle: TextStyle(color: Colors.white),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 10),
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
                      textStyle: TextStyle(
                        fontSize: 10, // 글자 크기 설정
                      ),
                      minimumSize: Size(10, 40),
                      padding: EdgeInsets.symmetric(horizontal: 8), // 버튼의 최소 크기 설정
                    ),
                    onPressed: () {
                      Navigator.pop(context, _editController.text);
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
                      textStyle: TextStyle(
                        fontSize: 10, // 글자 크기 설정
                      ),
                      minimumSize: Size(10, 40),
                      padding: EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _navigateAndAddSubMeal(
                          context, routineIndex, mealIndex, setModalState);
                    },
                    child: const Text('음식 추가'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      textStyle: TextStyle(
                        fontSize: 10, // 글자 크기 설정
                      ),
                      minimumSize: Size(10, 40),
                      padding: EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _removeMeal(routineIndex, mealIndex, setModalState);
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

    if (result != null && result is String) {
      setModalState(() {
        savedRoutines[routineIndex]['meals'][mealIndex]['name'] = result;
      });
      _saveData();
    }
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

  Map<String, double> _calculateTotalRoutineNutrients(
      Map<String, dynamic> routine) {
    double totalCalories = 0;
    double totalCarbs = 0;
    double totalProtein = 0;
    double totalFat = 0;

    for (var meal in routine['meals']) {
      final nutrients = _calculateTotalNutrients(
          meal['subMeals'].cast<Map<String, dynamic>>());
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
            return Container(
              color: Colors.blueGrey.shade900,
              child: Stack(
                children: [
                  Column(
                    children: [
                      Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '루틴 총 칼로리: ${totalRoutineNutrients['calories']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    '총 탄: ${totalRoutineNutrients['carbs']}  ',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontSize: 16),
                                  ),
                                  Text(
                                    '총 단: ${totalRoutineNutrients['protein']}  ',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontSize: 16),
                                  ),
                                  Text(
                                    '총 지: ${totalRoutineNutrients['fat']}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontSize: 16),
                                  ),
                                ],
                              ),
                            ],
                          )),
                      Expanded(
                        child: ListView.builder(
                          itemCount: data['meals'].length,
                          itemBuilder: (context, mealIndex) {
                            Map<String, dynamic> meal =
                                data['meals'][mealIndex];
                            final totalNutrients = _calculateTotalNutrients(
                                meal['subMeals'].cast<Map<String, dynamic>>());
                            return ExpansionTile(
                              backgroundColor: Colors.blueGrey.shade800,
                              title: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    meal['name'],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '총 칼로리: ${totalNutrients['calories']}',
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Text(
                                              '총 탄수화물: ${totalNutrients['carbs']}  ',
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12)),
                                          Text(
                                              '총 단백질: ${totalNutrients['protein']}  ',
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12)),
                                          Text(
                                            '총 지방: ${totalNutrients['fat']}',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12),
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
                                    icon: const Icon(Icons.more_horiz,
                                        color: Colors.white),
                                    onPressed: () {
                                      _editMealName(context, routineIndex,
                                          mealIndex, setModalState);
                                    },
                                  ),
                                  Icon(
                                    meal['isExpanded']
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                              onExpansionChanged: (isExpanded) {
                                setModalState(() {
                                  meal['isExpanded'] = isExpanded;
                                });
                              },
                              children: List.generate(meal['subMeals'].length,
                                  (subMealIndex) {
                                Map<String, dynamic> subMeal =
                                    meal['subMeals'][subMealIndex];
                                return ListTile(
                                  title: Text(
                                    '${subMeal['name']} (${subMeal['grams']}g)',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  subtitle: Text(
                                    'Calories: ${subMeal['calories']} Carbs: ${subMeal['carbs']} Protein: ${subMeal['protein']} Fat: ${subMeal['fat']}',
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 12),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.remove,
                                        color: Colors.white),
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
                    ],
                  ),
                  Positioned(
                    bottom: 16,
                    left: 120,
                    right: 0,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FloatingActionButton.extended(
                          onPressed: () async {
                            SharedPreferences prefs =
                                await SharedPreferences.getInstance();
                            await prefs.setString(
                                'currentRoutineTitle', data['title']);
                            await prefs.setString('currentRoutineMeals',
                                json.encode(data['meals']));

                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                          label: const Text(
                            '시작',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Oswald',
                            ),
                          ),
                          icon: const Icon(Icons.play_arrow),
                          backgroundColor: Colors.blueGrey.shade700,
                          foregroundColor: Colors.white,
                        ),
                        const SizedBox(width: 16), // 버튼 사이의 간격
                        FloatingActionButton.extended(
                          onPressed: () {
                            _addMeal(routineIndex, setModalState);
                          },
                          label: const Text(
                            '추가',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Oswald',
                            ),
                          ),
                          icon: const Icon(Icons.add),
                          backgroundColor: Colors.blueGrey.shade700,
                          foregroundColor: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
          title: const Text('식단 이름 수정', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.blueGrey.shade900,
          content: TextField(
            controller: _editController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: '식단 이름 입력',
              labelStyle: TextStyle(color: Colors.white),
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Color.fromARGB(255, 64, 72, 78), // 원하는 배경색으로 변경하세요.
              ),
              onPressed: () {
                Navigator.pop(context, _editController.text);
              },
              child: const Text('수정', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Color.fromARGB(255, 64, 72, 78), // 원하는 배경색으로 변경하세요.
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('취소', style: TextStyle(color: Colors.white)),
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
        title: const Text(
          '식단 모음 ',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Oswald',
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueGrey.shade900,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
            size: 28,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
          tooltip: '뒤로 가기',
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add,
              color: Colors.white,
              size: 28,
            ),
            onPressed: _addRoutine,
            tooltip: '추가',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.blueGrey.shade900,
        ),
        child: ListView.builder(
          itemCount: savedRoutines.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                height: 80, // 컨테이너의 높이를 100으로 설정
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 46, 62, 68),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: Colors.white),
                ),
                child: ListTile(
                  title: Text(savedRoutines[index]['title'],
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.start),
                  trailing: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center, // 아이콘을 상하 기준으로 가운데 정렬
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: () {
                          _editRoutineTitle(context, index);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.white),
                        onPressed: () {
                          _removeRoutine(index);
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    _showMeals(context, index, savedRoutines[index]);
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
