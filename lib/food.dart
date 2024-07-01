import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class FoodCreatePage extends StatefulWidget {
  const FoodCreatePage({super.key});

  @override
  State<FoodCreatePage> createState() => _FoodCreatePageState();
}

class _FoodCreatePageState extends State<FoodCreatePage> {
  final TextEditingController _controller = TextEditingController();
  Map<String, dynamic>? _nutritionData;

  Future<void> _fetchNutritionData(String query) async {
    final String apiKey = 'YOUR_API_KEY'; // 여기에 공공데이터 포털 API 키를 입력하세요.
    final String url =
        'https://api.nongsaro.go.kr/service/foodComposition/foodCompositionList?apiKey=$apiKey&foodName=$query&type=json';

    final http.Response response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      setState(() {
        _nutritionData = json.decode(response.body);
      });
    } else {
      throw Exception('Failed to load nutrition data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "식단 생성",
          style: TextStyle(
            color: Color.fromARGB(255, 243, 8, 8),
          ),
        ),
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 17, 6, 6),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ), // Icons.list 대신 Icons.menu를 사용
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: '음식 검색',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () => _fetchNutritionData(_controller.text),
              child: Text('검색'),
            ),
            SizedBox(height: 16.0),
            _nutritionData != null
                ? Expanded(
                    child: ListView(
                      children: [
                        Text('칼로리: ${_nutritionData!['calories']} kcal'),
                        Text(
                            '탄수화물: ${_nutritionData!['totalNutrients']['CHOCDF']['quantity']} g'),
                        Text(
                            '단백질: ${_nutritionData!['totalNutrients']['PROCNT']['quantity']} g'),
                        Text(
                            '지방: ${_nutritionData!['totalNutrients']['FAT']['quantity']} g'),
                      ],
                    ),
                  )
                : Text('검색 결과가 없습니다.'),
          ],
        ),
      ),
    );
  }
}
