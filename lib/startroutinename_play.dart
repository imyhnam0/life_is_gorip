import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'create_routine.dart';
import 'dart:async';

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

  late String _title = widget.clickroutinename;
  List<Widget> _rows = [];
  List<Map<String, dynamic>> exercisesData = [];
  int _counter = 0;
  int _minutes = 0;
  int _seconds = 0;
  Timer? _timer;
  int _remainingTime = 0;
  void _startTimer() {
    if (_timer != null) {
      _timer!.cancel();
    }
    setState(() {
      _remainingTime = _minutes * 60 + _seconds;
    });

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _incrementMinutes() {
    setState(() {
      _minutes++;
    });
  }

  void _incrementSeconds() {
    setState(() {
      _seconds++;
      if (_seconds >= 60) {
        _seconds = 0;
        _minutes++;
      }
    });
  }

  void _decrementMinutes() {
    if (_minutes > 0) {
      setState(() {
        _minutes--;
      });
    }
  }

  void _decrementSeconds() {
    if (_seconds > 0) {
      setState(() {
        _seconds--;
      });
    } else if (_minutes > 0) {
      setState(() {
        _seconds = 59;
        _minutes--;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    myCollectionName();
  }

  void myCollectionName() async {
    try {
      // 내루틴 가져오기
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('Routine')
          .doc('Myroutine')
          .collection(widget.currentroutinename)
          .doc(widget.clickroutinename)
          .get();

      if (documentSnapshot.exists) {
        var data = documentSnapshot.data() as Map<String, dynamic>;
        if (data.containsKey('exercises')) {
          exercisesData = List<Map<String, dynamic>>.from(data['exercises']
              .map((exercise) => {
                    'reps': exercise['reps'],
                    'weight': exercise['weight'],
                  })
              .toList());
        }
        setState(() {
          _rows = exercisesData.map((exercise) {
            _counter++; // 각 행을 추가할 때마다 카운터 증가
            return ExerciseRow(
              weight: exercise['weight'].toString(),
              reps: exercise['reps'].toString(),
              counter: _counter,
              onCheckPressed: _startTimer,
            );
          }).toList();
        });
      }
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
      ),
      body: Column(
        children: [
          Flexible(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade600,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 7,
                    offset: Offset(0, 3), // changes position of shadow
                  ),
                ],
                border: Border.all(
                  color: Colors.blueGrey.shade500,
                  width: 2,
                ),
              ), // 빈 컨테이너
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '남은 시간: $_remainingTime 초',
                      style: TextStyle(fontSize: 20),
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            ElevatedButton(
                              onPressed: _incrementMinutes,
                              child: Text(
                                '+',
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                primary: Colors.cyan.shade700, // 버튼 배경색 설정
                              ),
                            ),
                            Text(
                              '$_minutes'.padLeft(2, '0'),
                              style: TextStyle(fontSize: 14),
                            ),
                            ElevatedButton(
                              onPressed: _decrementMinutes,
                              child: Text(
                                '-',
                                style: TextStyle(color: Colors.yellow),
                              ),
                              style: ElevatedButton.styleFrom(
                                primary: Colors.cyan.shade700, // 버튼 배경색 설정
                              ),
                            ),
                          ],
                        ),
                        Text(
                          ':',
                          style: TextStyle(fontSize: 14),
                        ),
                        Column(
                          children: [
                            ElevatedButton(
                              onPressed: _incrementSeconds,
                              child: Text(
                                '+',
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                primary: Colors.cyan.shade700, // 버튼 배경색 설정
                              ),
                            ),
                            Text(
                              '$_seconds'.padLeft(2, '0'),
                              style: TextStyle(fontSize: 14),
                            ),
                            ElevatedButton(
                              onPressed: _decrementSeconds,
                              child: Text(
                                '-',
                                style: TextStyle(color: Colors.yellow),
                              ),
                              style: ElevatedButton.styleFrom(
                                primary: Colors.cyan.shade700, // 버튼 배경색 설정
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _startTimer,
                      child: Text(
                        '타이머 시작',
                        style: TextStyle(color: Colors.cyan.shade700),
                      ),
                      style: ElevatedButton.styleFrom(
                        primary: Colors.white, // 버튼 배경색 설정
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Flexible(
            flex: 7,
            child: Stack(
              children: [
                Container(
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
                ),
                SingleChildScrollView(
                  child: Column(
                    children: _rows,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ExerciseRow extends StatefulWidget {
  final String weight;
  final String reps;
  final int counter;
  final VoidCallback onCheckPressed;

  ExerciseRow(
      {required this.weight,
      required this.reps,
      required this.counter,
      required this.onCheckPressed});

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
              controller: TextEditingController(text: widget.weight),
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
              controller: TextEditingController(text: widget.reps),
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
            },
          ),
        ],
      ),
    );
  }
}
