import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'start_routine.dart';
import 'routine.dart';

class SaveRoutinePage extends StatefulWidget {
  const SaveRoutinePage({super.key});

  @override
  State<SaveRoutinePage> createState() => _SaveRoutinePageState();
}

class _SaveRoutinePageState extends State<SaveRoutinePage> {
  List<String> collectionNames = [];
  List<String> savedCollectionNames = [];

  @override
  void initState() {
    super.initState();
    loadStarRow();
    myCollectionName();
  }

  void deleteCollection(String documentId) async {
    try {
      // 컬렉션의 모든 문서를 가져옴
      var collectionRef = FirebaseFirestore.instance
          .collection("Routine")
          .doc('Myroutine')
          .collection(documentId);

      var snapshots = await collectionRef.get();

      // 각 문서를 삭제
      for (var doc in snapshots.docs) {
        await doc.reference.delete();
      }
      var namesCollectionRef = FirebaseFirestore.instance
          .collection("Routine")
          .doc('Routinename')
          .collection("Names");

      var namesSnapshots =
          await namesCollectionRef.where('name', isEqualTo: documentId).get();

      // 각 문서를 삭제
      for (var doc in namesSnapshots.docs) {
        await doc.reference.delete();
      }
      myCollectionName();
      // 새로고침 함수 호출
    } catch (e) {
      print('Error deleting collection: $e');
    }
  }

  void myCollectionName() async {
    try {
      // '_title' 컬렉션에서 하위 문서 ID들 가져오기
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection("Routine")
          .doc('Routinename')
          .collection('Names')
          .orderBy('order')
          .get();
      List<String> names =
          querySnapshot.docs.map((doc) => doc['name'] as String).toList();

      setState(() {
        collectionNames = names;
      });
    } catch (e) {
      print('Error fetching collection names: $e');
    }
  }

  void loadStarRow() async {
    try {
      DocumentSnapshot bookmarkDoc = await FirebaseFirestore.instance
          .collection("Routine")
          .doc('Bookmark')
          .get();

      if (bookmarkDoc.exists) {
        List<String> names = List<String>.from(bookmarkDoc['names']);
        setState(() {
          savedCollectionNames = names;
        });
      }
    } catch (e) {
      print('Error fetching saved collection names: $e');
    }
  }

  void addStarRow(String name) async {
    try {
      DocumentSnapshot bookmarkDoc = await FirebaseFirestore.instance
          .collection("Routine")
          .doc('Bookmark')
          .get();

      if (bookmarkDoc.exists) {
        List<String> names = List<String>.from(bookmarkDoc['names']);
        if (!names.contains(name)) {
          names.add(name);
          await FirebaseFirestore.instance
              .collection("Routine")
              .doc('Bookmark')
              .update({'names': names});
          setState(() {
            savedCollectionNames = names;
          });
        }
      }
    } catch (e) {
      print('Error adding name: $e');
    }
  }

  Future<void> updateFirestoreOrder() async {
    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      CollectionReference collectionRef = FirebaseFirestore.instance
          .collection("Routine")
          .doc('Routinename')
          .collection('Names');

      // `collectionNames` 리스트는 각 문서의 `name` 필드를 포함하고 있는 것으로 가정합니다.
      for (int i = 0; i < collectionNames.length; i++) {
        // `collectionNames[i]` 값을 가진 문서를 찾습니다.
        QuerySnapshot querySnapshot = await collectionRef
            .where('name', isEqualTo: collectionNames[i])
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          DocumentReference docRef = querySnapshot.docs[0].reference;
          batch.update(docRef, {'order': i});
        }
      }

      await batch.commit();

      myCollectionName();
    } catch (e) {
      print('Error updating Firestore order: $e');
    }
  }

  void removeStarRow(String name) async {
    try {
      DocumentSnapshot bookmarkDoc = await FirebaseFirestore.instance
          .collection("Routine")
          .doc('Bookmark')
          .get();

      if (bookmarkDoc.exists) {
        List<String> names = List<String>.from(bookmarkDoc['names']);
        if (names.contains(name)) {
          names.remove(name);
          await FirebaseFirestore.instance
              .collection("Routine")
              .doc('Bookmark')
              .update({'names': names});
          setState(() {
            savedCollectionNames = names;
          });
        }
      }
    } catch (e) {
      print('Error removing name: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "루틴 모음",
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
        actions: [
          Row(
            children: [
              IconButton(
                  icon: Icon(
                    Icons.add,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const RoutinePage()),
                    ).then((value) {
                      if (value == true) {
                        myCollectionName();
                      }
                    });
                    ;
                  }),
            ],
          ),
        ],
      ),
      body: Container(
        color: Colors.black,
        child: ReorderableListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          onReorder: (int oldIndex, int newIndex) async {
            setState(() {
              if (oldIndex < newIndex) {
                newIndex -= 1;
              }
              final String item = collectionNames.removeAt(oldIndex);
              collectionNames.insert(newIndex, item);
            });
            await updateFirestoreOrder();
          },
          children: <Widget>[
            for (int index = 0; index < collectionNames.length; index++)
              Padding(
                key: Key('$index'),
                padding: const EdgeInsets.symmetric(
                    vertical: 15.0, horizontal: 30.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.all(25.0),
                          backgroundColor: Color.fromARGB(255, 39, 34, 34),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StartRoutinePage(
                                clickroutinename: collectionNames[index],
                              ),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            StarRow(
                              name: collectionNames[index],
                              isChecked: savedCollectionNames
                                  .contains(collectionNames[index]),
                              onAdd: addStarRow,
                              onRemove: removeStarRow,
                            ),
                            Text(
                              collectionNames[index],
                              style:
                                  TextStyle(fontSize: 18.0, color: Colors.red),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                deleteCollection(collectionNames[index]);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    ReorderableDragStartListener(
                      index: index,
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.drag_handle,
                          size: 36.0, // 원하는 크기로 설정
                          color: Colors.white,
                        ),
                      ),
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

class StarRow extends StatefulWidget {
  final String name;
  final bool isChecked;
  final Function(String) onAdd;
  final Function(String) onRemove;

  StarRow({
    required this.name,
    required this.isChecked,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  _StarRowState createState() => _StarRowState();
}

class _StarRowState extends State<StarRow> {
  late bool _isChecked;

  @override
  void initState() {
    super.initState();
    _isChecked = widget.isChecked;
  }

  @override
  void didUpdateWidget(StarRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isChecked != widget.isChecked) {
      _isChecked = widget.isChecked;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: IconButton(
        icon: Icon(
          _isChecked ? Icons.star : Icons.star_border_outlined,
          color: _isChecked ? Colors.yellow : Colors.grey,
          size: 30,
        ),
        onPressed: () {
          setState(() {
            _isChecked = !_isChecked;
            if (_isChecked) {
              widget.onAdd(widget.name);
            } else {
              widget.onRemove(widget.name);
            }
          });
        },
      ),
    );
  }
}
