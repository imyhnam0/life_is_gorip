//만든 루틴 안에 들어와서 시작 버튼을 누르면 운동을 시작하게 하는 페이지

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'playroutine.dart';
import 'create_routine.dart';
import '../services/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';


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
  String? uid;

  @override
  void initState() {
    super.initState();
    uid = Provider.of<UserProvider>(context, listen: false).uid;
    myCollectionName();
  }

  //운동 시작할떄 현재 위치를 저장하는 함수
  Future<void> saveUserLocationAndState(String uid) async {
    try {
      // 위치 권한 확인 및 요청
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('위치 서비스가 비활성화되었습니다. 활성화 후 다시 시도해주세요.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('위치 권한이 거부되었습니다.');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('위치 권한이 영구적으로 거부되었습니다.');
      }
      // 현재 위치 가져오기
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      // Firestore에 위치와 상태 업데이트
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'isExercising': true,
        'location': {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': FieldValue.serverTimestamp(),
        },
      });

      print("운동 상태 및 위치 정보가 저장되었습니다.");
    } catch (e) {
      print("위치 정보를 저장하는 중 오류 발생: $e");
    }
  }

  Future<void> deleteData(String routineTitle) async {
  try {
    DocumentReference docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('Routine')
        .doc('Myroutine');

    DocumentSnapshot documentSnapshot = await docRef.get();
    print(routineTitle);

    if (documentSnapshot.exists) {
      var data = documentSnapshot.data() as Map<String, dynamic>;

      if (data.containsKey(_title)) {
        List<dynamic> myRoutineList = data[_title];

        // Find the index of the routine to delete
        int routineIndex = myRoutineList.indexWhere((routine) => routine.containsKey(routineTitle));

        // Remove the routine if found
        if (routineIndex != -1) {
          myRoutineList.removeAt(routineIndex);
          await docRef.update({_title: myRoutineList});
        }
      }
    }

    await myCollectionName();
  } catch (e) {
    print('Error deleting document: $e');
  }
}
  Future<void> myCollectionName() async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('Routine')
          .doc('Myroutine');

      final docSnap = await docRef.get();

      if (docSnap.exists) {
        final data = docSnap.data() as Map<String, dynamic>;
        if (data.containsKey(_title)) {
          final List<dynamic> myRoutineList = data[_title];

          // 각 루틴 항목의 key를 가져오기
          List<String> names = myRoutineList
              .map((routine) => routine.keys.first as String)
              .toList();

          setState(() {
            collectionNames = names;
          });
        }
      }
    } catch (e) {
      print('Error fetching collection names: $e');
    }
  }


  Future<void> saveCollectionNames(List<String> names) async {
    try {
      DocumentReference docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('Routine')
          .doc('Myroutine');

      DocumentSnapshot snapshot = await docRef.get();
      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        if (data.containsKey(_title)) {
          List<dynamic> originalList = data[_title];
          // 새로 저장할 리스트를 순서에 맞게 재정렬
          List<dynamic> reorderedList = [];
          for (String name in names) {
            final item = originalList.firstWhere((element) => element.containsKey(name));
            reorderedList.add(item);
          }
          // Firestore에 업데이트
          await docRef.update({_title: reorderedList});
        }
      }
    } catch (e) {
      print('Firestore에 순서를 저장하는 중 오류 발생: $e');
    }
  }

  Future<void> _updateRoutineTitle(String newTitle) async {
  try {
    DocumentReference docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('Routine')
        .doc('Myroutine');

    DocumentSnapshot documentSnapshot = await docRef.get();

    if (documentSnapshot.exists) {
      var data = documentSnapshot.data() as Map<String, dynamic>;

      if (data.containsKey(_title)) {
        List<dynamic> myRoutineList = data[_title];

        await docRef.update({_title: FieldValue.delete()});
        data.remove(_title);
        data[newTitle] = myRoutineList;

        await docRef.set(data, SetOptions(merge: true));
      }
    }
    final oldPrefix = _title;
    final newPrefix = newTitle;
    final nameRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('Routine')
        .doc('Routinename');

    final nameSnap = await nameRef.get();
    if (nameSnap.exists) {
      List<String> names = List<String>.from(nameSnap['names']);
      bool hasSamePrefix =
      names.any((name) => name.startsWith('$oldPrefix-'));

      if (hasSamePrefix) {
        // 접두사 일치하는 항목들만 변경
        List<String> updatedNames = names.map((name) {
          if (name.startsWith('$oldPrefix-')) {
            return name.replaceFirst(oldPrefix, newPrefix);
          } else {
            return name;
          }
        }).toList();

        await nameRef.update({'names': updatedNames});
      }
    }
    // 1. Bookmark 문서 업데이트
    final bookmarkRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('Routine')
        .doc('Bookmark');

    final bookmarkSnap = await bookmarkRef.get();
    if (bookmarkSnap.exists) {
      List<String> names = List<String>.from(bookmarkSnap['names']);
      int index = names.indexOf(oldPrefix);
      if (index != -1) {
        names[index] = newPrefix;
        await bookmarkRef.update({'names': names});
      }
    }

// 2. RoutineOrder 문서 업데이트
    final orderRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('Routine')
        .doc('RoutineOrder');

    final orderSnap = await orderRef.get();
    if (orderSnap.exists) {
      List<String> titles = List<String>.from(orderSnap['titles']);
      int index = titles.indexOf(oldPrefix);
      if (index != -1) {
        titles[index] = newPrefix;
        await orderRef.update({'titles': titles});
      }
    }


    setState(() {
      _title = newTitle;
    });

   
  } catch (e) {
    print('Error updating document: $e');
  }
}



  void _showNameInputDialog(BuildContext context) {
    nameController.text = _title;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.cyan.shade900,
          title: const Text(
            'NAME',

            style: TextStyle(color: Colors.white
            , fontSize: 24.0, fontWeight: FontWeight.bold,

            ),

          ),
          content: TextField(
            controller: nameController,
            style: const TextStyle(color: Colors.black),
            decoration: InputDecoration(
              hintText: "이름을 입력하세요",
              hintStyle: const TextStyle(color: Colors.grey),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black),
              ),
              fillColor: Colors.white,
              filled: true,
            ),
          ),
          actions: [
            TextButton(
              child: const Text(
                '취소',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                '확인',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                
               _updateRoutineTitle(nameController.text);
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
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueGrey.shade700,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context, true); // 성공적으로 이름 변경 후

          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.edit,
              color: Colors.white,
            ),
            onPressed: () {
              _showNameInputDialog(context);
            },
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
              offset: Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: Colors.blueGrey.shade700,
            width: 2,
          ),
        ),
        child: ReorderableListView(
            
          
          onReorder: (oldIndex, newIndex) {
            if (newIndex > oldIndex) {
              newIndex -= 1;
            }
            setState(() {
              final item = collectionNames.removeAt(oldIndex);
              collectionNames.insert(newIndex, item);
              saveCollectionNames(collectionNames); // 순서가 바뀔 때마다 저장
            });
          },
           proxyDecorator:
              (Widget child, int index, Animation<double> animation) {
            return Material(
              color: Colors.transparent, // Material 위젯의 color 속성을 직접 조정
              child: child,
              elevation: 0.0,
            );
          },
          children: [
            for (final name in collectionNames)
              Padding(
                key: ValueKey(name),
                padding: const EdgeInsets.symmetric(
                  vertical: 15.0, horizontal: 30.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.all(30.0),
                          backgroundColor: Colors.blueGrey.shade800,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0),
                            side: BorderSide(
                              color: Colors.blueGrey.shade700,
                              width: 2,
                            ),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CreateRoutinePage(
                                myroutinename: _title,
                                clickroutinename: name,
                              ),
                            ),
                          ).then((value) {
                            if (value == true) {
                              myCollectionName();
                            }
                          }
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 18.0, color: Colors.white),
                            ),
                            Spacer(),

                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                // 삭제 확인 다이얼로그 띄우기
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      backgroundColor: Colors.blueGrey.shade800,
                                      title: const Text(
                                        '진짜 삭제하시겠습니까?',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      content: const Text(
                                        '이 작업은 되돌릴 수 없습니다. 계속하시겠습니까?',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop(); // 다이얼로그 닫기
                                          },
                                          child: const Text(
                                            '아니요',
                                            style: TextStyle(color: Colors.white),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            // "예"를 누르면 삭제 함수 실행
                                            await deleteData(name); // 여기서 'name'을 사용하여 삭제
                                            await myCollectionName(); // 화면을 갱신합니다.
                                            Navigator.of(context).pop(); // 다이얼로그 닫기
                                          },
                                          child: const Text(
                                            '예',
                                            style: TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),


                            ReorderableDragStartListener(
                              index: collectionNames.indexOf(name),
                              child: Container(
                                padding: const EdgeInsets.all(3.0),
                                child: Icon(
                                  Icons.drag_handle,
                                  size: 30.0,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
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
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Container(
              width: 170.0,
              height: 56.0,
              child: FloatingActionButton.extended(
                heroTag: null,
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
              width: 170.0,
              height: 56.0,
              child: FloatingActionButton.extended(
                heroTag: null,
                onPressed: () async {
                  try {
                    await saveUserLocationAndState(uid!); // 현재 위치 저장
                    print("운동 상태와 위치 저장 완료!");
                  } catch (e) {
                    print("위치 저장 중 오류: $e");
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlayMyRoutinePage(
                        clickroutinename: widget.clickroutinename,
                      ),
                    ),
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
