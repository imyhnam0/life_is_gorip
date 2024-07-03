import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'playroutine.dart';
import 'create_routine.dart';

class StartRoutinePage extends StatefulWidget {
  final String clickroutinename;
  const StartRoutinePage({Key? key, required this.clickroutinename})
      : super(key: key);

  @override
  _StartRoutinePageState createState() => _StartRoutinePageState();
}

class _StartRoutinePageState extends State<StartRoutinePage> {
  TextEditingController nameController = TextEditingController();
  late String _title = widget.clickroutinename;
  List<String> collectionNames = [];

  @override
  void initState() {
    super.initState();
    myCollectionName();
  }

  void deleteData(String documentId) async {
    try {
      // 문서 삭제
      await FirebaseFirestore.instance
          .collection("Routine")
          .doc('Myroutine')
          .collection(widget.clickroutinename)
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
          .collection(widget.clickroutinename)
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
          backgroundColor: Color.fromARGB(255, 39, 34, 34),
          title: Text(
            'My routine name',
            style: TextStyle(color: Colors.red),
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
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                '확인',
                style: TextStyle(color: Colors.red),
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
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueGrey.shade700,
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
        child: ListView.builder(
            itemCount: collectionNames.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 15.0, horizontal: 30.0), // 좌우 여백 추가
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.all(30.0),
                          backgroundColor: Colors.blueGrey.shade800, // 배경 색상
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
                              builder: (context) => CreateRoutinePage(
                                myroutinename: _title,
                                clickroutinename: collectionNames[index],
                              ),
                            ),
                          ).then((value) {
                            if (value == true) {
                              myCollectionName();
                            }
                            if (value == false) {
                              deleteData(collectionNames[index]);
                            }
                          });
                        },
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween, // 아이템 간의 공간을 최대화
                          children: [
                            // 왼쪽 끝에 아이콘
                            Text(
                              collectionNames[index],
                              style: TextStyle(
                                  fontSize: 18.0, color: Colors.white),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                deleteData(collectionNames[index]);
                              },
                            ), // 오른쪽 끝에 아이콘
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.blueGrey.shade800,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Container(
              width: 170.0, // 원하는 너비로 설정
              height: 56.0, // 원하는 높이로 설정
              child: FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateRoutinePage(
                        myroutinename: _title,
                        clickroutinename: "",
                      ),
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
                backgroundColor: Colors.cyan.shade700,
              ),
            ),
            Container(
              width: 170.0, // 원하는 너비로 설정
              height: 56.0, // 원하는 높이로 설정
              child: FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => PlayMyRoutinePage(
                            clickroutinename: widget.clickroutinename)),
                  );
                },
                icon: Icon(
                  Icons.sports_gymnastics,
                  color: Colors.blueGrey.shade700,
                ),
                label: Text(
                  "시작",
                  style: TextStyle(color: Colors.blueGrey.shade700),
                ),
                backgroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
