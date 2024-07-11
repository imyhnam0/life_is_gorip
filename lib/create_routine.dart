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

  void deleteData(String documentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
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
        DocumentSnapshot documentSnapshot = await db
            .collection('users')
            .doc(uid)
            .collection('Routine')
            .doc('Myroutine')
            .collection(widget.myroutinename)
            .doc(_title)
            .get();

        if (documentSnapshot.exists) {
          var existingData = documentSnapshot.data() as Map<String, dynamic>;
          if (!DeepCollectionEquality()
              .equals(existingData['exercises'], routine['exercises'])) {
            await db
                .collection('users')
                .doc(uid)
                .collection('Routine')
                .doc('Myroutine')
                .collection(widget.myroutinename)
                .doc(_title)
                .set(routine);
          }
        } else {
          await db
              .collection('users')
              .doc(uid)
              .collection('Routine')
              .doc('Myroutine')
              .collection(widget.myroutinename)
              .doc(_title)
              .set(routine);
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
              'My routine name',
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
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
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
            _counter++;
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
    return Scaffold(
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
                  deleteData(_title);
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
                      margin: const EdgeInsets.only(right: 20.0, bottom: 20.0),
                      width: 160,
                      height: 60,
                      child: FloatingActionButton.extended(
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
    );
  }
}
