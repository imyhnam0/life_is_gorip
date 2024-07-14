import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'user_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StartRoutineNamePlay extends StatefulWidget {
  final String clickroutinename;
  final String currentroutinename;
  const StartRoutineNamePlay(
      {Key? key,
      required this.clickroutinename,
      required this.currentroutinename})
      : super(key: key);

  @override
  _StartRoutineNamePlayState createState() => _StartRoutineNamePlayState();
}

class _StartRoutineNamePlayState extends State<StartRoutineNamePlay> {
  TextEditingController nameController = TextEditingController();
  List<bool> _checkedStates = [];
    void _initializeCheckedStates(int count) {
    _checkedStates = List<bool>.filled(count, false);
  }
   void _handleCheckChanged(int index, bool isChecked) {
    setState(() {
      _checkedStates[index] = isChecked;
    });

    if (_checkedStates.every((checked) => checked)) {
      saveRoutineData();
      Navigator.of(context).pop(true);
    }
  }

  late String _title = widget.clickroutinename;
  List<ExerciseRow> _rows = [];
  List<Map<String, dynamic>> exercisesData = [];
  int _counter = 0;
  int _minutes = 0;
  int _seconds = 0;
  Timer? _timer;
  int _remainingTime = 0;
  String? uid;
  bool _isCountdownActive = false;

