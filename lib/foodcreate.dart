import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_provider.dart';
import 'package:provider/provider.dart';


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
  String? uid;

  void initState() {
    super.initState();
    uid = Provider.of<UserProvider>(context, listen: false).uid;
  }

  Future<void> _addFood() async {
    foodName = _nameController.text;
    double grams = double.tryParse(_gramsController.text) ?? 0;
    calories = double.tryParse(_caloriesController.text) ?? 0;
    carbs = double.tryParse(_carbsController.text) ?? 0;
    protein = double.tryParse(_proteinController.text) ?? 0;
    fat = double.tryParse(_fatController.text) ?? 0;

    if (foodName.isNotEmpty && grams > 0 && calories > 0) {
      await FirebaseFirestore.instance.collection('users')
        .doc(uid).collection('Food').doc(foodName).set({
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
        title: const Text('음식 추가', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueGrey.shade900,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
            size: 28,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
          tooltip: '뒤로 가기',
        ),
        
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.blueGrey.shade900,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(_nameController, '음식 이름'),
            _buildTextField(_gramsController, '그람수'),
            _buildTextField(_caloriesController, '칼로리'),
            _buildTextField(_carbsController, '탄수화물'),
            _buildTextField(_proteinController, '단백질'),
            _buildTextField(_fatController, '지방'),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  _addFood();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                child: const Text('음식 추가', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 20),
            if (foodName.isNotEmpty && calories > 0) ...[
              _buildInfoText('음식 이름: $foodName'),
              _buildInfoText('칼로리: $calories'),
              const SizedBox(height: 20),
              _buildMacroNutrientsLegend(),
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
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String labelText, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: Colors.white),
        border: const OutlineInputBorder(),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.cyan),
        ),
      ),
    );
  }

  Widget _buildInfoText(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildMacroNutrientsLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        _buildLegendItem('탄수화물', Colors.blue),
        _buildLegendItem('단백질', Colors.red),
        _buildLegendItem('지방', Colors.green),
      ],
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
