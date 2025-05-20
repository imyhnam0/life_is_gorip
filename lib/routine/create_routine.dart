import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'user_provider.dart';
import 'package:provider/provider.dart';

class CreateRoutinePage extends StatefulWidget {
  final String clickroutinename;
  final String myroutinename;

  const CreateRoutinePage({
    Key? key,
    required this.clickroutinename,
    required this.myroutinename,
  }) : super(key: key);

  @override
  _CreateRoutinePageState createState() => _CreateRoutinePageState();
}

class _CreateRoutinePageState extends State<CreateRoutinePage>
    with SingleTickerProviderStateMixin {
  TextEditingController nameController = TextEditingController();
  List<TextEditingController> _weightControllers = [];
  List<TextEditingController> _repsControllers = [];
  late String _title = widget.clickroutinename;
  List<Widget> _rows = [];
  List<Map<String, dynamic>> exercisesData = [];
  int _counter = 1;
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? uid;
  String lastname = ''; // 마지막으로 입력한 루틴 이름

  @override
  void initState() {
    super.initState();
    uid = Provider.of<UserProvider>(context, listen: false).uid;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.1, 0.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticIn,
    ));

    if (_title.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showNameInputDialog(context);
      });
    } else {
      myCollectionName();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    _controller.dispose();
    _weightControllers.forEach((controller) => controller.dispose());
    _repsControllers.forEach((controller) => controller.dispose());
    super.dispose();
  }

  Future<void> updateRoutineTitle(String newTitle) async {
    //이름 수정해주는 함수
    var db = FirebaseFirestore.instance;

    try {
      DocumentReference myRoutineRef = db
          .collection('users')
          .doc(uid)
          .collection('Routine')
          .doc('Myroutine');

      DocumentSnapshot documentSnapshot = await myRoutineRef.get();

      if (documentSnapshot.exists) {
        var existingData = documentSnapshot.data() as Map<String, dynamic>;
        List<dynamic> myRoutineList = existingData[widget.myroutinename] ?? [];

        // _title이 같은 루틴을 찾기
        int routineIndex =
            myRoutineList.indexWhere((routine) => routine.containsKey(_title));

        if (routineIndex != -1) {
          var routineData = myRoutineList[routineIndex][_title];

          // 기존 루틴 삭제
          myRoutineList.removeAt(routineIndex);

          // 새로운 이름으로 루틴 추가
          myRoutineList.add({newTitle: routineData});

          // Firestore 업데이트
          await myRoutineRef.update({widget.myroutinename: myRoutineList});

          // 로컬 상태 업데이트
          setState(() {
            _title = newTitle;
          });
        }
      }
    } catch (e) {
      print('Error updating routine title: $e');
    }
  }

  Future<void> saveRoutineData() async {
    var db = FirebaseFirestore.instance;

    Map<String, dynamic> routine = {"exercises": []};
    for (int i = 0; i < _weightControllers.length; i++) {
      String weight = _weightControllers[i].text;
      String reps = _repsControllers[i].text;

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
          List<dynamic> myRoutineList =
              existingData[widget.myroutinename] ?? [];

          // _title이 같은 루틴을 찾기
          int routineIndex = myRoutineList
              .indexWhere((routine) => routine.containsKey(_title));

          if (routineIndex != -1) {
            // 기존 _title을 가진 루틴 업데이트
            myRoutineList[routineIndex][_title] = routine;
          } else {
            // 새로운 루틴 추가
            myRoutineList.add({_title: routine});
          }

          await myRoutineRef.update({widget.myroutinename: myRoutineList});
        } else {
          // 문서가 없을 경우 새로 생성
          await myRoutineRef.set({
            widget.myroutinename: [
              {_title: routine}
            ]
          });
        }
      } catch (e) {
        print('Error adding document: $e');
      }
    }
  }

  void _showNameInputDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return SlideTransition(
          position: _offsetAnimation,
          child: AlertDialog(
            backgroundColor: Colors.cyan.shade900,
            title: Text(
              '운동 종목 생성',
              style: TextStyle(color: Colors.white),
            ),
            content: Form(
              key: _formKey,
              child: TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: "이름을 입력하세요",
                  hintStyle: TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  fillColor: Colors.white,
                  filled: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '이름을 입력해주세요';
                  }
                  return null;
                },
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
                  Navigator.of(context).pop(); // 대화상자 닫기
                },
              ),
              TextButton(
                child: Text(
                  '확인',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    await updateRoutineTitle(nameController.text);
                    setState(() {
                      _title = nameController.text;
                    });
                    Navigator.of(context).pop();
                  } else {
                    _controller
                        .forward()
                        .then((value) => _controller.reverse());
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void myCollectionName() async {
    try {
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('Routine')
          .doc('Myroutine')
          .get();

      if (documentSnapshot.exists) {
        var data = documentSnapshot.data() as Map<String, dynamic>;

        // Check if the widget.myroutinename exists
        if (data.containsKey(widget.myroutinename)) {
          List<dynamic> myRoutineList = data[widget.myroutinename];

          // Find the routine with the title widget.clickroutinename
          for (var routine in myRoutineList) {
            if (routine.containsKey(widget.clickroutinename)) {
              var routineData = routine[widget.clickroutinename];
              if (routineData.containsKey('exercises')) {
                exercisesData =
                    List<Map<String, dynamic>>.from(routineData['exercises']
                        .map((exercise) => {
                              'reps': exercise['reps'],
                              'weight': exercise['weight'],
                            })
                        .toList());
              }
              break;
            }
          }

          setState(() {
            _rows = exercisesData.map((exercise) {
              Widget row = _buildExerciseRow(
                  exercise['weight'].toString(), exercise['reps'].toString());
              _counter++;
              return row;
            }).toList();
          });
        }
      }
    } catch (e) {
      print('Error fetching document data: $e');
    }
  }

  Widget _buildExerciseRow(String weight, String reps) {
    final weightController = TextEditingController(text: weight.toString());
    final repsController = TextEditingController(text: reps.toString());

    _weightControllers.add(weightController);
    _repsControllers.add(repsController);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.cyan.shade700,
            child: Text(
              '$_counter',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: weightController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "무게를 입력하세요",
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
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: repsController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "횟수를 입력하세요",
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
          ),
        ],
      ),
    );
  }

  void _deleteLastRow() {
    setState(() {
      if (_rows.isNotEmpty) {
        _rows.removeLast();
        _weightControllers.removeLast();
        _repsControllers.removeLast();
        _counter--;
      }
    });
  }

  void _addTextFields() {
    setState(() {
      _rows.add(_buildExerciseRow('', ''));
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // 화면을 클릭하면 키보드 숨기기
      },
      child: Scaffold(
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
              if (_rows.isEmpty) {
                Navigator.of(context).pop(false);
              } else {
                saveRoutineData().then((_) {
                  Navigator.of(context).pop(true);
                });
              }
            },
            tooltip: '뒤로 가기',
          ),
          actions: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.edit,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () {
                    lastname = _title;

                    _showNameInputDialog(context);
                  },
                ),
                IconButton(
                  icon: const Icon(
                    Icons.save,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () {
                    if (_rows.isEmpty) {
                      Navigator.of(context).pop(false);
                    } else {
                      saveRoutineData().then((_) {
                        Navigator.of(context).pop(true);
                      });
                    }
                  },
                ),
              ],
            )
          ],
        ),
        body: Stack(
          children: [
            Container(
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
            ),
            SingleChildScrollView(
              child: Column(
                children: [
                  ..._rows,
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(left: 20.0, bottom: 20.0),
                        width: 160,
                        height: 60,
                        child: FloatingActionButton.extended(
                          heroTag: null,
                          onPressed: _addTextFields,
                          icon: const Icon(
                            Icons.add,
                            color: Colors.white,
                          ),
                          label: const Text(
                            "세트추가",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Oswald',
                            ),
                          ),
                          backgroundColor: Colors.blueGrey.shade700,
                        ),
                      ),
                      Container(
                        margin:
                            const EdgeInsets.only(right: 20.0, bottom: 20.0),
                        width: 160,
                        height: 60,
                        child: FloatingActionButton.extended(
                          heroTag: null,
                          onPressed: _deleteLastRow,
                          icon: const Icon(
                            Icons.remove,
                            color: Colors.white,
                          ),
                          label: const Text(
                            "세트삭제",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Oswald',
                            ),
                          ),
                          backgroundColor: Colors.blueGrey.shade700,
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
    );
  }
}
