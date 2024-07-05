import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class FoodroutinestartPage extends StatefulWidget {
  @override
  _FoodroutinestartPageState createState() => _FoodroutinestartPageState();
}

class _FoodroutinestartPageState extends State<FoodroutinestartPage> {
  String? title;
  List<Map<String, dynamic>> meals = [];

  double totalCalories = 0;
  double totalCarbs = 0;
  double totalProtein = 0;
  double totalFat = 0;

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
        _calculateTotalRoutineNutrients();
      });
    }
  }

  Future<void> _clearData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('currentRoutineTitle');
    await prefs.remove('currentRoutineMeals');
  }

  void _calculateTotalRoutineNutrients() {
    totalCalories = 0;
    totalCarbs = 0;
    totalProtein = 0;
    totalFat = 0;

    for (var meal in meals) {
      for (var subMeal in meal['subMeals']) {
        totalCalories += subMeal['calories'] as double;
        totalCarbs += subMeal['carbs'] as double;
        totalProtein += subMeal['protein'] as double;
        totalFat += subMeal['fat'] as double;
      }
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

  List<PieChartSectionData> showingSections() {
    final total = totalCarbs + totalProtein + totalFat;
    if (total == 0) return [];

    return [
      PieChartSectionData(
        color: Colors.blue,
        value: (totalCarbs / total) * 100,
        title: '${(totalCarbs / total * 100).toStringAsFixed(1)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        color: Colors.red,
        value: (totalProtein / total) * 100,
        title: '${(totalProtein / total * 100).toStringAsFixed(1)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        color: Colors.green,
        value: (totalFat / total) * 100,
        title: '${(totalFat / total * 100).toStringAsFixed(1)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ];
  }
   Future<void> _saveToFirebase() async {
    CollectionReference todayFood = FirebaseFirestore.instance
        .collection('Calender')
        .doc('food')
        .collection('todayfood');
        String formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    await todayFood.add({
      'date': formattedDate,
      'totalCalories': totalCalories,
      'totalCarbs': totalCarbs,
      'totalProtein': totalProtein,
      'totalFat': totalFat,
    });
  }

  @override
  Widget build(BuildContext context) {
    if (title == null || meals.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('none'),
        ),
        body: const Center(
          child: Text('아직 실행중인 식단이 없습니다.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title!),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              '루틴 총 칼로리: $totalCalories 총 탄: $totalCarbs 총 단: $totalProtein 총 지: $totalFat',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                Text(
                  '탄수화물 : ',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Container(
                  width: 20,
                  height: 20,
                  color: Colors.blue,
                ),
                SizedBox(width: 10), // 간격 추가
                Text(
                  '단백질 : ',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Container(
                  width: 20,
                  height: 20,
                  color: Colors.red,
                ),
                SizedBox(width: 10), // 간격 추가
                Text(
                  '지방 : ',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Container(
                  width: 20,
                  height: 20,
                  color: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: PieChart(
                PieChartData(
                  sections: showingSections(),
                  centerSpaceRadius: 40,
                  sectionsSpace: 0,
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: meals.length,
                itemBuilder: (context, index) {
                  final totalNutrients = _calculateTotalNutrients(
                      meals[index]['subMeals'].cast<Map<String, dynamic>>());
                  return ExpansionTile(
                    title: Text(
                      '${meals[index]['name']} - 총 칼로리: ${totalNutrients['calories']} 총 탄: ${totalNutrients['carbs']} 총 단: ${totalNutrients['protein']} 총 지: ${totalNutrients['fat']}',
                    ),
                    children: meals[index]['subMeals'].map<Widget>((subMeal) {
                      return CheckboxListTile(
                        title:
                            Text('${subMeal['name']} (${subMeal['grams']}g)'),
                        value: meals[index]['checkedMeals'] != null &&
                            meals[index]['checkedMeals']
                                .contains(subMeal['name']),
                        onChanged: (bool? value) {
                          setState(() {
                            if (meals[index]['checkedMeals'] == null) {
                              meals[index]['checkedMeals'] = [];
                            }
                            if (value == true) {
                              meals[index]['checkedMeals'].add(subMeal['name']);
                            } else {
                              meals[index]['checkedMeals']
                                  .remove(subMeal['name']);
                            }
                          });
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            onPressed: () async {
              _saveToFirebase();
              await _clearData();
              Navigator.pop(context);
            },
            child: const Text('완료'),
          ),
        ),
      ),
    );
  }
}
