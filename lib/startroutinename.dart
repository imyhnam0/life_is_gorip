import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'create_routine.dart';

class StartRoutineName extends StatefulWidget {
  final String clickroutinename;
  final String currentroutinename;
  const StartRoutineName(
      {Key? key,
      required this.clickroutinename,
      required this.currentroutinename})
      : super(key: key);

  @override
  _StartRoutineNameState createState() => _StartRoutineNameState();
}

class _StartRoutineNameState extends State<StartRoutineName> {
  TextEditingController nameController = TextEditingController();
  late String _title = widget.clickroutinename;
  List<Widget> _rows = [];
  List<Map<String, dynamic>> exercisesData = [];
  int _counter = 1;

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
    return Padding(
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
              controller: TextEditingController(text: weight.toString()),
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
              controller: TextEditingController(text: reps.toString()),
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
    );
  }

  void _addTextFields() {
    setState(() {
      _rows.add(_buildExerciseRow('0', '0'));
      _counter++;
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
          ), // Icons.list 대신 Icons.menu를 사용
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          Container(
            color: Colors.black,
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                ..._rows,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      margin: EdgeInsets.only(left: 40.0, bottom: 20.0),
                      width: 200,
                      height: 60,
                      child: FloatingActionButton.extended(
                        onPressed: _addTextFields,
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
                      margin: EdgeInsets.only(right: 40.0, bottom: 20.0),
                      width: 200,
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
                        backgroundColor: Color.fromARGB(255, 17, 6, 6),
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
