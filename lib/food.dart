import 'package:flutter/material.dart';
import 'foodcreate.dart';

class FoodRoutineCreatePage extends StatefulWidget {
  const FoodRoutineCreatePage({super.key});

  @override
  State<FoodRoutineCreatePage> createState() => _FoodRoutineCreatePageState();
}

class _FoodRoutineCreatePageState extends State<FoodRoutineCreatePage> {
  List<Map<String, dynamic>> meals = [];

  Future<void> _navigateAndAddSubMeal(BuildContext context, int mealIndex) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddMealPage()),
    );
    if (result != null && result is String) {
      print(result);
      setState(() {
        meals[mealIndex]['subMeals'].add(result);
      });
    }
  }

  void _addMeal() {
    setState(() {
      meals.add({
        'name': '${meals.length + 1}번째 끼니',
        'subMeals': [],
        'isExpanded': false,
      });
    });
  }

   void _toggleExpansion(int index, bool isExpanded) {
    setState(() {
      meals[index]['isExpanded'] = isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Food Routine Create Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _addMeal,
              child: Text('끼니 추가'),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: meals.length,
                itemBuilder: (context, index) {
                  return ExpansionTile(
                    title: Text(meals[index]['name']),
                   trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () {
                            _navigateAndAddSubMeal(context, index);
                          },
                        ),
                        Icon(meals[index]['isExpanded']
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down),
                      ],
                    ),
                    onExpansionChanged: (isExpanded) {
                      _toggleExpansion(index, isExpanded);
                    },
                    children: meals[index]['subMeals'].map<Widget>((subMeal) {
                      return ListTile(
                        title: Text(subMeal),
                      );
                    }).toList(),
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
    home: FoodRoutineCreatePage(),
  ));
}
