import 'dart:html';
import 'package:health/food.dart';
import 'package:flutter_charts/flutter_charts.dart';
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
import 'start_routine.dart';
import 'chart.dart';

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
  List<String> collectionNames = [];

  @override
  void initState() {
    super.initState();
    _fetchSevenDayAgoData();
  }

  Future<void> _fetchSevenDayAgoData() async {
    List<String> names = await _sevendayago();
    setState(() {
      collectionNames = names;
    });
  }

  Future<List<String>> _sevendayago() async {
    var db = FirebaseFirestore.instance;
    String sevenDaysAgoDate = DateFormat('yyyy-MM-dd')
        .format(selectedDate.subtract(Duration(days: 7)));
    print(sevenDaysAgoDate);
    try {
      // 7일 전 날짜의 데이터 가져오기
      QuerySnapshot snapshot = await db
          .collection('Calender')
          .doc('health')
          .collection(sevenDaysAgoDate)
          .get();

      // 7일 전 루틴 이름 리스트를 추출
      List<String> routineNames =
          snapshot.docs.map((doc) => doc['오늘 한 루틴이름'] as String).toList();

      return routineNames;
    } catch (e) {
      print('오류 발생: $e');
      return [];
    }
  }

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
          'Life is Gorip',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Pacifico',
            fontSize: 24.0, // 글자 색상을 흰색으로 설정
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueGrey.shade700,
        leading: IconButton(
          icon: Icon(
            Icons.menu,
            color: Colors.white,
          ), // Icons.list 대신 Icons.menu를 사용
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RoutineChart()),
            );
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => BookMarkPage()),
                    );
                  },
                  icon: Icon(
                    Icons.star,
                    color: Colors.yellow,
                  ),
                  label: Text(
                    '즐겨찾기',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.blueGrey.shade700, // 버튼 배경색 설정
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.blueGrey.shade900,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 7,
              offset: Offset(0, 3), // changes position of shadow
            ),
          ],
          border: Border.all(
            color: Colors.blueGrey.shade700,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Flexible(
              flex: 3, // 상단 영역
              child: Container(
                child: Row(children: [
                  Image.asset(
                    'dumbbell.png',
                    width: 100,
                  ),
                  Container(
                    width: 350,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 오늘 날짜를 항상 표시하는 Container
                        Padding(
                          padding: const EdgeInsets.all(0.0),
                          child: Align(
                            alignment: Alignment(-0.2, 0.0),
                            child: Container(
                              padding: const EdgeInsets.all(8.0),
                              color: Colors.grey[800],
                              child: Text(
                                '오늘 날짜: ${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontFamily: 'Oswald',
                                ),
                              ),
                            ),
                          ),
                        ),
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
                                child: Text(
                                  '데이터가 없습니다.',
                                  style: TextStyle(color: Colors.white),
                                ),
                              );
                            }

                            var data = snapshot.data!;

                            return Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 8),
                                  Text(
                                    '오늘 한 루틴이름: ${data['오늘 한 루틴이름']}',
                                    style: TextStyle(
                                        color:
                                            Color.fromARGB(255, 242, 241, 241),
                                        fontFamily: 'Oswald',
                                        fontSize: 13),
                                  ),
                                  Text(
                                    '오늘 총 세트수: ${data['오늘 총 세트수']}',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 10),
                                  ),
                                  Text(
                                    '오늘 총 볼륨: ${data['오늘 총 볼륨']}',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 10),
                                  ),
                                  Text(
                                    '오늘 총 운동시간: ${data['오늘 총 시간']}',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 10),
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
                    child: ListView.builder(
                      itemCount: collectionNames.length,
                      itemBuilder: (context, index) {
                        String collectionName = collectionNames[index];

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 15.0, horizontal: 30.0), // 좌우 여백 추가
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.all(25.0),
                                    backgroundColor:
                                        Colors.blueGrey.shade800, // 배경 색상
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15.0),
                                      side: BorderSide(
                                        color: Colors.blueGrey.shade700,
                                        width: 2,
                                      ), // 둥근 모서리 반경 설정
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => StartRoutinePage(
                                          clickroutinename: collectionName,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        collectionName,
                                        style: TextStyle(
                                          fontSize: 20.0,
                                          color: Colors.white,
                                          fontFamily: 'Oswald',
                                        ),
                                      ),
                                      SizedBox(height: 5.0),
                                      Text(
                                        '7일전 루틴',
                                        style: TextStyle(
                                          fontSize: 15.0,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ), // 하단 영역 배경 색상 설정
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      margin: EdgeInsets.only(
                          right: 40.0, bottom: 20.0), // margin 추가
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
                          color: Colors.blueGrey.shade700,
                        ),
                        label: Text(
                          "루틴추가",
                          style: TextStyle(
                            color: Colors.blueGrey.shade700,
                            fontFamily: 'Oswald',
                          ),
                        ),
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Container(
                      margin: EdgeInsets.only(
                          left: 40.0, bottom: 20.0), // margin 추가
                      width: 200, // FloatingActionButton의 너비 조정
                      height: 60,
                      child: FloatingActionButton.extended(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const FoodCreatePage()),
                          );
                        },
                        icon: Icon(
                          Icons.food_bank,
                          color: Colors.white,
                        ),
                        label: Text(
                          "식단추가",
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Oswald',
                          ),
                        ),
                        backgroundColor: Colors.cyan.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.blueGrey.shade800,
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
