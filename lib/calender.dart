import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CalenderPage extends StatefulWidget {
  const CalenderPage({super.key});

  @override
  _CalenderPageState createState() => _CalenderPageState();
}

class _CalenderPageState extends State<CalenderPage> {
  DateTime selectedDate = DateTime.now();

  Future<Map<String, dynamic>?> _fetchRoutineData() async {
    var db = FirebaseFirestore.instance;
    String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);

    try {
      QuerySnapshot snapshot = await db
          .collection('Calender')
          .doc('health')
          .collection(formattedDate)
          .orderBy('timestamp', descending: true)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data() as Map<String, dynamic>;
      }
    } catch (e) {
      print('Error fetching document: $e');
    }
    return null;
  }

  void _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('캘린더 페이지'),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () => _selectDate(context),
            child: Text('날짜 선택'),
          ),
          FutureBuilder<Map<String, dynamic>?>(
            future: _fetchRoutineData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('오류 발생: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data == null) {
                return Center(child: Text('데이터가 없습니다.'));
              }

              var data = snapshot.data!;
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('오늘 총 운동 세트수: ${data['오늘 총 세트수']}'),
                    Text('오늘 총 운동 볼륨: ${data['오늘 총 볼륨']}'),
                    Text('오늘 총 운동 시간: ${data['오늘 총 시간']}'),
                    Text('운동 완료 시간: ${data['timestamp']?.toDate() ?? 'N/A'}'),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
