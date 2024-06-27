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
      home: SaveRoutinePage(),
    );
  }
}

class Homepage extends StatelessWidget {
  const Homepage({super.key});

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
          onPressed: () {
            print('Leading icon pressed');
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.account_box,
              color: Colors.white,
            ),
            onPressed: () {
              // 우측 상단 아이콘 클릭 시 실행할 동작
              print('Search icon pressed');
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
                      Padding(
                        padding:
                            EdgeInsets.only(left: 50.0), // 오른쪽으로 16.0의 여백을 줍니다.
                        child: Text(
                          '2024-06-26',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 25.0), // 폰트 크기를 18.0으로 설정합니다.
                        ),
                      ),
                      Padding(
                        padding:
                            EdgeInsets.only(left: 50.0), // 오른쪽으로 16.0의 여백을 줍니다.
                        child: Text(
                          '현재까지 먹은 칼로리: 1200kcal',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 15.0), // 폰트 크기를 18.0으로 설정합니다.
                        ),
                      ),
                      Padding(
                        padding:
                            EdgeInsets.only(left: 50.0), // 오른쪽으로 16.0의 여백을 줍니다.
                        child: Text(
                          '탄 60g 단 140g 지 20g',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 15.0), // 폰트 크기를 18.0으로 설정합니다.
                        ),
                      ),
                      Padding(
                        padding:
                            EdgeInsets.only(left: 50.0), // 오른쪽으로 16.0의 여백을 줍니다.
                        child: Text(
                          '오늘 총 운동 볼륨 : 12000 운동시간 : 1h',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 15.0), // 폰트 크기를 18.0으로 설정합니다.
                        ),
                      ),
                      Padding(
                        padding:
                            EdgeInsets.only(left: 50.0), // 오른쪽으로 16.0의 여백을 줍니다.
                        child: Text(
                          'Im thinking about what to add',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 15.0), // 폰트 크기를 18.0으로 설정합니다.
                        ),
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
                    print('Search icon pressed');
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
