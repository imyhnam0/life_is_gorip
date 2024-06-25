import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
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
              // 좌상단 아이콘 클릭 시 실행할 동작 구현
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
        body: Container(
          color: Color.fromARGB(255, 37, 29, 29),
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
                    onPressed: () {},
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
                    onPressed: () {
                      print('Profile icon pressed');
                    },
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
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }
}
