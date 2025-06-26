//루틴 이름 생성 -> 세로운 루틴 생성

import 'package:flutter/material.dart';
import 'create_routine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoutinePage extends StatefulWidget {
  const RoutinePage({super.key});

  @override
  State<RoutinePage> createState() => _RoutinePageState();
}

class _RoutinePageState extends State<RoutinePage>
    with SingleTickerProviderStateMixin {
  TextEditingController nameController = TextEditingController();
  String _title = '';
  List<String> collectionNames = [];
  late AnimationController _controller;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? uid;
  String? errorMessage;


  @override
  void initState() {
    super.initState();
    uid = Provider.of<UserProvider>(context, listen: false).uid;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showNameInputDialog(context);
    });
    myCollectionName();
  }

  @override
  void dispose() {
    nameController.dispose();
    _controller.dispose();
    super.dispose();
  }





  Future<void> saveRoutineName() async {
    final db = FirebaseFirestore.instance;

    try {
      final docRef = db
          .collection('users')
          .doc(uid)
          .collection('Routine')
          .doc('Routinename');

      final snapshot = await docRef.get();

      List<String> names = [];

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        names = List<String>.from(data['names'] ?? []);
      }

      // 🔍 widget.myroutinename과 -기준 앞부분이 같은 게 있는지 확인
      final hasSameBase = names.any((name) {
        final parts = name.split('-');
        return parts.length > 1 && parts.first == _title;
      });

      if (hasSameBase) {
        print('같은 루틴 이름이 이미 존재하므로 저장하지 않음');
        return;
      }

      // 전체 루틴 이름 중 가장 큰 인덱스를 찾기
      int nextIndex = 1;
      final regExp = RegExp(r'-(\d+)$');
      for (final key in names) {
        final match = regExp.firstMatch(key);
        if (match != null) {
          final number = int.tryParse(match.group(1) ?? '');
          if (number != null && number >= nextIndex) {
            nextIndex = number + 1;
          }
        }
      }

      // 새 루틴 키 생성
      final newKey = '${_title}-$nextIndex';

      names.add(newKey);
      await docRef.set({'names': names}, SetOptions(merge: true));
      print('$newKey 루틴 저장 완료');
    } catch (e) {
      print('Error saving routine: $e');
    }
  }

  Future<void> saveRoutineData() async {
    var db = FirebaseFirestore.instance;

    try {
      DocumentReference myRoutineRef = db
          .collection('users')
          .doc(uid)
          .collection('Routine')
          .doc('Myroutine');
      // 🛑 먼저 동일한 루틴 이름이 이미 존재하는지 확인
      final snapshot = await myRoutineRef.get();
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        if (data.containsKey(_title)) {
          // 이미 존재하면 예외를 던져서 catch로 이동
          throw Exception('이미 존재하는 루틴입니다');
        }
      }

      await myRoutineRef.set({_title: []}, SetOptions(merge: true));
      await saveRoutineName();

      final orderRef = db
          .collection('users')
          .doc(uid)
          .collection('Routine')
          .doc('RoutineOrder');

      final orderSnap = await orderRef.get();
      List<String> orderTitles = [];

      if (orderSnap.exists) {
        orderTitles = List<String>.from(orderSnap['titles'] ?? []);
      }

      if (!orderTitles.contains(_title)) {
        orderTitles.add(_title);
        await orderRef.set({'titles': orderTitles}, SetOptions(merge: true));
        print('Order 문서에 루틴 순서 추가됨');
      } else {
        print('Order 문서에 이미 존재하는 루틴입니다');
      }
    } catch (e) {
      print('Error adding document: $e');
    }
  }

  //저장한 루틴세부 이름들을 가져오는 함수(예:턱걸이, 바벨로우)
  Future<List<String>> _getRoutineDetails() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snap = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("Routine")
        .doc("Routinename")
        .get();

    if (snap.exists && snap.data()!.containsKey('details')) {
      return List<String>.from(snap['details']);
    }
    return [];
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
          int routineIndex = myRoutineList
              .indexWhere((routine) => routine.containsKey(routineTitle));

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

  Future<void> deleteAllData(String title) async {
    final firestore = FirebaseFirestore.instance;

    try {
      // 1. Myroutine 문서에서 삭제
      DocumentReference myroutineRef = firestore
          .collection('users')
          .doc(uid)
          .collection('Routine')
          .doc('Myroutine');

      DocumentSnapshot myroutineSnap = await myroutineRef.get();
      if (myroutineSnap.exists) {
        Map<String, dynamic> data =
            myroutineSnap.data() as Map<String, dynamic>;
        if (data.containsKey(title)) {
          data.remove(title);
          await myroutineRef.set(data);
        }
      }

      // 2. RoutineOrder 문서에서 삭제
      DocumentReference orderRef = firestore
          .collection('users')
          .doc(uid)
          .collection('Routine')
          .doc('RoutineOrder');

      DocumentSnapshot orderSnap = await orderRef.get();
      if (orderSnap.exists) {
        List<String> titles = List<String>.from(orderSnap['titles']);
        titles.remove(title);
        await orderRef.update({'titles': titles});
      }

      // 3. Routinename 문서에서 삭제
      DocumentReference nameRef = firestore
          .collection('users')
          .doc(uid)
          .collection('Routine')
          .doc('Routinename');

      DocumentSnapshot nameSnap = await nameRef.get();
      if (nameSnap.exists) {
        List<String> names = List<String>.from(nameSnap['names']);
        names.removeWhere((name) => name.startsWith('$title-'));
        await nameRef.update({'names': names});
      }

      // 로컬 상태 업데이트
      await myCollectionName();
    } catch (e) {
      print('❌ deleteAllData 오류: $e');
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

          setState(() {
            collectionNames = names;
          });
        }
      }
    } catch (e) {
      print('Error fetching collection names: $e');
    }
  }

  void _showNameInputDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.cyan.shade900,
              title: Text(
                '루틴 이름 생성',
                style: TextStyle(color: Colors.white),
              ),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: "이름을 입력하세요",
                        hintStyle: TextStyle(color: Colors.grey),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                        ),
                        fillColor: Colors.white,
                        filled: true,
                        errorText: errorMessage,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '이름을 입력해주세요';
                        }
                        return null;
                      },
                    ),
                    if (errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          errorMessage!,
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                  ],
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
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text(
                    '확인',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () async {
                    final inputTitle = nameController.text.trim();
                    if (inputTitle.isEmpty) {
                      setStateDialog(() {
                        errorMessage = '이름을 입력해주세요';
                      });
                      return;
                    }

                    final db = FirebaseFirestore.instance;
                    final myRoutineRef = db
                        .collection('users')
                        .doc(uid)
                        .collection('Routine')
                        .doc('Myroutine');

                    final snapshot = await myRoutineRef.get();
                    if (snapshot.exists) {
                      final data = snapshot.data() as Map<String, dynamic>;
                      if (data.containsKey(inputTitle)) {
                        setStateDialog(() {
                          errorMessage = '이미 존재하는 이름입니다';
                        });
                        return;
                      }
                    }

                    setState(() {
                      _title = inputTitle;
                      errorMessage = null;
                    });
                    await saveRoutineData();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Hero(
          tag: 'routine',
          child: Text(
            _title,
            style: TextStyle(
              color: Colors.white,
            ),
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
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('생성을 종료하시겠습니까?',
                      style: TextStyle(color: Colors.white)),
                  backgroundColor: Colors.cyan.shade900,
                  actions: <Widget>[
                    TextButton(
                      child: Text('아니오', style: TextStyle(color: Colors.white)),
                      onPressed: () {
                        Navigator.of(context).pop(); // 팝업 닫기
                      },
                    ),
                    TextButton(
                      child: Text('예', style: TextStyle(color: Colors.white)),
                      onPressed: () {
                        deleteAllData(_title).then((_) {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        });
                      },
                    ),
                  ],
                );
              },
            );
          },
        ),
        actions: [
          Row(
            children: [
              // IconButton(
              //   icon: Icon(
              //     Icons.edit,
              //     color: Colors.white,
              //   ),
              //   onPressed: () {
              //     _showNameInputDialog(context);
              //   },
              // ),
              IconButton(
                  icon: Icon(
                    Icons.save,
                    color: Colors.white,
                  ),
                  onPressed: () async {
                    if (collectionNames.isEmpty) {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('아무 값이 없습니다. 생성을 안할겁니까?',
                                style: TextStyle(color: Colors.white)),
                            backgroundColor: Colors.cyan.shade900,
                            actions: <Widget>[
                              TextButton(
                                child: Text('아니오',
                                    style: TextStyle(color: Colors.white)),
                                onPressed: () {
                                  Navigator.of(context).pop(); // 다이얼로그 닫기
                                },
                              ),
                              TextButton(
                                child: Text('예',
                                    style: TextStyle(color: Colors.white)),
                                onPressed: () async {
                                  await deleteAllData(_title);
                                  Navigator.of(context).pop(); // 다이얼로그 닫기
                                  Navigator.of(context).pop(); // RoutinePage 닫기
                                },
                              ),
                            ],
                          );
                        },
                      );
                    } else {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('저장하시겠습니까?',
                                style: TextStyle(color: Colors.white)),
                            backgroundColor: Colors.cyan.shade900,
                            actions: <Widget>[
                              TextButton(
                                child: Text('아니오',
                                    style: TextStyle(color: Colors.white)),
                                onPressed: () {
                                  Navigator.of(context).pop(); // 다이얼로그 닫기
                                },
                              ),
                              TextButton(
                                child: Text('예',
                                    style: TextStyle(color: Colors.white)),
                                onPressed: () {
                                  Navigator.of(context).pop(); // 다이얼로그 닫기
                                  Navigator.of(context)
                                      .pop(true); // 이전 페이지로 값 전달
                                },
                              ),
                            ],
                          );
                        },
                      );
                    }
                  }),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.blueGrey.shade900,
          boxShadow: [
            BoxShadow(
              color: Colors.black,
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
          padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 30.0),
          onReorder: (int oldIndex, int newIndex) {
            setState(() {
              if (newIndex > oldIndex) {
                newIndex -= 1;
              }
              final String item = collectionNames.removeAt(oldIndex);
              collectionNames.insert(newIndex, item);
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
            for (int index = 0; index < collectionNames.length; index++)
              Padding(
                key: ValueKey(collectionNames[index]),
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.all(25.0),
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
                                clickroutinename: collectionNames[index],
                              ),
                            ),
                          ).then((value) {
                            if (value == true) {
                              myCollectionName();
                            }
                          });
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
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
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Add some space between the buttons
          FloatingActionButton.extended(
            heroTag: null,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text("루틴 추가", style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.cyan.shade700,
            onPressed: () async {
              /// 다이얼로그 열기 전에 Firestore 데이터 가져옴
              final routineList = await _getRoutineDetails();
              List<String> filteredRoutineList = List.from(routineList);
              String searchQuery = '';

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) {
                  return StatefulBuilder(
                    // → setState() 로 리스트 즉시 갱신하기 위함
                    builder: (ctx, setStateDialog) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      backgroundColor: Colors.blueGrey.shade200,
                      title: Text(
                        "내 루틴 목록",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.blueGrey.shade800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      content: ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: 400),
                        child: Column(children: [
                          // ✅ 검색창 추가
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: '루틴 이름 검색...',
                                prefixIcon: Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onChanged: (query) {
                                setStateDialog(() {
                                  searchQuery = query.trim();
                                  filteredRoutineList = routineList
                                      .where((name) => name
                                          .toLowerCase()
                                          .contains(searchQuery.toLowerCase()))
                                      .toList();
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: filteredRoutineList.map((name) {
                                  return Card(
                                    elevation: 3,
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 6),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 10),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              name,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.blueGrey.shade900,
                                              ),
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: Icon(Icons.add,
                                                    color: Colors.green),
                                                onPressed: () async {
                                                  final routineName =
                                                      name; // 예: '턱걸이', '바벨로우'

                                                  final db = FirebaseFirestore
                                                      .instance;
                                                  final myRoutineRef = db
                                                      .collection('users')
                                                      .doc(uid)
                                                      .collection('Routine')
                                                      .doc('Myroutine');

                                                  final snapshot =
                                                      await myRoutineRef.get();

                                                  Map<String, dynamic> data =
                                                      {};
                                                  if (snapshot.exists) {
                                                    data = snapshot.data()
                                                        as Map<String, dynamic>;
                                                  }

                                                  // 기존 루틴이 있는지 확인하고 불러오기
                                                  List<dynamic> myRoutineList =
                                                      [];
                                                  if (data
                                                      .containsKey(_title)) {
                                                    myRoutineList =
                                                        List<dynamic>.from(
                                                            data[_title]);
                                                  }
                                                  final exists = myRoutineList.any((element) {
                                                    return element.containsKey(routineName);
                                                  });

                                                  if (exists) {
                                                    print('⚠️ "$routineName" 이미 존재합니다.');
                                                    showDialog(
                                                      context: context,
                                                      builder: (context) => AlertDialog(
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(20),
                                                        ),
                                                        backgroundColor: Colors.white,
                                                        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                                                        content: Column(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            Icon(Icons.warning_amber_rounded, size: 40, color: Colors.redAccent),
                                                            SizedBox(height: 12),
                                                            Text(
                                                              '이미 추가된 루틴입니다',
                                                              style: TextStyle(
                                                                fontSize: 16,
                                                                fontWeight: FontWeight.bold,
                                                                color: Colors.black87,
                                                              ),
                                                              textAlign: TextAlign.center,
                                                            ),
                                                            SizedBox(height: 6),
                                                            Text(
                                                              '"$routineName"',
                                                              style: TextStyle(
                                                                fontSize: 14,
                                                                color: Colors.black54,
                                                              ),
                                                              textAlign: TextAlign.center,
                                                            ),
                                                          ],
                                                        ),
                                                        actionsAlignment: MainAxisAlignment.center,
                                                        actions: [
                                                          ElevatedButton(
                                                            onPressed: () => Navigator.of(context).pop(),
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor: Colors.redAccent,
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius.circular(12),
                                                              ),
                                                            ),
                                                            child: Text('확인', style: TextStyle(color: Colors.white)),
                                                          ),
                                                        ],
                                                      ),
                                                    );

                                                    return;
                                                  }


                                                  // 새로운 루틴 항목 추가 (reps, weight 빈값)
                                                  myRoutineList.add({
                                                    routineName: {
                                                      "exercises": [
                                                        {
                                                          "reps": "",
                                                          "weight": ""
                                                        }
                                                      ]
                                                    }
                                                  });

                                                  // Firestore에 반영
                                                  await myRoutineRef.set(
                                                      {_title: myRoutineList},
                                                      SetOptions(merge: true));

                                                  // UI 갱신
                                                  await myCollectionName();

                                                  print(
                                                      '✅ 루틴 "$routineName" 이(가) 추가되었습니다.');
                                                },
                                              ),
                                              IconButton(
                                                icon: Icon(Icons.delete,
                                                    color: Colors.red),
                                                onPressed: () async {
                                                  final uid = FirebaseAuth
                                                      .instance
                                                      .currentUser!
                                                      .uid;
                                                  final docRef =
                                                      FirebaseFirestore.instance
                                                          .collection("users")
                                                          .doc(uid)
                                                          .collection("Routine")
                                                          .doc("Routinename");

                                                  await docRef.update({
                                                    "details":
                                                        FieldValue.arrayRemove(
                                                            [name])
                                                  });

                                                  setStateDialog(() {
                                                    routineList.remove(name);
                                                  });
                                                },
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ]),
                      ),
                      actions: [
                        /// ▶ 루틴 이름 입력용 두 번째 다이얼로그
                        TextButton.icon(
                          icon: Icon(Icons.add, color: Colors.white),
                          label: Text("루틴 생성",
                              style: TextStyle(color: Colors.white)),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.cyan.shade700,
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () async {
                            String? errorText; // 에러 메시지 상태
                            final txt = TextEditingController();

                            final result = await showDialog(
                              context: ctx,
                              builder: (_) => StatefulBuilder(
                                builder: (context, setStateDialog) {
                                  return AlertDialog(
                                    backgroundColor: Colors.blueGrey.shade100,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16)),
                                    title: Text(
                                      "새 루틴 이름 입력",
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blueGrey.shade900),
                                    ),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextField(
                                          controller: txt,
                                          decoration: InputDecoration(
                                            hintText: "예) 바벨로우, 턱걸이",
                                            prefixIcon:
                                                Icon(Icons.fitness_center),
                                            errorText: errorText,
                                            // 여기서 에러 메시지 띄움
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                  color:
                                                      Colors.blueGrey.shade700),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                  color: Colors.cyan.shade700),
                                            ),
                                          ),
                                          autofocus: true,
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          backgroundColor:
                                              Colors.blueGrey.shade300,
                                          foregroundColor: Colors.white,
                                        ),
                                        onPressed: () => Navigator.pop(context),
                                        child: Text("취소"),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.cyan.shade700,
                                        ),
                                        child: Text("저장",
                                            style:
                                                TextStyle(color: Colors.white)),
                                        onPressed: () async {
                                          final added = txt.text.trim();

                                          if (added.isEmpty) {
                                            setStateDialog(() =>
                                                errorText = "⚠️ 값을 입력해주세요");
                                            return;
                                          }

                                          if (routineList.contains(added)) {
                                            setStateDialog(() => errorText =
                                                "⚠️ 같은 이름의 루틴이 존재합니다");
                                            return;
                                          }

                                          // Firestore에 저장
                                          final uid = FirebaseAuth
                                              .instance.currentUser!.uid;
                                          final docRef = FirebaseFirestore
                                              .instance
                                              .collection("users")
                                              .doc(uid)
                                              .collection("Routine")
                                              .doc("Routinename");

                                          await docRef.set(
                                            {
                                              "details":
                                                  FieldValue.arrayUnion([added])
                                            },
                                            SetOptions(merge: true),
                                          );

                                          setStateDialog(() {
                                            routineList.add(added);
                                          });
                                          Navigator.pop(context, true);
                                          // 성공 시 닫기
                                        },
                                      ),
                                    ],
                                  );
                                },
                              ),
                            );
                            if (result == true) {
                              final updatedList = await _getRoutineDetails();
                              setStateDialog(() {
                                routineList.clear();
                                routineList.addAll(updatedList);
                              });
                            }
                          },
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.blueGrey.shade300,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child:
                              Text("닫기", style: TextStyle(color: Colors.black)),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
