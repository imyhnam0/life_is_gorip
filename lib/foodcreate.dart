import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FoodCreatePage extends StatefulWidget {
  const FoodCreatePage({super.key});

  @override
  _FoodCreatePageState createState() => _FoodCreatePageState();
}

class _FoodCreatePageState extends State<FoodCreatePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _gramsController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _carbsController = TextEditingController();
  final TextEditingController _proteinController = TextEditingController();
  final TextEditingController _fatController = TextEditingController();

  String foodName = '';
  double calories = 0;
  double carbs = 0;
  double protein = 0;
  double fat = 0;

  Future<void> _addFood() async {
    foodName = _nameController.text;
    double grams = double.tryParse(_gramsController.text) ?? 0;
    calories = double.tryParse(_caloriesController.text) ?? 0;
    carbs = double.tryParse(_carbsController.text) ?? 0;
    protein = double.tryParse(_proteinController.text) ?? 0;
    fat = double.tryParse(_fatController.text) ?? 0;

    if (foodName.isNotEmpty && grams > 0 && calories > 0) {
      await FirebaseFirestore.instance.collection('Food').doc(foodName).set({
        'grams': grams,
        'calories': calories,
        'carbs': carbs,
        'protein': protein,
        'fat': fat,
      });
      setState(() {});
    } else {
      // Handle the case when fields are empty or invalid
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('음식 추가'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: '음식 이름'),
            ),
            TextField(
              controller: _gramsController,
              decoration: const InputDecoration(labelText: '그람수'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _caloriesController,
              decoration: const InputDecoration(labelText: '칼로리'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _carbsController,
              decoration: const InputDecoration(labelText: '탄수화물'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _proteinController,
              decoration: const InputDecoration(labelText: '단백질'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _fatController,
              decoration: const InputDecoration(labelText: '지방'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _addFood();
                Navigator.pop(context);},
              child: const Text('음식 추가'),
            ),
            const SizedBox(height: 20),
            if (foodName.isNotEmpty && calories > 0) ...[
              Text(
                '음식 이름: $foodName',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                '칼로리: $calories',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  Text(
                    '탄수화물 : ',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
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
                        fontSize: 20, fontWeight: FontWeight.bold),
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
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    width: 20,
                    height: 20,
                    color: Colors.green,
                  ),
                ],
              )
            ],
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
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> showingSections() {
    final total = carbs + protein + fat;
    if (total == 0) return [];

    return [
      PieChartSectionData(
        color: Colors.blue,
        value: (carbs / total) * 100,
        title: '${(carbs / total * 100).toStringAsFixed(1)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        color: Colors.red,
        value: (protein / total) * 100,
        title: '${(protein / total * 100).toStringAsFixed(1)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        color: Colors.green,
        value: (fat / total) * 100,
        title: '${(fat / total * 100).toStringAsFixed(1)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ];
  }
}

void main() {
  runApp(const MaterialApp(home: FoodCreatePage()));
}
