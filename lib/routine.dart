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
  List<String> collectionNames = [];

  final Map<String, dynamic> user = {
    "first": "1",
  };

  @override
  void initState() {
    super.initState();
    myCollectionName();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showNameInputDialog(context);
    });
  }

  void _showDeleteDialog(BuildContext context, String documentId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("루틴 생성 삭제"),
          content: Text("아 파이어베이스 데이터 한 개도 없으면 날라간대"),
          actions: [
            TextButton(
              child: Text("예"),
              onPressed: () {
                deleteData(documentId); // 문서 삭제
                Navigator.of(context).pop(); // 팝업 닫기
                Navigator.of(context).pop(); // 이전 화면으로 돌아가기
              },
            ),
            TextButton(
              child: Text("아니요"),
              onPressed: () {
                Navigator.of(context).pop(); // 팝업 닫기
              },
            ),
          ],
        );
      },
    );
  }

  void deleteData(String documentId) async {
    if (collectionNames.length == 1) {
      _showDeleteDialog(context, documentId);
    } else {
      try {
        // 문서 삭제
        await FirebaseFirestore.instance
            .collection(nameController.text)
            .doc(documentId)
            .delete();
        myCollectionName();
      } catch (e) {
        print('Error deleting document: $e');
      }
    }
  }

  void myCollectionName() async {
    try {
      // '_title' 컬렉션에서 하위 문서 ID들 가져오기
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection(nameController.text)
          .get();
      List<String> names = querySnapshot.docs.map((doc) => doc.id).toList();

      setState(() {
        collectionNames = names;
      });
    } catch (e) {
      print('Error fetching collection names: $e');
    }
  }

  void _myRoutineName(String collectionName) async {
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
                _myRoutineName(nameController.text);
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
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.edit,
                  color: Colors.white,
                ),
                onPressed: () {
                  _showNameInputDialog(context);
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.save,
                  color: Colors.white,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          )
        ],
      ),
      body: Container(
        color: Colors.black,
        child: ListView.builder(
          itemCount: collectionNames.length,
          itemBuilder: (context, index) {
            return Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(20.0),
                    color: Colors.white.withOpacity(0.5),
                    child: Text(
                      collectionNames[index],
                      style: TextStyle(fontSize: 18.0),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    deleteData(collectionNames[index]);
                  },
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateRoutinePage(_title, notmyid),
            ),
          ).then((value) {
            if (value == true) {
              myCollectionName();
            }
          });
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
