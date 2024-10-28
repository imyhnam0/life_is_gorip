import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_provider.dart';
import 'package:provider/provider.dart';
import 'main.dart';

class Airoutine extends StatefulWidget {
  final String myroutinename;

  const Airoutine({
    Key? key,
    required this.myroutinename,
  }) : super(key: key);

  @override
  _AiroutineState createState() => _AiroutineState();
}

class _AiroutineState extends State<Airoutine> {
  TextEditingController _controller = TextEditingController();
  Map<String, List<Map<String, String>>> routineData = {}; // 여러 운동 종목을 저장할 데이터
  String? uid;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    uid = Provider.of<UserProvider>(context, listen: false).uid;
  }

  // Firestore에 루틴 데이터를 저장하는 함수
  Future<void> saveRoutineData() async {
    var db = FirebaseFirestore.instance;

    if (routineData.isNotEmpty) {
      try {
        DocumentReference myRoutineRef = db
            .collection('users')
            .doc(uid)
            .collection('Routine')
            .doc('Myroutine');

        DocumentSnapshot documentSnapshot = await myRoutineRef.get();

        if (documentSnapshot.exists) {
          var existingData = documentSnapshot.data() as Map<String, dynamic>;

          // 기존 데이터에 새로운 종목 추가 (병합 방식으로)
          routineData.forEach((exercise, sets) {
            if (existingData[widget.myroutinename] == null) {
              existingData[widget.myroutinename] = [];
            }
            // 해당 종목이 있는지 확인하고, 있으면 업데이트, 없으면 새로 추가
            List<dynamic> myRoutineList = existingData[widget.myroutinename];
            int exerciseIndex = myRoutineList.indexWhere((e) => e.containsKey(exercise));

            if (exerciseIndex != -1) {
              // 종목이 이미 있는 경우 병합
              myRoutineList[exerciseIndex][exercise]["exercises"].addAll(sets);
            } else {
              // 새로운 종목 추가
              myRoutineList.add({exercise: {"exercises": sets}});
            }
          });

          await myRoutineRef.update({widget.myroutinename: existingData[widget.myroutinename]});
        } else {
          // 새로운 문서 생성
          await myRoutineRef.set({
            widget.myroutinename: routineData.map((exercise, sets) => MapEntry(
              exercise,
              {"exercises": sets},
            ))
          });
        }

      } catch (e) {
        print('Error saving routine: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('루틴 저장 중 오류가 발생했습니다.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장할 루틴이 없습니다.')),
      );
    }
  }

  // 입력된 텍스트를 분석해서 운동 이름, 중량, 개수를 추출하는 함수
  void _showParsedRoutine(BuildContext context) {
    String input = _controller.text.trim();
    List<String> lines = input.split('\n');

    String? currentExercise; // 현재 운동 이름
    routineData = {}; // 운동 종목을 비우고 새로 추가

    for (String line in lines) {
      line = line.trim();

      // 만약 "kg"가 포함된 경우 무게와 반복 횟수로 인식
      if (RegExp(r'\d+kg \d+').hasMatch(line)) {
        if (currentExercise != null) {
          List<String> parts = line.split(' ');
          String weight = parts[0].replaceAll('kg', ''); // 예: 30kg
          String reps = parts[1]; // 예: 10회

          // 현재 운동 종목에 중량과 반복 횟수 추가
          if (routineData[currentExercise] == null) {
            routineData[currentExercise] = [];
          }

          routineData[currentExercise]?.add({
            'weight': weight,
            'reps': reps,
          });
        }
      }
      // "kg"가 포함되지 않은 경우 운동 이름으로 인식
      else {
        currentExercise = line;
        routineData[currentExercise] = [];
      }
    }

    // 팝업으로 결과 보여주기
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('입력한 루틴 정보'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: routineData.entries.map((entry) {
                String exercise = entry.key;
                List<Map<String, String>> sets = entry.value;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ...sets.map((set) {
                        return Text('weight: ${set['weight']}, reps: ${set['reps']}');
                      }).toList(),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              child: Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
                child: Text('저장'),
                onPressed: () {
                  Navigator.of(context).pop(); // 팝업 닫기
                  saveRoutineData().then((_) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => Homepage()), // Replace MainPage with your main page widget
                    );
                  });
                }
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
        title: Text('루틴 생성', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueGrey.shade700,

        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null, // 여러 줄 입력 가능
                decoration: InputDecoration(
                  hintText: '운동 이름과 중량, 개수를 입력하세요\n예시:\n덤벨로우\n30kg 3\n턱걸이\n40kg 5',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _showParsedRoutine(context);
              },
              child: Text('입력 내용 확인'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan.shade700,
                padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
