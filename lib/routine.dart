import 'package:flutter/material.dart';
import 'create_routine.dart';

class RoutinePage extends StatelessWidget {
  const RoutinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '루틴 생성',
          style: TextStyle(
            color: Color.fromARGB(255, 243, 8, 8), // 글자 색상을 흰색으로 설정
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
      body: Stack(
        children: [
          Container(
            color: Colors.black,
          ),
          Align(
            alignment: Alignment.center,
            child: FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CreateRoutinePage()),
                );
              },
              icon: Icon(
                Icons.add,
                color: Colors.white,
              ),
              label: Text(
                "생성",
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Color.fromARGB(255, 199, 25, 19),
            ),
          )
        ],
      ),
    );
  }
}
