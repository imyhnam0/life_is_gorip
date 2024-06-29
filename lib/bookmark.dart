import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'start_routine.dart';

class BookMarkPage extends StatefulWidget {
  @override
  State<BookMarkPage> createState() => _BookMarkPageState();
}

class _BookMarkPageState extends State<BookMarkPage> {
  List<String> collectionNames = [];

  bool _isChecked = false;

  @override
  void initState() {
    super.initState();
    myCollectionName();
  }

  void deleteCollection(String documentId) async {
    try {
      // 컬렉션의 모든 문서를 가져옴
      var collectionRef = FirebaseFirestore.instance
          .collection("Routine")
          .doc('Myroutine')
          .collection(documentId);

      var snapshots = await collectionRef.get();

      // 각 문서를 삭제
      for (var doc in snapshots.docs) {
        await doc.reference.delete();
      }
      var namesCollectionRef = FirebaseFirestore.instance
          .collection("Routine")
          .doc('Routinename')
          .collection("Names");

      var namesSnapshots =
          await namesCollectionRef.where('name', isEqualTo: documentId).get();

      // 각 문서를 삭제
      for (var doc in namesSnapshots.docs) {
        await doc.reference.delete();
      }
      myCollectionName();
      // 새로고침 함수 호출
    } catch (e) {
      print('Error deleting collection: $e');
    }
  }

  void myCollectionName() async {
    try {
      // '_title' 컬렉션에서 하위 문서 ID들 가져오기
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection("Routine")
          .doc('Routinename')
          .collection('Names')
          .get();
      List<String> names =
          querySnapshot.docs.map((doc) => doc['name'] as String).toList();

      setState(() {
        collectionNames = names;
      });
    } catch (e) {
      print('Error fetching collection names: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "루틴 모음",
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
      ),
      body: Container(
        color: Colors.black,
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
                          padding: EdgeInsets.all(25.0),
                          backgroundColor:
                              Color.fromARGB(255, 39, 34, 34), // 배경 색상
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(15.0), // 둥근 모서리 반경 설정
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StartRoutinePage(
                                clickroutinename: collectionNames[index],
                              ),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween, // 아이템 간의 공간을 최대화
                          children: [
                            // 왼쪽 끝에 아이콘
                            Text(
                              collectionNames[index],
                              style:
                                  TextStyle(fontSize: 18.0, color: Colors.red),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                deleteCollection(collectionNames[index]);
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
    );
  }
}
