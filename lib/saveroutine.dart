import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'start_routine.dart';
import 'routine.dart';
import 'user_provider.dart';
import 'package:provider/provider.dart';

class SaveRoutinePage extends StatefulWidget {
  const SaveRoutinePage({super.key});

  @override
  State<SaveRoutinePage> createState() => _SaveRoutinePageState();
}

class _SaveRoutinePageState extends State<SaveRoutinePage> {
  List<String> collectionNames = [];
  List<String> savedCollectionNames = [];
  bool _isDelete = false;
  String? uid;

  @override
  void initState() {
    super.initState();
    uid = Provider.of<UserProvider>(context, listen: false).uid;
    loadStarRow();
    myCollectionName();
  }

  Future<void> deleteCollection(String documentId) async {
    var db = FirebaseFirestore.instance;
    // Remove documentId from Bookmark collection
    try {
      DocumentSnapshot bookmarkDoc = await db
          .collection('users')
          .doc(uid)
          .collection("Routine")
          .doc('Bookmark')
          .get();

      if (bookmarkDoc.exists) {
        List<String> names = List<String>.from(bookmarkDoc['names']);
        if (names.contains(documentId)) {
          names.remove(documentId);
          await db
              .collection('users')
              .doc(uid)
              .collection("Routine")
              .doc('Bookmark')
              .update({'names': names});
        }
      }
    } catch (e) {
      print('Error removing name: $e');
    }

    try {
    DocumentReference docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('Routine')
        .doc('Myroutine');

    DocumentSnapshot documentSnapshot = await docRef.get();

    if (documentSnapshot.exists) {
      var data = documentSnapshot.data() as Map<String, dynamic>;

      if (data.containsKey(documentId)) {
        // Remove the entire collection (_title)
        data.remove(documentId);
        await docRef.set(data);
      }
    }

    await myCollectionName();
  } catch (e) {
    print('Error deleting collection: $e');
  }


   
  }


  Future<void> myCollectionName() async {
  try {
    DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('Routine')
        .doc('Myroutine')
        .get();

    if (documentSnapshot.exists) {
      var data = documentSnapshot.data() as Map<String, dynamic>;

      List<String> names = [];
      data.forEach((key, value) {
        names.add(key);
      });

      setState(() {
        collectionNames = names;
      });
    }
  } catch (e) {
    print('Error fetching collection names: $e');
  }
}


  // Future<void> myCollectionName() async {
  //   try {
  //     QuerySnapshot querySnapshot = await FirebaseFirestore.instance
  //         .collection('users')
  //         .doc(uid)
  //         .collection("Routine")
  //         .doc('Routinename')
  //         .collection('Names')
  //         .orderBy('order')
  //         .get();

  //     List<String> names =
  //         querySnapshot.docs.map((doc) => doc['name'] as String).toList();

  //     setState(() {
  //       collectionNames = names;
  //     });
  //   } catch (e) {
  //     print('Error fetching collection names: $e');
  //   }
  // }

  Future<void> loadStarRow() async {
    try {
      DocumentSnapshot bookmarkDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
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

  Future<void> addStarRow(String name) async {
    try {
      DocumentReference bookmarkDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection("Routine")
          .doc('Bookmark');

      DocumentSnapshot bookmarkDoc = await bookmarkDocRef.get();

      if (bookmarkDoc.exists) {
        List<String> names = List<String>.from(bookmarkDoc['names']);
        if (!names.contains(name)) {
          names.add(name);
          await bookmarkDocRef.update({'names': names});
        }
      } else {
        await bookmarkDocRef.set({'names': [name]});
      }

      setState(() {
        savedCollectionNames.add(name);
      });
    } catch (e) {
      print('Error adding name: $e');
    }
  }


  // Future<void> updateFirestoreOrder() async {
  //   try {
  //     WriteBatch batch = FirebaseFirestore.instance.batch();
  //     CollectionReference collectionRef = FirebaseFirestore.instance
  //         .collection('users')
  //         .doc(uid)
  //         .collection("Routine")
  //         .doc('Routinename')
  //         .collection('Names');

  //     for (int i = 0; i < collectionNames.length; i++) {
  //       QuerySnapshot querySnapshot = await collectionRef
  //           .where('name', isEqualTo: collectionNames[i])
  //           .get();

  //       if (querySnapshot.docs.isNotEmpty) {
  //         DocumentReference docRef = querySnapshot.docs[0].reference;
  //         batch.update(docRef, {'order': i});
  //       }
  //     }

  //     await batch.commit();
  //   } catch (e) {
  //     print('Error updating Firestore order: $e');
  //   }
  // }

  Future<void> removeStarRow(String name) async {
    try {
      DocumentSnapshot bookmarkDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection("Routine")
          .doc('Bookmark')
          .get();

      if (bookmarkDoc.exists) {
        List<String> names = List<String>.from(bookmarkDoc['names']);
        if (names.contains(name)) {
          names.remove(name);
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
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
            Navigator.pop(context, true);
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
                      builder: (context) => const RoutinePage(),
                    ),
                  ).then((value) {
                    if (value == true) {
                      myCollectionName();
                    }
                  });
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.edit,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _isDelete = !_isDelete;
                  });
                },
              ),
            ],
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
        child: ReorderableListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          onReorder: (int oldIndex, int newIndex)  {
            setState(() {
              if (oldIndex < newIndex) {
                newIndex -= 1;
              }
              final String item = collectionNames.removeAt(oldIndex);
              collectionNames.insert(newIndex, item);
            });
            
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
                              builder: (context) => StartRoutinePage(
                                clickroutinename: collectionNames[index],
                              ),
                            ),
                          ).then((value) {
                            if (value == true) {
                              myCollectionName();
                            }
                          });
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
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
                              style: TextStyle(
                                fontSize: 18.0,
                                color: Colors.white,
                              ),
                            ),
                            Spacer(), 
                            ReorderableDragStartListener(
                              index: index,
                              child: Container(
                                padding: const EdgeInsets.all(3.0),
                                child: Icon(
                                  Icons.drag_handle,
                                  size: 30.0,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Visibility(
                      visible: _isDelete,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 5.0),
                        child: IconButton(
                          icon: Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            deleteCollection(collectionNames[index]);
                          },
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
