import 'dart:html';
import 'saveroutine.dart';
import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'routine.dart';
import 'create_routine.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'calender.dart';
import 'package:intl/intl.dart';
import 'bookmark.dart';

void main() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Homepage(),
    );
  }
}

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'IMYHNAM',
          style: TextStyle(
            color: Color.fromARGB(255, 243, 8, 8), // 글자 색상을 흰색으로 설정
          ),
        ),
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 17, 6, 6),
        leading: IconButton(
          icon: Icon(
            Icons.menu,
            color: Colors.white,
          ), // Icons.list 대신 Icons.menu를 사용
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.star,
              color: Colors.yellow,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BookMarkPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Flexible(
            flex: 3, // 상단 영역
            child: Container(
              color: Colors.black,
              child: Row(children: [
                Image.asset(
                  'health.jpg',
                  width: 150,
                ),
                Container(
                  width: 350,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder<Map<String, dynamic>?>(
                        future: _fetchRoutineData(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Center(
                                child: Text('오류 발생: ${snapshot.error}'));
                          }
                          if (!snapshot.hasData || snapshot.data == null) {
                            return Center(
                                child: Text('데이터가 없습니다.',
                                    style: TextStyle(color: Colors.white)));
                          }

                          var data = snapshot.data!;
                          var todayDate = DateTime.now();
                          var formattedDate =
                              '${todayDate.year}-${todayDate.month}-${todayDate.day}';

                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8.0),
                                  color: Colors.grey[800],
                                  child: Text(
                                    '오늘 날짜: $formattedDate',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 16),
                                  ),
                                ),
                                SizedBox(height: 8), // 간격 추가
                                Text(
                                  '오늘 총 세트수: ${data['오늘 총 세트수']}',
                                  style: TextStyle(color: Colors.white),
                                ),
                                Text(
                                  '오늘 총 볼륨: ${data['오늘 총 볼륨']}',
                                  style: TextStyle(color: Colors.white),
                                ),
                                Text(
                                  '오늘 총 운동시간: ${data['오늘 총 시간']}',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                )
              ]), // 상단 영역 배경 색상 설정
            ),
          ),
          Flexible(
            flex: 7, // 하단 영역
            child: Stack(
              children: [
                Container(
                  color: Colors.black, // 하단 영역 배경 색상 설정
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    margin:
                        EdgeInsets.only(right: 40.0, bottom: 20.0), // margin 추가
                    width: 200, // FloatingActionButton의 너비 조정
                    height: 60,
                    child: FloatingActionButton.extended(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const RoutinePage()),
                        );
                      },
                      icon: Icon(
                        Icons.add,
                        color: Colors.red,
                      ),
                      label: Text(
                        "루틴추가",
                        style: TextStyle(color: Colors.red),
                      ),
                      backgroundColor: Color.fromARGB(255, 243, 241, 240),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Container(
                    margin:
                        EdgeInsets.only(left: 40.0, bottom: 20.0), // margin 추가
                    width: 200, // FloatingActionButton의 너비 조정
                    height: 60,
                    child: FloatingActionButton.extended(
                      onPressed: () {
                        print('First FloatingActionButton pressed');
                      },
                      icon: Icon(
                        Icons.food_bank,
                        color: Colors.white,
                      ),
                      label: Text(
                        "식단추가",
                        style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Color.fromARGB(255, 199, 25, 19),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.black,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.work, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SaveRoutinePage()),
                    );
                  },
                ),
                Text(
                  '루틴',
                  style: TextStyle(color: Colors.white, fontSize: 8),
                ),
              ],
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.event_available, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CalenderPage()),
                    );
                  },
                ),
                Text(
                  '캘린더',
                  style: TextStyle(color: Colors.white, fontSize: 8),
                ),
              ],
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.directions_run, color: Colors.white),
                  onPressed: () {},
                ),
                Text(
                  '현재진행',
                  style: TextStyle(color: Colors.white, fontSize: 8),
                ),
              ],
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.lunch_dining, color: Colors.white),
                  onPressed: () {},
                ),
                Text(
                  '식단',
                  style: TextStyle(color: Colors.white, fontSize: 8),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
