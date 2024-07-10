import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'user_provider.dart';
import 'package:provider/provider.dart';

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
  List<ExerciseRow> _rows = [];
  List<Map<String, dynamic>> exercisesData = [];
  int _counter = 0;
  int _minutes = 0;
  int _seconds = 0;
  Timer? _timer;
  int _remainingTime = 0;
  String? uid;

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

  void _addTextFields() {
    setState(() {
      _counter++;
      _rows.add(ExerciseRow(
        weightController: TextEditingController(text: '0'),
        repsController: TextEditingController(text: '0'),
        counter: _counter,
        onCheckPressed: _startTimer,
      ));
    });
  }

  void _deleteLastRow() {
    setState(() {
      if (_rows.isNotEmpty) {
        _rows.removeLast();
        _counter--;
      }
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    setState(() {
      _remainingTime = 0;
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
          .collection(widget.currentroutinename)
          .doc(_title)
          .get();

      if (documentSnapshot.exists) {
        var data = documentSnapshot.data() as Map<String, dynamic>;
        if (data.containsKey('exercises')) {
          List<Map<String, dynamic>> exercisesData =
              List<Map<String, dynamic>>.from(data['exercises']
                  .map((exercise) => {
                        'reps': exercise['reps'],
                        'weight': exercise['weight'],
                      })
                  .toList());

          setState(() {
            _rows = exercisesData.map((exercise) {
              _counter++;
              return ExerciseRow(
                weightController:
                    TextEditingController(text: exercise['weight'].toString()),
                repsController:
                    TextEditingController(text: exercise['reps'].toString()),
                counter: _counter,
                onCheckPressed: _startTimer,
              );
            }).toList();
          });
        }
      }
    } catch (e) {
      print('Error fetching document data: $e');
    }
  }

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
        await db
            .collection('users')
            .doc(uid)
            .collection('Routine')
            .doc('Myroutine')
            .collection(widget.currentroutinename)
            .doc(_title)
            .set(routine);
      } catch (e) {
        print('Error adding document: $e');
      }
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
          ),
          onPressed: () {
            saveRoutineData();
            Navigator.of(context).pop(true);
          },
        ),
      ),
      body: Column(
        children: [
          Flexible(
            flex: 3,
            child: SingleChildScrollView(
              child: Container(
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
                              fontSize: 25,
                              fontFamily: 'Oswald',
                              color: Colors.black), // 기본 텍스트 스타일
                          children: <TextSpan>[
                            TextSpan(
                                text: '$_remainingTime',
                                style: TextStyle(
                                    color: Colors.white)), // 빨간색으로 강조할 부분
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
                              Text('Minute', style: TextStyle(fontSize: 20,    fontFamily: 'Oswald',)),
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
                                  children:
                                      List<Widget>.generate(60, (int index) {
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
                              Text('Seconds', style: TextStyle(fontSize: 20,    fontFamily: 'Oswald',)),
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
                                  children:
                                      List<Widget>.generate(60, (int index) {
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
                        offset: Offset(0, 3),
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
  final TextEditingController weightController;
  final TextEditingController repsController;
  final int counter;
  final VoidCallback onCheckPressed;

  ExerciseRow({
    required this.weightController,
    required this.repsController,
    required this.counter,
    required this.onCheckPressed,
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
