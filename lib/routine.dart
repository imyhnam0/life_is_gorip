import 'package:flutter/material.dart';
import 'create_routine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoutinePage extends StatefulWidget {
  const RoutinePage({super.key});

  @override
  State<RoutinePage> createState() => _RoutinePageState();
}

class _RoutinePageState extends State<RoutinePage> {
  TextEditingController nameController = TextEditingController();
  String _title = '';
  String notmyid = '';

  final Map<String, dynamic> user = {
    "first": "1",
  };

  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showNameInputDialog(context);
    });
  }

  void _addDocumentToCollection(String collectionName) async {
    try {
      // 문서를 추가하고 DocumentReference를 반환받음
      DocumentReference docRef =
          await FirebaseFirestore.instance.collection(collectionName).add(user);
      // 문서 ID 저장
      String notmyid = docRef.id;
      // 필요시 상태 관리 (예: State 변수에 저장)
      setState(() {
        this.notmyid = notmyid; // documentId를 클래스 변수로 선언했다고 가정
      });
    } catch (e) {
      print('Error adding document: $e');
    }
  }

  void _showNameInputDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey,
          title: Text(
            'My routine name',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(
              hintText: "이름을 입력하세요",
              hintStyle: TextStyle(color: Colors.grey), // 힌트 텍스트 색상
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.red), // 기본 상태의 밑줄 색상
              ),
              fillColor: Colors.white, // 텍스트 필드 배경 색상
              filled: true,
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                '취소',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                '확인',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                _addDocumentToCollection(nameController.text);
                setState(() {
                  _title = nameController.text;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _title,
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
                    builder: (context) => CreateRoutinePage(_title, notmyid),
                  ),
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
