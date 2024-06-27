import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateRoutinePage extends StatefulWidget {
  const CreateRoutinePage(this.myroutinename, this.notmyid, {Key? key})
      : super(key: key);
  final String myroutinename;
  final String notmyid;

  @override
  _CreateRoutinePageState createState() => _CreateRoutinePageState();
}

class _CreateRoutinePageState extends State<CreateRoutinePage> {
  TextEditingController nameController = TextEditingController();
  List<TextEditingController> _weightControllers = [];
  List<TextEditingController> _repsControllers = [];
  String _title = '';
  List<Widget> _rows = [];
  int _counter = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showNameInputDialog(context);
    });
  }

  void deletedata(String collectionName, String documentId) async {
    try {
      // 문서 삭제
      await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(documentId)
          .delete();
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
    String documentId = nameController.text;

    try {
      // 지정한 ID로 문서 참조 후 데이터 저장
      await db.collection(widget.myroutinename).doc(documentId).set(routine);
    } catch (e) {
      print('Error adding document: $e');
    }
  }

  void _showNameInputDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey,
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
                borderSide: BorderSide(color: Colors.red), // 기본 상태의 밑줄 색상
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
      TextEditingController weightController = TextEditingController();
      TextEditingController repsController = TextEditingController();

      _weightControllers.add(weightController);
      _repsControllers.add(repsController);

      _rows.add(
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(
                padding: EdgeInsets.all(16.0),
                color: Colors.red,
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
                      borderSide: BorderSide(color: Colors.red),
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
                      borderSide: BorderSide(color: Colors.red),
                    ),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
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
              color: Color.fromARGB(255, 243, 8, 8),
            ),
          ),
          centerTitle: true,
          backgroundColor: Color.fromARGB(255, 17, 6, 6),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
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
                    _showNameInputDialog(context);
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.save,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    deletedata(widget.myroutinename, widget.notmyid);
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
              color: Colors.black,
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ..._rows,
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween, // 좌우에 버튼을 배치하기 위해 사용
                      children: [
                        Container(
                          margin: EdgeInsets.only(
                              left: 40.0, bottom: 20.0), // margin 추가
                          width: 200, // FloatingActionButton의 너비 조정
                          height: 60,
                          child: FloatingActionButton.extended(
                            onPressed: () {
                              _addTextFields();
                            },
                            icon: Icon(
                              Icons.add,
                              color: Colors.red,
                            ),
                            label: Text(
                              "세트추가",
                              style: TextStyle(color: Colors.red),
                            ),
                            backgroundColor: Color.fromARGB(255, 17, 6, 6),
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(
                              right: 40.0, bottom: 20.0), // margin 추가
                          width: 200, // FloatingActionButton의 너비 조정
                          height: 60,
                          child: FloatingActionButton.extended(
                            onPressed: () {
                              _deleteLastRow();
                            },
                            icon: Icon(
                              Icons.remove,
                              color: Colors.yellow,
                            ),
                            label: Text(
                              "세트삭제",
                              style: TextStyle(color: Colors.yellow),
                            ),
                            backgroundColor: Color.fromARGB(255, 17, 6, 6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ));
  }
}
