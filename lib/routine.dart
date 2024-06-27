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
  List<String> collectionNames = [];

  @override
  void initState() {
    super.initState();
    myCollectionName();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showNameInputDialog(context);
    });
  }

  void deleteData(String documentId) async {
    try {
      // 문서 삭제
      await FirebaseFirestore.instance
          .collection("Routine")
          .doc('Myroutine')
          .collection(nameController.text)
          .doc(documentId)
          .delete();
      myCollectionName();
    } catch (e) {
      print('Error deleting document: $e');
    }
  }

  void myCollectionName() async {
    try {
      // 내루틴 가져오기
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Routine')
          .doc('Myroutine')
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

  void saveRoutineName() async {
    var db = FirebaseFirestore.instance;

    try {
      await db
          .collection('Routine')
          .doc('Routinename')
          .collection('Names')
          .add({'name': nameController.text});
      // 지정한 ID로 문서 참조 후 데이터 저장
    } catch (e) {
      print('Error adding document: $e');
    }
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
                  saveRoutineName();
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
              builder: (context) => CreateRoutinePage(_title),
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
