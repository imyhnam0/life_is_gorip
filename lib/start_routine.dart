import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'playroutine.dart';
import 'create_routine.dart';
import 'user_provider.dart';
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
    loadSavedCollectionNames(); // 저장된 순서를 불러오기
    myCollectionName();
  }

  Future<void> saveUserLocationAndState(String uid) async {
    try {
      print("1");

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

      print("2");
      print("서비스 활성화 여부: $serviceEnabled");
      print("권한 상태: $permission");

      // 현재 위치 가져오기
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      print("위도: ${position.latitude}");
      print("경도: ${position.longitude}");

      print("3");

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
    print(_title);
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
    DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('Routine')
        .doc('Myroutine')
        .get();

    if (documentSnapshot.exists) {
      var data = documentSnapshot.data() as Map<String, dynamic>;
      if (data.containsKey(_title)) {
        List<dynamic> myRoutineList = data[_title];
        List<String> names = [];
        for (var routine in myRoutineList) {
          routine.forEach((key, value) {
            names.add(key);
          });
        }

        final prefs = await SharedPreferences.getInstance();
        List<String>? savedNames = prefs.getStringList('$_title-collectionNames');

        if (savedNames != null &&
            savedNames.length == names.length &&
            savedNames.every((element) => names.contains(element))) {
          setState(() {
            collectionNames = savedNames;
          });
        } else {
          setState(() {
            collectionNames = names;
          });
          saveCollectionNames(names);
        }
      }
    }
  } catch (e) {
    print('Error fetching collection names: $e');
  }
}

  Future<void> saveCollectionNames(List<String> names) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('$_title-collectionNames', names);

    // 👉 Firestore에도 저장
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


Future<void> loadSavedCollectionNames() async {
  final prefs = await SharedPreferences.getInstance();
  List<String>? savedNames = prefs.getStringList('$_title-collectionNames');
  if (savedNames != null) {
    setState(() {
      collectionNames = savedNames;
    });
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

        // Remove the old title
        await docRef.update({_title: FieldValue.delete()});

        // Add the new title with the same list
        data.remove(_title);
        data[newTitle] = myRoutineList;

        await docRef.set(data, SetOptions(merge: true));
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.cyan.shade900,
          title: const Text(
            '이름 수정',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: nameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "이름을 입력하세요",
              hintStyle: const TextStyle(color: Colors.grey),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
              fillColor: Colors.blueGrey.shade700,
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
     Navigator.pop(context, true);
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
                            if (value == false) {
                              deleteData(name);
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
                              icon: Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                deleteData(name);
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
