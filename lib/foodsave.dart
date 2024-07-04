import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'foodcreate.dart';
import 'foodroutinestart.dart';


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
      MaterialPageRoute(builder: (context) => AddMealPage()),
    );
    if (result != null && result is String) {
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
        'subMeals': [],
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
      setModalState(() {
        savedRoutines[routineIndex]['meals'][mealIndex]['name'] = result;
      });
      _saveData();
    }
  }

  void _showMeals(
      BuildContext context, int routineIndex, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Stack(
              children: [
                ListView(
                  children: data['meals'].asMap().entries.map<Widget>((entry) {
                    int mealIndex = entry.key;
                    Map<String, dynamic> meal = entry.value;
                    return ExpansionTile(
                      title: Text(meal['name']),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {
                              _editMealName(context, routineIndex, mealIndex,
                                  setModalState);
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.add),
                            onPressed: () {
                              _navigateAndAddSubMeal(context, routineIndex,
                                  mealIndex, setModalState);
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.remove),
                            onPressed: () {
                              _removeMeal(
                                  routineIndex, mealIndex, setModalState);
                            },
                          ),
                        ],
                      ),
                      children: meal['subMeals']
                          .asMap()
                          .entries
                          .map<Widget>((subEntry) {
                        int subMealIndex = subEntry.key;
                        String subMeal = subEntry.value;
                        return ListTile(
                          title: Text(subMeal),
                          trailing: IconButton(
                            icon: Icon(Icons.remove),
                            onPressed: () {
                              _removeSubMeal(routineIndex, mealIndex,
                                  subMealIndex, setModalState);
                            },
                          ),
                        );
                      }).toList(),
                    );
                  }).toList(),
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
                        child: Text('시작'),
                      ),
                      SizedBox(width: 16), // 버튼 사이의 간격
                      FloatingActionButton(
                        onPressed: () {
                          _addMeal(routineIndex, setModalState);
                        },
                        child: Icon(Icons.add),
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
          title: Text('식단 이름 수정'),
          content: TextField(
            controller: _editController,
            decoration: InputDecoration(
              labelText: '식단 이름 입력',
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
        savedRoutines[index]['title'] = result;
        _saveData();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('저장된 식단'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
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
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    _editRoutineTitle(context, index);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.remove),
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

void main() {
  runApp(MaterialApp(
    home: FoodSavePage(),
  ));
}
