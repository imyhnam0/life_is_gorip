import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'playroutine.dart';
import 'create_routine.dart';

class StartRoutinePage extends StatefulWidget {
  final String clickroutinename;
  const StartRoutinePage({Key? key, required this.clickroutinename})
      : super(key: key);

  @override
  _StartRoutinePageState createState() => _StartRoutinePageState();
}

class _StartRoutinePageState extends State<StartRoutinePage> {
  TextEditingController nameController = TextEditingController();
  late String _title = widget.clickroutinename;
  List<String> collectionNames = [];

  @override
  void initState() {
    super.initState();
    myCollectionName();
  }

  Future<void> deleteData(String documentId) async {
    try {
      await FirebaseFirestore.instance
          .collection("Routine")
          .doc('Myroutine')
          .collection(widget.clickroutinename)
          .doc(documentId)
          .delete();
      await myCollectionName();
    } catch (e) {
      print('Error deleting document: $e');
    }
  }

  Future<void> myCollectionName() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Routine')
          .doc('Myroutine')
          .collection(widget.clickroutinename)
          .get();
      List<String> names = querySnapshot.docs.map((doc) => doc.id).toList();

      setState(() {
        collectionNames = names;
      });
    } catch (e) {
      print('Error fetching collection names: $e');
    }
  }

  void _showNameInputDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.cyan.shade900,
          title: const Text(
            '이름 수정',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: nameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "이름을 입력하세요",
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
          actions: [
            TextButton(
              child: const Text(
                '취소',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
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

  Future<void> saveRoutineName() async {
    var db = FirebaseFirestore.instance;

    try {
      await db
          .collection('Routine')
          .doc('Routinename')
          .collection('Names')
          .add({'name': nameController.text});
    } catch (e) {
      print('Error adding document: $e');
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
            Navigator.pop(context);
          },
        ),
        actions: [
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
              saveRoutineName();
              Navigator.of(context).pop();
            },
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
        child: ListView.builder(
          itemCount: collectionNames.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                  vertical: 15.0, horizontal: 30.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.all(30.0),
                        backgroundColor: Colors.blueGrey.shade800,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          side: BorderSide(
                            color: Colors.blueGrey.shade700,
                            width: 2,
                          ),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateRoutinePage(
                              myroutinename: _title,
                              clickroutinename: collectionNames[index],
                            ),
                          ),
                        ).then((value) {
                          if (value == true) {
                            myCollectionName();
                          }
                          if (value == false) {
                            deleteData(collectionNames[index]);
                          }
                        });
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            collectionNames[index],
                            style: TextStyle(
                                fontSize: 18.0, color: Colors.white),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              deleteData(collectionNames[index]);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.blueGrey.shade800,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Container(
              width: 170.0,
              height: 56.0,
              child: FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateRoutinePage(
                        myroutinename: _title,
                        clickroutinename: "",
                      ),
                    ),
                  ).then((value) {
                    if (value == true) {
                      myCollectionName();
                    }
                  });
                },
                icon: Icon(
                  Icons.add,
                  color: Colors.white,
                ),
                label: Text(
                  "생성",
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.cyan.shade700,
              ),
            ),
            Container(
              width: 170.0,
              height: 56.0,
              child: FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlayMyRoutinePage(
                        clickroutinename: widget.clickroutinename,
                      ),
                    ),
                  );
                },
                icon: Icon(
                  Icons.sports_gymnastics,
                  color: Colors.blueGrey.shade700,
                ),
                label: Text(
                  "시작",
                  style: TextStyle(color: Colors.blueGrey.shade700),
                ),
                backgroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
