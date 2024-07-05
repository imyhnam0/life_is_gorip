import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddMealPage extends StatefulWidget {
  const AddMealPage({Key? key}) : super(key: key);

  @override
  _AddMealPageState createState() => _AddMealPageState();
}

class _AddMealPageState extends State<AddMealPage> {
  final TextEditingController _mealController = TextEditingController();
  List<String> _searchResults = [];
  final TextEditingController _gramsController = TextEditingController();

  Map<String, dynamic>? _selectedFoodData;

  void _searchFood() async {
    String query = _mealController.text;
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    final results = await FirebaseFirestore.instance
        .collection('Food')
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: query)
        .where(FieldPath.documentId, isLessThanOrEqualTo: query + '\uf8ff')
        .get();

    setState(() {
      _searchResults = results.docs.map((doc) => doc.id).toList();
    });
  }

  void _showFoodDetails(String foodName) async {
    DocumentSnapshot doc = await FirebaseFirestore.instance.collection('Food').doc(foodName).get();

    if (doc.exists) {
      setState(() {
        _selectedFoodData = doc.data() as Map<String, dynamic>?;
        _gramsController.text = _selectedFoodData?['grams'].toString() ?? '0';
      });

      _showFoodDialog(foodName);
    }
  }

  void _showFoodDialog(String foodName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(foodName),
          content: StatefulBuilder(
            builder: (context, setState) {
              double grams = double.tryParse(_gramsController.text) ?? 0;
              double ratio = grams / (_selectedFoodData?['grams'] ?? 1);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _gramsController,
                    decoration: const InputDecoration(labelText: 'Grams'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        grams = double.tryParse(value) ?? 0;
                        ratio = grams / (_selectedFoodData?['grams'] ?? 1);
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Text('Calories: ${(_selectedFoodData?['calories'] ?? 0) * ratio}'),
                  Text('Carbs: ${(_selectedFoodData?['carbs'] ?? 0) * ratio}'),
                  Text('Protein: ${(_selectedFoodData?['protein'] ?? 0) * ratio}'),
                  Text('Fat: ${(_selectedFoodData?['fat'] ?? 0) * ratio}'),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (_selectedFoodData != null) {
                  double grams = double.tryParse(_gramsController.text) ?? 0;
                  double ratio = grams / (_selectedFoodData?['grams'] ?? 1);
                  Navigator.pop(context);
                  Navigator.of(context).pop({
                    'name': foodName,
                    'grams': _gramsController.text,
                    'calories': (_selectedFoodData?['calories'] ?? 0) * ratio,
                    'carbs': (_selectedFoodData?['carbs'] ?? 0) * ratio,
                    'protein': (_selectedFoodData?['protein'] ?? 0) * ratio,
                    'fat': (_selectedFoodData?['fat'] ?? 0) * ratio,
                  });
                }
              },
              child: const Text('추가'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('끼니 추가'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _mealController,
              decoration: const InputDecoration(
                labelText: '끼니 이름 입력',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _searchFood,
                  child: const Text('검색'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_searchResults[index]),
                    trailing: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () => _showFoodDetails(_searchResults[index]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