  void _startTimer() {
    if (_timer != null) {
      _timer!.cancel();
    }
    setState(() {
      _remainingTime = _minutes * 60 + _seconds;
      _isCountdownActive = false;
    });

     _saveEndTimeToPrefs(_remainingTime);

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
          if (_remainingTime <= 10) {
            _isCountdownActive = true;
          }
        });
      } else {
        setState(() {
        _isCountdownActive = false;
      });
        timer.cancel();
      }
    });
  }

  Future<void> _saveEndTimeToPrefs(int remainingTime) async {
  final prefs = await SharedPreferences.getInstance();
  final DateTime now = DateTime.now();
  final DateTime endTime = now.add(Duration(seconds: remainingTime));
  prefs.setString('endTime', endTime.toIso8601String());
}

  Future<void> _loadEndTimeFromPrefs() async {
  final prefs = await SharedPreferences.getInstance();
  final String? endTimeString = prefs.getString('endTime');

  if (endTimeString != null) {
    final DateTime endTime = DateTime.parse(endTimeString);
    final DateTime now = DateTime.now();
    final int remainingTime = endTime.difference(now).inSeconds;

    if (remainingTime > 0) {
      setState(() {
        _remainingTime = remainingTime;
        _startTimer();
      });
    } else {
      setState(() {
        _remainingTime = 0;
        _isCountdownActive = false;
      });
    }
  }
}



  void _addTextFields() {
    setState(() {
      _counter++;
      _rows.add(ExerciseRow(
        weightController: TextEditingController(text: '0'),
        repsController: TextEditingController(text: '0'),
        counter: _counter,
        onCheckPressed: _startTimer,
        onCheckChanged: (isChecked) => _handleCheckChanged(_counter - 1, isChecked),
      ));
       _initializeCheckedStates(_counter);
    });
  }

  void _deleteLastRow() {
    setState(() {
      if (_rows.isNotEmpty) {
        _rows.removeLast();
        _counter--;
         _initializeCheckedStates(_counter);
      }
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    setState(() {
      _remainingTime = 0;
      _isCountdownActive = false;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    nameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    uid = Provider.of<UserProvider>(context, listen: false).uid;
    myCollectionName();
    _initializeCheckedStates(_counter);
     _loadEndTimeFromPrefs();
     
  }
  Future<void> myCollectionName() async {
  try {
    print(widget.currentroutinename);
    print(_title);
    DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('Routine')
        .doc('Myroutine')
        .get();

    if (documentSnapshot.exists) {
      var data = documentSnapshot.data() as Map<String, dynamic>;

      if (data.containsKey(widget.currentroutinename)) {
        List<dynamic> myRoutineList = data[widget.currentroutinename];

        var routineData = myRoutineList.firstWhere(
          (routine) => routine.containsKey(_title),
          orElse: () => null,
        );

        if (routineData != null && routineData[_title].containsKey('exercises')) {
          List<Map<String, dynamic>> exercisesData =
              List<Map<String, dynamic>>.from(routineData[_title]['exercises']
                  .map((exercise) => {
                        'reps': exercise['reps'],
                        'weight': exercise['weight'],
                      })
                  .toList());

          setState(() {
            _counter = exercisesData.length;
            _checkedStates = List<bool>.filled(_counter, false); // 상태 초기화
            _rows = exercisesData.map((exercise) {
              int currentIndex = exercisesData.indexOf(exercise);
              return ExerciseRow(
                weightController:
                    TextEditingController(text: exercise['weight'].toString()),
                repsController:
                    TextEditingController(text: exercise['reps'].toString()),
                counter: currentIndex + 1,
                onCheckPressed: _startTimer,
                onCheckChanged: (isChecked) => _handleCheckChanged(currentIndex, isChecked),
              );
            }).toList();
          });
        }
      }
    }
  } catch (e) {
    print('Error fetching document data: $e');
  }
}


//   Future<void> myCollectionName() async {
//   try {
//     print(widget.currentroutinename);
//     print(_title);
//     DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
//         .collection('users')
//         .doc(uid)
//         .collection('Routine')
//         .doc('Myroutine')
//         .collection(widget.currentroutinename)
//         .doc(_title)
//         .get();

//     if (documentSnapshot.exists) {
//       var data = documentSnapshot.data() as Map<String, dynamic>;
//       if (data.containsKey('exercises')) {
//         List<Map<String, dynamic>> exercisesData =
//             List<Map<String, dynamic>>.from(data['exercises']
//                 .map((exercise) => {
//                       'reps': exercise['reps'],
//                       'weight': exercise['weight'],
//                     })
//                 .toList());

//         setState(() {
//           _counter = exercisesData.length;
//           _checkedStates = List<bool>.filled(_counter, false); // 상태 초기화
//           _rows = exercisesData.map((exercise) {
//             int currentIndex = exercisesData.indexOf(exercise);
//             return ExerciseRow(
//               weightController:
//                   TextEditingController(text: exercise['weight'].toString()),
//               repsController:
//                   TextEditingController(text: exercise['reps'].toString()),
//               counter: currentIndex + 1,
//               onCheckPressed: _startTimer,
//               onCheckChanged: (isChecked) => _handleCheckChanged(currentIndex, isChecked),
//             );
//           }).toList();
//         });
//       }
//     }
//   } catch (e) {
//     print('Error fetching document data: $e');
//   }
// }

Future<void> saveRoutineData() async {
  var db = FirebaseFirestore.instance;

  Map<String, dynamic> routine = {"exercises": []};
  for (var row in _rows) {
    String weight = row.weightController.text;
    String reps = row.repsController.text;

    routine["exercises"].add({
      "weight": weight,
      "reps": reps,
    });
  }

  if (routine["exercises"].isNotEmpty) {
    try {
      DocumentReference myRoutineRef = db
          .collection('users')
          .doc(uid)
          .collection('Routine')
          .doc('Myroutine');

      DocumentSnapshot documentSnapshot = await myRoutineRef.get();

      if (documentSnapshot.exists) {
        var existingData = documentSnapshot.data() as Map<String, dynamic>;
        List<dynamic> myRoutineList = existingData[widget.currentroutinename] ?? [];

        // _title이 같은 루틴을 찾기
        int routineIndex = myRoutineList.indexWhere((routine) => routine.containsKey(_title));

        if (routineIndex != -1) {
          // 기존 _title을 가진 루틴 업데이트
          myRoutineList[routineIndex][_title] = routine;
        } else {
          // 새로운 루틴 추가
          myRoutineList.add({_title: routine});
        }

        await myRoutineRef.update({widget.currentroutinename: myRoutineList});
      } else {
        // 문서가 없을 경우 새로 생성
        await myRoutineRef.set({
          widget.currentroutinename: [
            {_title: routine}
          ]
        });
      }
    } catch (e) {
      print('Error adding document: $e');
    }
  }
}

  // Future<void> saveRoutineData() async {
  //   var db = FirebaseFirestore.instance;

  //   Map<String, dynamic> routine = {"exercises": []};
  //   for (var row in _rows) {
  //     String weight = row.weightController.text;
  //     String reps = row.repsController.text;

  //     routine["exercises"].add({
  //       "weight": weight,
  //       "reps": reps,
  //     });
  //   }

  //   if (routine["exercises"].isNotEmpty) {
  //     try {
  //       await db
  //           .collection('users')
  //           .doc(uid)
  //           .collection('Routine')
  //           .doc('Myroutine')
  //           .collection(widget.currentroutinename)
  //           .doc(_title)
  //           .set(routine);
  //     } catch (e) {
  //       print('Error saving routine data: $e');
  //     }
  //   }
  // }

 @override
Widget build(BuildContext context) {
  return GestureDetector(
    onTap: () {
      FocusScope.of(context).unfocus(); // 화면을 클릭하면 키보드 숨기기
    },
    child: Scaffold(
      backgroundColor: Colors.blueGrey.shade800,
      resizeToAvoidBottomInset: true, // 키보드가 나타날 때 레이아웃 조정
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
          onPressed: () async{
            await saveRoutineData();
            Navigator.of(context).pop('not done');
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade600,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 7,
                    offset: Offset(0, 3),
                  ),
                ],
                border: Border.all(
                  color: Colors.blueGrey.shade500,
                  width: 2,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text.rich(
                      TextSpan(
                        text: 'Time: ',
                        style: TextStyle(
                            fontSize: 40,
                            fontFamily: 'Oswald',
                            color: Colors.black), // 기본 텍스트 스타일
                        children: <TextSpan>[
                          TextSpan(
                              text: '$_remainingTime',
                              style: TextStyle(
                                  color: Colors.white)), // 강조할 부분
                          TextSpan(text: ' Seconds'),
                        ],
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: _cancelTimer,
                          child: Text(
                            '취소',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                          ),
                        ),
                        SizedBox(width: 10),
                        Column(
                          children: [
                            Text('Minute',
                                style: TextStyle(fontSize: 20, fontFamily: 'Oswald',)),
                            Container(
                              height: 150,
                              width: 100,
                              child: CupertinoPicker(
                                itemExtent: 32.0,
                                onSelectedItemChanged: (int index) {
                                  setState(() {
                                    _minutes = index;
                                  });
                                },
                                children: List<Widget>.generate(
                                    60, (int index) {
                                  return Center(
                                    child: Text(
                                        '${index.toString().padLeft(2, '0')}'),
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                        Text(':', style: TextStyle(fontSize: 20)),
                        Column(
                          children: [
                            Text('Seconds',
                                style: TextStyle(fontSize: 20, fontFamily: 'Oswald',)),
                            Container(
                              height: 150,
                              width: 100,
                              child: CupertinoPicker(
                                itemExtent: 32.0,
                                onSelectedItemChanged: (int index) {
                                  setState(() {
                                    _seconds = index;
                                  });
                                },
                                children: List<Widget>.generate(
                                    60, (int index) {
                                  return Center(
                                    child: Text(
                                        '${index.toString().padLeft(2, '0')}'),
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _startTimer,
                          child: Text(
                            '시작',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Stack(
              children: [
                Container(
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
                ),
                Column(
                  children: [
                    ..._rows,
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          margin: EdgeInsets.only(left: 40.0, bottom: 20.0),
                          width: 140,
                          height: 60,
                          child: FloatingActionButton.extended(
                            onPressed: _addTextFields,
                            icon: Icon(
                              Icons.add,
                              color: Colors.white,
                            ),
                            label: Text(
                              "세트추가",
                              style: TextStyle(color: Colors.white),
                            ),
                            backgroundColor: Colors.blueGrey.shade900,
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(right: 40.0, bottom: 20.0),
                          width: 140,
                          height: 60,
                          child: FloatingActionButton.extended(
                            onPressed: _deleteLastRow,
                            icon: Icon(
                              Icons.remove,
                              color: Colors.yellow,
                            ),
                            label: Text(
                              "세트삭제",
                              style: TextStyle(color: Colors.yellow),
                            ),
                            backgroundColor: Colors.blueGrey.shade900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            if (_isCountdownActive)
              Positioned.fill(
                child: Container(
                  color: Colors.black54,
                  child: Center(
                    child: Text(
                      '$_remainingTime',
                      style: TextStyle(
                        fontSize: 100,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

    
    
  }


class ExerciseRow extends StatefulWidget {
  final TextEditingController weightController;
  final TextEditingController repsController;
  final int counter;
  final VoidCallback onCheckPressed;
  final ValueChanged<bool> onCheckChanged;

  ExerciseRow({
    required this.weightController,
    required this.repsController,
    required this.counter,
    required this.onCheckPressed,
    required this.onCheckChanged,
  });

  @override
  _ExerciseRowState createState() => _ExerciseRowState();
}

class _ExerciseRowState extends State<ExerciseRow> {
  bool _isChecked = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Container(
            padding: EdgeInsets.all(16.0),
            color: Colors.cyan.shade700,
            child: Text(
              '${widget.counter}',
              style: TextStyle(color: Colors.white),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: widget.weightController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: "무게를 입력하세요",
                hintStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                ),
                fillColor: Colors.white,
                filled: true,
              ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: widget.repsController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: "횟수를 입력하세요",
                hintStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                ),
                fillColor: Colors.white,
                filled: true,
              ),
            ),
          ),
          SizedBox(width: 10),
          IconButton(
            icon: Icon(
              _isChecked ? Icons.check_box : Icons.check_box_outline_blank,
              color: _isChecked ? Colors.green : Colors.grey,
            ),
            onPressed: () {
              setState(() {
                _isChecked = !_isChecked;
              });
              widget.onCheckPressed();
              widget.onCheckChanged(_isChecked); 
            },
          ),
        ],
      ),
    );
  }
}
