import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_provider.dart';
import 'package:provider/provider.dart';
import 'foodcreate.dart';

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
  String? uid;

  @override
  void initState() {
    super.initState();
    uid = Provider.of<UserProvider>(context, listen: false).uid;
    print('유아이디인데 : $uid');
  }

  void _searchFood() async {
    String query = _mealController.text;
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    final results = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('Food')
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: query)
        .where(FieldPath.documentId, isLessThanOrEqualTo: query + '\uf8ff')
        .get();

    setState(() {
      _searchResults = results.docs.map((doc) => doc.id).toList();
    });
  }

  Future<void> _showFoodDetails(String foodName) async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('Food')
        .doc(foodName)
        .get();

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
          backgroundColor: Colors.blueGrey.shade900,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: Text(
            foodName,
            style: TextStyle(color: Colors.white),
          ),
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
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Grams',
                      labelStyle: TextStyle(color: Colors.white),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.cyan),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        grams = double.tryParse(value) ?? 0;
                        ratio = grams / (_selectedFoodData?['grams'] ?? 1);
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildFoodDetailText('Calories',
                      (_selectedFoodData?['calories'] ?? 0) * ratio),
                  _buildFoodDetailText(
                      'Carbs', (_selectedFoodData?['carbs'] ?? 0) * ratio),
                  _buildFoodDetailText(
                      'Protein', (_selectedFoodData?['protein'] ?? 0) * ratio),
                  _buildFoodDetailText(
                      'Fat', (_selectedFoodData?['fat'] ?? 0) * ratio),
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
              child: const Text('추가', style: TextStyle(color: Colors.cyan)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('닫기', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFoodDetailText(String label, double value) {
    return Text(
      '$label: ${value.toStringAsFixed(2)}',
      style: TextStyle(color: Colors.white),
    );
  }

  @override
  void dispose() {
    _mealController.dispose();
    _gramsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('끼니 추가', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueGrey.shade700,
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
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color.fromARGB(255, 65, 102, 106),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FoodCreatePage()),
              );
            },
            child: const Text('음식 추가',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _mealController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
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
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _searchFood,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 54, 72, 75),
              ),
              child: const Text('검색', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_searchResults[index],
                        style: TextStyle(color: Colors.white)),
                    trailing: IconButton(
                      icon: const Icon(Icons.search, color: Colors.cyan),
                      onPressed: () => _showFoodDetails(_searchResults[index]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.blueGrey.shade900,
    );
  }
}
