import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FoodCreatePage extends StatefulWidget {
  const FoodCreatePage({super.key});

  @override
  State<FoodCreatePage> createState() => _FoodCreatePageState();
}

class _FoodCreatePageState extends State<FoodCreatePage> {
  List<Map<String, dynamic>>? foodData;
  TextEditingController _foodNameController = TextEditingController();
  @override
  void dispose() {
    _foodNameController.dispose();
    super.dispose();
  }

  Future<void> fetchFoodData(String foodName) async {
    final url = Uri.parse(
        'http://openapi.foodsafetykorea.go.kr/api/c40b690515f447b599b7/I2790/json/1/1000/DESC_KOR=$foodName');

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;

      setState(() {
        if (data['I2790'] != null && data['I2790']['row'] != null) {
          foodData = List<Map<String, dynamic>>.from(data['I2790']['row']);
        } else {
          foodData = null;
        }
      });
    } else {
      throw Exception('Failed to load food data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Food Create Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _foodNameController,
              decoration: InputDecoration(
                labelText: '품목명 입력',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                fetchFoodData(_foodNameController.text);
              },
              child: Text('검색'),
            ),
            SizedBox(height: 16),
            Expanded(
              child: foodData == null
                  ? Center(child: Text('데이터를 불러올 수 없습니다.'))
                  : ListView.builder(
                      itemCount: foodData!.length,
                      itemBuilder: (context, index) {
                        final item = foodData![index];
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('식품이름: ${item['DESC_KOR']}'),
                                  Text('총내용량: ${item['SERVING_SIZE']}'),
                                  Text('열량(kcal): ${item['NUTR_CONT1']}'),
                                  Text('탄수화물(g): ${item['NUTR_CONT2']}'),
                                  Text('단백질(g): ${item['NUTR_CONT3']}'),
                                  Text('지방(g): ${item['NUTR_CONT4']}'),
                                ],
                              ),
                            ),
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
