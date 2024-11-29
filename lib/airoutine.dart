import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_provider.dart';
import 'package:provider/provider.dart';
import 'main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

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
  bool _showPopup = true;
  late VideoPlayerController _videoController;

  @override
  void dispose() {
    _controller.dispose();
    _videoController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    uid = Provider.of<UserProvider>(context, listen: false).uid;
    _initializeVideo();
    _checkPopupPreference();
  }

  Future<void> _initializeVideo() async {
    _videoController =
        VideoPlayerController.asset('assets/videos/aiRoutine.mp4');

    try {
      await _videoController.initialize();
      setState(() {});
    } catch (e) {
      print('동영상 초기화 중 오류 발생: $e');
    }
  }

  Future<void> _checkPopupPreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _showPopup = prefs.getBool('showPopup') ?? true;
    });

    if (_showPopup) {
      WidgetsBinding.instance.addPostFrameCallback((_) async{
        if (!_videoController.value.isInitialized) {
          await _initializeVideo();
        }
        _showVideoPopup();
      });
    }
  }

  Future<void> _setPopupPreference(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('showPopup', value);
  }

  void _showVideoPopup() async{
    if (!_videoController.value.isInitialized) {
      try {
        await _videoController.initialize();
        setState(() {}); // UI 갱신
      } catch (e) {
        print('동영상 초기화 중 오류 발생: $e');
      }
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            '자동 생성 안내',
            style:
                TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
          ),
          backgroundColor: Colors.grey.shade900,
          // 바탕화면 색상 설정
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15), // 모서리를 둥글게 설정
            side: BorderSide(color: Colors.blueGrey, width: 2), // 테두리 색상과 두께 설정
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: _videoController.value.isInitialized
                    ? _videoController.value.aspectRatio
                    : 16 / 9,
                child: _videoController.value.isInitialized
                    ? VideoPlayer(_videoController)
                    : Center(child: CircularProgressIndicator()),
              ),
              SizedBox(height: 16),
            ],
          ),
          actions: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red),
                // Border color for '취소' button
                borderRadius:
                    BorderRadius.circular(8), // Optional: Rounded corners
              ),
              child: TextButton(
                child: Text('더 이상 보지 않기', style: TextStyle(color: Colors.red)),
                onPressed: () {
                  _setPopupPreference(false);
                  Navigator.of(context).pop();
                },
              ),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red),
                // Border color for '취소' button
                borderRadius:
                    BorderRadius.circular(8), // Optional: Rounded corners
              ),
              child: TextButton(
                child: Text('닫기', style: TextStyle(color: Colors.green)),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        );
      },
    );
    _videoController.setPlaybackSpeed(2);
    _videoController.play(); // 팝업 표시 시 자동 재생
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
            int exerciseIndex =
                myRoutineList.indexWhere((e) => e.containsKey(exercise));

            if (exerciseIndex != -1) {
              // 종목이 이미 있는 경우 병합
              myRoutineList[exerciseIndex][exercise]["exercises"].addAll(sets);
            } else {
              // 새로운 종목 추가
              myRoutineList.add({
                exercise: {"exercises": sets}
              });
            }
          });

          await myRoutineRef.update(
              {widget.myroutinename: existingData[widget.myroutinename]});
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
    String input = _controller.text.trim(); //사용자 입력 데이터
    List<String> lines = input.split('\n'); // 입력 데이터를 줄 단위로 자르기
    String? currentExercise; // 현재 운동 이름
    routineData = {}; // 운동 종목을 비우고 새로 추가

    for (String line in lines) {
      line = line.trim(); //각 줄의 공복 제거

      // 만약 "kg"가 포함된 경우 무게와 반복 횟수로 인식
      if (RegExp(r'\d+kg \d+').hasMatch(line)) {
        // 숫자 1개 이상과 kg로 이루어진 패턴
        if (currentExercise != null) {
          // 현재 처리중인 운동이 있는 경우
          List<String> parts = line.split(' '); // 공백을 기준으로 나눈후 parts에 저장
          for (int i = 0; i < parts.length; i++) {
            print(parts[i]);
            print("dd");
          }

          // 반복적으로 kg과 reps를 처리
          for (int i = 0; i < parts.length; i++) {
            if (parts[i].contains('kg')) {
              // 'kg' 포함 여부 확인
              String weight = parts[i].replaceAll('kg', ''); // 중량 추출

              // 'kg' 이후의 반복 횟수 전부 추가
              for (int j = i + 1;
                  j < parts.length && !parts[j].contains('kg');
                  j++) {
                String reps = parts[j]; // 반복 횟수 추출

                // currentExercise에 데이터 추가
                if (routineData[currentExercise] == null) {
                  routineData[currentExercise] = [];
                }

                routineData[currentExercise]?.add({
                  'weight': weight,
                  'reps': reps,
                });
              }
            }
          }
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
          title: Text(
            '입력한 루틴 정보',
            style:
                TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: routineData.entries.map((entry) {
                String exercise = entry.key;
                List<Map<String, String>> sets = entry.value;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.cyan,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...sets.map((set) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blueGrey.withOpacity(0.2),
                                blurRadius: 4,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Text(
                            'Weight: ${set['weight']}kg, Reps: ${set['reps']}',
                            style:
                                TextStyle(fontSize: 16, color: Colors.black87),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                );
              }).toList(),
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
                '저장',
                style: TextStyle(color: Colors.green),
              ),
              onPressed: () async {
                // 루틴 데이터를 저장
                await saveRoutineData();
                // 첫 번째 팝업 닫기
                Navigator.of(context).pop();
                // 두 번째 화면 닫기 (true 반환)
                if (mounted) {
                  Navigator.of(context).pop(true);
                }
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
        title: Text('루틴 생성', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueGrey.shade700,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue),
              // Border color for '취소' button
              borderRadius:
                  BorderRadius.circular(8), // Optional: Rounded corners
            ),
            child: TextButton(
              child: Text(
                '설명서',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                _showVideoPopup(); // 설명서 버튼을 누르면 비디오 팝업 호출
              },
            ),
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  maxLines: null, // 여러 줄 입력 가능
                  decoration: InputDecoration(
                    hintText:
                        '운동 이름과 중량, 개수를 입력하세요\n예시:\n덤벨로우\n30kg 3\n턱걸이\n40kg 5',
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
                child: Text('입력 내용 확인', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan.shade700,
                  padding:
                      EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
