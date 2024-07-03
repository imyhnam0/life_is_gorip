import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

class _CreateRoutinePageState extends State<CreateRoutinePage> {
  TextEditingController nameController = TextEditingController();
  List<TextEditingController> _weightControllers = [];
  List<TextEditingController> _repsControllers = [];
  late String _title = widget.clickroutinename;
  List<Widget> _rows = [];
  List<Map<String, dynamic>> exercisesData = [];
  int _counter = 1;

  @override
  void initState() {
    super.initState();

    if (_title == '') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showNameInputDialog(context);
      });
    } else {
      myCollectionName();
    }
  }

  void deleteData(String documentId) async {
    try {
      // 문서 삭제
      await FirebaseFirestore.instance
          .collection("Routine")
          .doc('Myroutine')
          .collection(widget.myroutinename)
          .doc(_title)
          .delete();
      myCollectionName();
    } catch (e) {
      print('Error deleting document: $e');
    }
  }

  void saveRoutineData() async {
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
        await db
            .collection('Routine')
            .doc('Myroutine')
            .collection(widget.myroutinename)
            .doc(_title)
            .set(routine);
      } catch (e) {
        print('Error adding document: $e');
      }
    }
  }

  void _showNameInputDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.cyan.shade900,
          title: Text(
            'Exercise name',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(
              hintText: "이름을 입력하세요",
              hintStyle: TextStyle(color: Colors.grey), // 힌트 텍스트 색상
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black), // 기본 상태의 밑줄 색상
              ),
              fillColor: Colors.white, // 텍스트 필드 배경 색상
              filled: true,
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
              },
            ),
            TextButton(
              child: Text(
                '확인',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                setState(() {
                  _title = nameController.text;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void myCollectionName() async {
    try {
      // 내루틴 가져오기
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('Routine')
          .doc('Myroutine')
          .collection(widget.myroutinename)
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
            Widget row = _buildExerciseRow(
                exercise['weight'].toString(), exercise['reps'].toString());
            _counter++; // 각 행을 추가할 때마다 카운터 증가
            return row;
          }).toList();
        });
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
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Container(
            padding: EdgeInsets.all(16.0),
            color: Colors.cyan.shade700,
            child: Text(
              '$_counter',
              style: TextStyle(color: Colors.white),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: weightController,
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
              controller: repsController,
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
      _rows.add(_buildExerciseRow('0', '0'));
      _counter++;
    });
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
            if (_rows.isEmpty) {
              Navigator.of(context).pop(false);
            } else {
              saveRoutineData();
              Navigator.of(context).pop(true);
            }
          },
        ),
        actions: [
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.edit,
                  color: Colors.white,
                ),
                onPressed: () {
                  deleteData(_title);
                  _showNameInputDialog(context);
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.save,
                  color: Colors.white,
                ),
                onPressed: () {
                  saveRoutineData();
                  Navigator.of(context).pop(true);
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
              children: [
                ..._rows,
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      margin: EdgeInsets.only(left: 40.0, bottom: 20.0),
                      width: 160,
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
                      width: 160,
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
    );
  }
}
