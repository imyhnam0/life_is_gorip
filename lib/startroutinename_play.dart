import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'create_routine.dart';

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
            _counter++; // 각 행을 추가할 때마다 카운터 증가
            return ExerciseRow(
              weight: exercise['weight'].toString(),
              reps: exercise['reps'].toString(),
              counter: _counter,
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
            color: Color.fromARGB(255, 243, 8, 8),
          ),
        ),
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 17, 6, 6),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: const Color.fromARGB(255, 241, 174, 174),
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
              children: _rows,
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

  ExerciseRow(
      {required this.weight, required this.reps, required this.counter});

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
            color: Colors.red,
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
              controller: TextEditingController(text: widget.reps),
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
            },
          ),
        ],
      ),
    );
  }
}
