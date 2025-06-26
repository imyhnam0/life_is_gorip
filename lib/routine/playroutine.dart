//운동시작을 눌렀을때 나오는 페이지 운동시작 시간이 상단에 떠있음

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'startroutinename_play.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../services/user_provider.dart';
import 'package:provider/provider.dart';
import 'create_routine.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PlayMyRoutinePage extends StatefulWidget {
  final String clickroutinename;
  const PlayMyRoutinePage({Key? key, required this.clickroutinename});

  @override
  State<PlayMyRoutinePage> createState() => _PlayMyRoutinePageState();
}

class _PlayMyRoutinePageState extends State<PlayMyRoutinePage> {
  TextEditingController nameController = TextEditingController();
  late String _title = widget.clickroutinename;
  List<String> collectionNames = [];
  List<Map<String, dynamic>> exercisesData = [];
  int result = 0;
  int sumweight = 0;
  String? uid;
  List<bool> completionStatus = [];
  int totalWeight = 0; // 총 무게 상태 변수 추가
  int totalRows = 0; // 총 행 수 상태 변수 추가
  String? _entryTime;

  void _setEntryTime() {
    final now = DateTime.now();
    _entryTime = DateFormat('HH:mm').format(now);
  }

  @override
  void initState() {
    super.initState();
    uid = Provider.of<UserProvider>(context, listen: false).uid;
    myCollectionName();
    totalRoutineReps();
    _setEntryTime();

  }
  Future<void> _clearCheckedStates() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear(); // 모든 SharedPreferences 값 초기화
}



  @override

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

  Future<void> saveSubroutineOrder(List<String> orderedNames) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('Routine')
          .doc('Myroutine');

      final snapshot = await docRef.get();
      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        if (data.containsKey(_title)) {
          List<dynamic> originalList = data[_title];
          List<dynamic> reorderedList = [];

          for (String name in orderedNames) {
            final item = originalList.firstWhere((element) => element.containsKey(name));
            reorderedList.add(item);
          }

          await docRef.update({_title: reorderedList});
        }
      }
    } catch (e) {
      print('⚠️ Error saving subroutine order: $e');
    }
  }






  Future<void> _clearTitleAndTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('title');
    await prefs.remove('savedTime');
  }



  String _formatTime(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }



  Future<void> saveRoutine(
      String title,
      int result,
      int sumweight,
      List<Map<String, dynamic>> exerciseLogs,
      String endTime,
      ) async {
    final DateTime now = DateTime.now();
    final String formattedDate = DateFormat('yyyy-MM-dd').format(now);
    final db = FirebaseFirestore.instance;
    final batch = db.batch(); // Batch 쓰기 시작

    try {
      final healthDocRef =
          db.collection('users').doc(uid).collection('Calender').doc('health');

      // 새로운 문서 ID 생성
      final routineDocRef = healthDocRef.collection('routines').doc('${formattedDate}_$title');
      // 🔍 "등-3" 형식의 값에서 title == "등" 인 항목 찾기
      final routinenameDoc = await db
          .collection('users')
          .doc(uid)
          .collection('Routine')
          .doc('Routinename')
          .get();

      List<dynamic> names = routinenameDoc.data()?['names'] ?? [];
      int indexToSave = -1;

      for (var name in names) {
        if (name is String && name.startsWith('$title-')) {
          final parts = name.split('-');
          if (parts.length == 2) {
            indexToSave = int.tryParse(parts[1]) ?? -1;
            break;
          }
        }
      }

      batch.set(routineDocRef, {
        '오늘 한 루틴이름': title,
        '루틴 인덱스': indexToSave,
        '오늘 총 세트수': result,
        '오늘 총 볼륨': sumweight,
        '날짜': formattedDate,
        '운동 시작 시간': _entryTime,
        '운동 종료 시간': endTime,
        '운동 목록': exerciseLogs,
      });

      await batch.commit(); // Batch 쓰기 커밋
    } catch (e) {
      print('Error adding document: $e');
    }
  }

  Future<void> myCollectionName() async {
    try {
      // Firestore에서 데이터를 가져옵니다.
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('Routine')
          .doc('Myroutine')
          .get();

      // 문서가 존재하는지 확인합니다.
      if (documentSnapshot.exists) {
        var data = documentSnapshot.data() as Map<String, dynamic>;

        // _title이 키로 존재하는지 확인합니다.
        if (data.containsKey(widget.clickroutinename)) {
          List<dynamic> myRoutineList = data[widget.clickroutinename];

          List<String> names = [];
          // 각 루틴을 순회하며 키 값을 가져옵니다.
          for (var routine in myRoutineList) {
            if (routine is Map<String, dynamic>) {
              routine.forEach((key, value) {
                names.add(key);
              });
            }
          }

          final prefs = await SharedPreferences.getInstance();
          List<String>? savedNames =
              prefs.getStringList('$_title-collectionNames');

          if (savedNames != null &&
              savedNames.length == names.length &&
              savedNames.every((element) => names.contains(element))) {
            names = savedNames;
          } else {
            prefs.setStringList('$_title-collectionNames', names);
          }

          // 상태를 업데이트합니다.
          setState(() {
            collectionNames = names;
            completionStatus = List<bool>.filled(names.length, false);
          });
        }
      }
    } catch (e) {
      // 에러 발생 시 콘솔에 출력합니다.
      print('Error fetching collection names: $e');
    }
  }

  Future<void> totalRoutineReps() async {
    try {
      // Firestore에서 데이터를 가져옵니다.
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('Routine')
          .doc('Myroutine')
          .get();

      int tempTotalWeight = 0;
      int tempTotalRows = 0; // 총 행 수를 저장할 변수

      // 문서가 존재하는지 확인합니다.
      if (documentSnapshot.exists) {
        var data = documentSnapshot.data() as Map<String, dynamic>;

        // _title이 키로 존재하는지 확인합니다.
        if (data.containsKey(widget.clickroutinename)) {
          List<dynamic> myRoutineList = data[widget.clickroutinename];

          for (var routine in myRoutineList) {
            if (routine is Map<String, dynamic>) {
              routine.forEach((key, value) {
                if (value.containsKey('exercises')) {
                  List<Map<String, dynamic>> exercises =
                      List<Map<String, dynamic>>.from(value['exercises']
                          .map((exercise) => {
                                'reps': exercise['reps'],
                                'weight': exercise['weight'],
                              })
                          .toList());

                  tempTotalRows += exercises.length; // 총 행 수를 더합니다.

                  for (var exercise in exercises) {
                    int weight = 0;
                    int reps = 0;

                    if (exercise['weight'] is int) {
                      weight = exercise['weight'];
                    } else if (exercise['weight'] is String) {
                      weight = int.tryParse(exercise['weight']) ?? 0;
                    }

                    if (exercise['reps'] is int) {
                      reps = exercise['reps'];
                    } else if (exercise['reps'] is String) {
                      reps = int.tryParse(exercise['reps']) ?? 0;
                    }

                    tempTotalWeight += weight * reps;
                  }
                }
              });
            }
          }
        }
      }

      setState(() {
        totalWeight = tempTotalWeight;
        totalRows = tempTotalRows;
      });
      // 결과 출력
      print('Total weight: $totalWeight');
      print('Total rows: $totalRows'); // 총 행 수를 출력합니다.
    } catch (e) {
      // 에러 발생 시 콘솔에 출력합니다.
      print('Error fetching routine stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Oswald',
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueGrey.shade900,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
            size: 28,
          ),
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  backgroundColor: Colors.blueGrey.shade800,
                  title: const Text(
                    '진짜 종료하시겠습니까?',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: const Text(
                    '운동을 종료하면 모든 진행 상황이 저장되지 않습니다. 계속하시겠습니까?',
                    style: TextStyle(color: Colors.white),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        '아니요',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final FirebaseFirestore firestore = FirebaseFirestore.instance;
                        try {
                          // Firestore에서 해당 사용자의 문서를 업데이트합니다.
                          await firestore.collection('users').doc(uid).update({
                            'isExercising': false, // isExercising 필드를 true로 설정
                          });

                          print('isExercising updated to true');
                        } catch (e) {
                          print('Error updating isExercising: $e');
                        }
                        await _clearTitleAndTime();
                        await _clearCheckedStates(); // 체크 값 초기화
                        setState(() {
                          totalRows = 0; // 초기화
                          totalWeight = 0; // 초기화
                        });
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (context) => const Homepage()),
                              (route) => false,
                        );
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
          tooltip: '뒤로 가기',
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add,
              color: Colors.white,
              size: 28,
            ),
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
                                                icon: Icon(Icons.delete, color: Colors.red),
                                                onPressed: () async {
                                                  final confirm = await showDialog<bool>(
                                                    context: context,
                                                    builder: (context) {
                                                      return AlertDialog(
                                                        backgroundColor: Colors.white,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(16),
                                                        ),
                                                        title: Text(
                                                          '정말 삭제하시겠습니까?',
                                                          style: TextStyle(fontWeight: FontWeight.bold),
                                                        ),
                                                        content: Text('"$name" 루틴을 삭제하면 되돌릴 수 없습니다.'),
                                                        actions: [
                                                          TextButton(
                                                            child: Text('아니오', style: TextStyle(color: Colors.grey)),
                                                            onPressed: () => Navigator.of(context).pop(false),
                                                          ),
                                                          ElevatedButton(
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor: Colors.redAccent,
                                                            ),
                                                            child: Text('예', style: TextStyle(color: Colors.white)),
                                                            onPressed: () => Navigator.of(context).pop(true),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  );

                                                  if (confirm == true) {
                                                    final uid = FirebaseAuth.instance.currentUser!.uid;
                                                    final docRef = FirebaseFirestore.instance
                                                        .collection("users")
                                                        .doc(uid)
                                                        .collection("Routine")
                                                        .doc("Routinename");

                                                    await docRef.update({
                                                      "details": FieldValue.arrayRemove([name])
                                                    });

                                                    setStateDialog(() {
                                                      routineList.remove(name);
                                                      filteredRoutineList.remove(name);
                                                    });
                                                  }
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
                                            filteredRoutineList.add(added);
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
            tooltip: '편집',
          ),
        ],
      ),
      body: Column(
        children: [
          Flexible(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blueGrey.shade700, Colors.blueGrey.shade900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 7,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: Border.all(
                  color: Colors.blueGrey.shade600,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.timer,
                            color: Colors.cyan.shade300, size: 30),
                        const SizedBox(width: 8),

                        Text(
                          _entryTime != null ? 'START : $_entryTime' : '',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Orbitron', // or BebasNeue
                            color: Colors.cyanAccent,
                            letterSpacing: 1.5,
                            shadows: [
                              Shadow(
                                offset: Offset(1.5, 1.5),
                                blurRadius: 3.0,
                                color: Colors.black.withOpacity(0.7),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Text(
                            'Sets',
                            style: const TextStyle(
                              fontSize: 25,
                              fontFamily: 'Oswald',
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            '$totalRows',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            'Volume',
                            style: const TextStyle(
                              fontSize: 20,
                              fontFamily: 'Oswald',
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            '$totalWeight',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Flexible(
            flex: 7,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade900,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 7,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: Border.all(
                  color: Colors.blueGrey.shade700,
                  width: 2,
                ),
              ),
              child: ReorderableListView(
                children: [
                  for (int index = 0; index < collectionNames.length; index++)
                    Padding(
                      key: ValueKey(collectionNames[index]),
                      padding: const EdgeInsets.symmetric(
                          vertical: 15.0, horizontal: 30.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.all(30.0),
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
                                    builder: (context) => StartRoutineNamePlay(
                                      currentroutinename: _title,
                                      clickroutinename: collectionNames[index],
                                    ),
                                  ),
                                ).then((value) {
                                  if (value == 'not done') {
                                    totalRoutineReps();
                                  } else {
                                    setState(() {
                                      completionStatus[index] = true;
                                      // ✅ 완료된 루틴은 하단으로 보내기 위해 정렬
                                      List<Map<String, dynamic>> zipped = [];
                                      for (int i = 0; i < collectionNames.length; i++) {
                                        zipped.add({
                                          'name': collectionNames[i],
                                          'done': completionStatus[i],
                                        });
                                      }

                                      // 완료된 루틴은 밑으로 정렬
                                      zipped.sort((a, b) {
                                        if (a['done'] == b['done']) return 0;
                                        return a['done'] ? 1 : -1; // done == true 면 뒤로 보냄
                                      });

                                      // 다시 나눠 담기
                                      collectionNames = zipped.map((e) => e['name'] as String).toList();
                                      completionStatus = zipped.map((e) => e['done'] as bool).toList();
                                    });
                                    totalRoutineReps();
                                  }
                                });
                              },
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    collectionNames[index],
                                    style: const TextStyle(
                                      fontSize: 18.0,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Oswald',
                                    ),
                                  ),
                                  if (completionStatus[index])
                                    const Icon(
                                      Icons.check,
                                      color: Colors.green,
                                      size: 28,
                                    ),
                                  Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.white),
                                    onPressed: () async {
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
                                                  await deleteData(collectionNames[index]);
                                                  await myCollectionName(); // 화면을 다시 불러옵니다.
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
                                    index: index,
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
                onReorder: (int oldIndex, int newIndex) async {
                  setState(() {
                    // Make the list mutable
                    List<String> mutableCollectionNames =
                        List.from(collectionNames);
                    List<bool> mutableCompletionStatus =
                        List.from(completionStatus);

                    if (newIndex > oldIndex) {
                      newIndex -= 1;
                    }
                    final item = mutableCollectionNames.removeAt(oldIndex);
                    mutableCollectionNames.insert(newIndex, item);
                    // completionStatus도 같이 업데이트 해야 할 경우 아래 코드를 사용
                    final status = mutableCompletionStatus.removeAt(oldIndex);
                    mutableCompletionStatus.insert(newIndex, status);

                    collectionNames = mutableCollectionNames;
                    completionStatus = mutableCompletionStatus;
                  });
                  await saveSubroutineOrder(collectionNames);
                },
                proxyDecorator:
                    (Widget child, int index, Animation<double> animation) {
                  return Material(
                    color: Colors.transparent, // Material 위젯의 color 속성을 직접 조정
                    child: child,
                    elevation: 0.0,
                  );
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.blueGrey.shade800,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceEvenly, // 버튼들을 가운데 정렬하고 균등하게 배치
            children: [
              FloatingActionButton.extended(
                heroTag: 'finishRoutine',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        backgroundColor: Colors.blueGrey.shade800,
                        title: const Text(
                          '운동을 종료하시겠습니까?',
                          style: TextStyle(color: Colors.white),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text(
                              '아니요',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final FirebaseFirestore firestore = FirebaseFirestore.instance;
                              try {
                                // Firestore에서 해당 사용자의 문서를 업데이트합니다.
                                await firestore.collection('users').doc(uid).update({
                                  'isExercising': false, // isExercising 필드를 true로 설정
                                });

                                print('isExercising updated to true');
                              } catch (e) {
                                print('Error updating isExercising: $e');
                              }
                              final now = DateTime.now();
                              String endTime = DateFormat('HH:mm').format(now);

                              List<Map<String, dynamic>> exerciseLogs = [];

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

                                  for (var routine in myRoutineList) {
                                    if (routine is Map<String, dynamic>) {
                                      routine.forEach((exerciseName, exerciseData) {
                                        if (exerciseData.containsKey('exercises')) {
                                          List<Map<String, dynamic>> sets =
                                          List<Map<String, dynamic>>.from(exerciseData['exercises']);

                                          exerciseLogs.add({
                                            '운동 이름': exerciseName,
                                            '세트': sets, // 세트 전체 저장
                                          });
                                        }
                                      });
                                    }
                                  }
                                }
                              }

                              await saveRoutine(
                                _title,
                                totalRows,
                                totalWeight,
                                exerciseLogs,
                                endTime,
                              );
                              await _clearCheckedStates(); // 체크 값 초기화
                              await _clearTitleAndTime();
                              setState(() {

                                totalRows = 0; // 초기화
                                totalWeight = 0; // 초기화
                              });
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const Homepage()),
                                (route) => false,
                              );
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
                icon: const Icon(
                  Icons.mood,
                  color: Colors.white,
                ),
                label: const Text(
                  "완료",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Oswald',
                  ),
                ),
                backgroundColor: Colors.cyan.shade700,
              ),
              FloatingActionButton.extended(
                heroTag: 'endRoutine',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        backgroundColor: Colors.blueGrey.shade800,
                        title: const Text(
                          '진짜 종료하시겠습니까?',
                          style: TextStyle(color: Colors.white),
                        ),
                        content: const Text(
                          '운동을 종료하면 모든 진행 상황이 저장되지 않습니다. 계속하시겠습니까?',
                          style: TextStyle(color: Colors.white),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text(
                              '아니요',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final FirebaseFirestore firestore = FirebaseFirestore.instance;
                              try {
                                // Firestore에서 해당 사용자의 문서를 업데이트합니다.
                                await firestore.collection('users').doc(uid).update({
                                  'isExercising': false, // isExercising 필드를 true로 설정
                                });

                                print('isExercising updated to true');
                              } catch (e) {
                                print('Error updating isExercising: $e');
                              }
                              await _clearTitleAndTime();
                              await _clearCheckedStates(); // 체크 값 초기화
                              setState(() {

                                totalRows = 0; // 초기화
                                totalWeight = 0; // 초기화
                              });
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                    builder: (context) => const Homepage()),
                                (route) => false,
                              );
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
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                ),
                label: const Text(
                  "종료",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Oswald',
                  ),
                ),
                backgroundColor: Colors.red.shade700, // "종료" 버튼에는 다른 색상을 사용
              ),
            ],
          ),
        ),
      ),
    );
  }
}
