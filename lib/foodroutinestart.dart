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
          title: const Text('None'),
          backgroundColor: Colors.blueGrey.shade900,
        ),
        body: const Center(
          child: Text('아직 실행중인 식단이 없습니다.', style: TextStyle(color: Colors.white)),
        ),
        backgroundColor: Colors.blueGrey.shade900,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title!, style: const TextStyle(color: Colors.white)),
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
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _buildLegendItem('탄수화물', Colors.blue),
                const SizedBox(width: 20),
                _buildLegendItem('단백질', Colors.red),
                const SizedBox(width: 20),
                _buildLegendItem('지방', Colors.green),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Card(
                color: Colors.blueGrey.shade800,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
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
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Card(
                color: Colors.blueGrey.shade800,
                child: ListView.builder(
                  itemCount: meals.length,
                  itemBuilder: (context, index) {
                    final totalNutrients = _calculateTotalNutrients(
                        meals[index]['subMeals'].cast<Map<String, dynamic>>());
                    return ExpansionTile(
                      title: Text(
                        '${meals[index]['name']} - 총 칼로리: ${totalNutrients['calories']} 총 탄: ${totalNutrients['carbs']} 총 단: ${totalNutrients['protein']} 총 지: ${totalNutrients['fat']}',
                        style: TextStyle(color: Colors.white),
                      ),
                      children: meals[index]['subMeals']
                          .map<Widget>((subMeal) {
                        return CheckboxListTile(
                          title: Text(
                              '${subMeal['name']} (${subMeal['grams']}g)',
                              style: TextStyle(color: Colors.white)),
                          value: meals[index]['checkedMeals'] != null &&
                              meals[index]['checkedMeals']
                                  .contains(subMeal['name']),
                          onChanged: (bool? value) {
                            setState(() {
                              if (meals[index]['checkedMeals'] == null) {
                                meals[index]['checkedMeals'] = [];
                              }
                              if (value == true) {
                                meals[index]['checkedMeals']
                                    .add(subMeal['name']);
                              } else {
                                meals[index]['checkedMeals']
                                    .remove(subMeal['name']);
                              }
                            });
                          },
                          activeColor: Colors.cyan,
                          checkColor: Colors.white,
                          tileColor: Colors.blueGrey.shade700,
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.blueGrey.shade900,
      bottomNavigationBar: BottomAppBar(
        color: Colors.blueGrey.shade800,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            onPressed: () async {
              await _saveToFirebase();
              await _clearData();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyan,
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
            child: const Text(
              '완료',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

void main() {
  runApp(MaterialApp(home: FoodroutinestartPage()));
}
