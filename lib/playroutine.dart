import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:health/main.dart';
import 'startroutinename_play.dart';
import 'package:intl/intl.dart';

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

  @override
  void initState() {
    super.initState();
    myCollectionName();
    totalRoutineReps();
    _startTimer();
  }

  int _seconds = 0;
  late Timer _timer;

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
      });
    });
  }

  String _formatTime(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void saveRoutineName(
      int result, int sumweight, int timerSeconds, String _title) async {
    // 완료된 값 저장하는 함수
    var db = FirebaseFirestore.instance;
    String currentTime = DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      // health 문서 아래에 timestamp 컬렉션을 생성하고 새로운 문서를 추가합니다.
      await db
          .collection('Calender')
          .doc('health')
          .collection(currentTime)
          .add({
        '오늘 한 루틴이름': _title,
        '오늘 총 세트수': result,
        '오늘 총 볼륨': sumweight,
        '오늘 총 시간': _formatTime(timerSeconds),
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding document: $e');
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

  void totalRoutineReps() async {
    try {
      // 내루틴 가져오기
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Routine')
          .doc('Myroutine')
          .collection(widget.clickroutinename)
          .get();

      int totalExercises = 0;
      int totalWeight = 0;

      for (var doc in querySnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('exercises')) {
          exercisesData = List<Map<String, dynamic>>.from(data['exercises']
              .map((exercise) => {
                    'reps': exercise['reps'],
                    'weight': exercise['weight'],
                  })
              .toList());

          totalExercises += exercisesData.length;

          for (var exercise in exercisesData) {
            // weight 값을 안전하게 변환
            int weight = 0;
            if (exercise['weight'] is int) {
              weight = exercise['weight'];
            } else if (exercise['weight'] is String) {
              weight = int.tryParse(exercise['weight']) ?? 0;
            }
            totalWeight += weight;
          }
        }
      }
      print(totalWeight);
      setState(() {
        result = totalExercises;
        sumweight = totalWeight;
      });
    } catch (e) {
      print('Error fetching document data: $e');
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
        actions: [
          ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('진짜 종료하시겠습니까?'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // 팝업창 닫기
                        },
                        child: Text('아니요'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const Homepage()),
                          );
                        },
                        child: Text('예'),
                      ),
                    ],
                  );
                },
              );
            },
            child: Text(
              '종료',
              style: TextStyle(color: Colors.red), // 텍스트 색상 설정
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Flexible(
            flex: 3,
            child: Container(
              color: Colors.grey, // 상단 컨테이너 색상
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start, // 세로 상단 정렬
                crossAxisAlignment: CrossAxisAlignment.center, // 가로 중앙 정렬
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0), // 상단 여백 추가
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center, // 가로 중앙 정렬
                      children: [
                        Text(
                          '운동 시간: ',
                          style: TextStyle(fontSize: 24, color: Colors.white),
                        ),
                        Text(
                          _formatTime(_seconds),
                          style: TextStyle(fontSize: 24, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20), // 간격 추가
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceEvenly, // 가로 균등 정렬
                    children: [
                      Text(
                        '오늘 총 세트수: $result', // 예시 텍스트
                        style: TextStyle(fontSize: 24, color: Colors.white),
                      ),
                      Text(
                        '오늘 총 볼륨: $sumweight', // 예시 텍스트
                        style: TextStyle(fontSize: 24, color: Colors.white),
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
                              padding: EdgeInsets.all(30.0),
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
                                  builder: (context) => StartRoutineNamePlay(
                                    currentroutinename: _title,
                                    clickroutinename: collectionNames[index],
                                  ),
                                ),
                              );
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment
                                  .spaceBetween, // 아이템 간의 공간을 최대화
                              children: [
                                Text(
                                  collectionNames[index],
                                  style: TextStyle(
                                      fontSize: 18.0, color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Color.fromARGB(241, 34, 30, 30),
        child: Container(
          width: 170.0, // 원하는 너비로 설정
          height: 56.0, // 원하는 높이로 설정
          child: FloatingActionButton.extended(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('운동을 종료하시겠습니까?'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // 팝업창 닫기
                        },
                        child: Text('아니요'),
                      ),
                      TextButton(
                        onPressed: () {
                          saveRoutineName(result, sumweight, _seconds, _title);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const Homepage()),
                          );
                        },
                        child: Text('예'),
                      ),
                    ],
                  );
                },
              );
            },
            icon: Icon(
              Icons.mood,
              color: Colors.white,
            ),
            label: Text(
              "완료",
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Color.fromARGB(255, 180, 34, 34),
          ),
        ),
      ),
    );
  }
}
