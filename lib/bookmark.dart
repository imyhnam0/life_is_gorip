import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'start_routine.dart';
import 'user_provider.dart';
import 'package:provider/provider.dart';

class BookMarkPage extends StatefulWidget {
  @override
  State<BookMarkPage> createState() => _BookMarkPageState();
}

class _BookMarkPageState extends State<BookMarkPage> {
  List<String> collectionNames = [];
  List<String> savedCollectionNames = [];
  List<String> filteredCollectionNames = [];
  List<String> modifiedCollectionNames = [];

  bool _isChecked = false;
  String? uid;

  @override
  void initState() {
    super.initState();
    uid = Provider.of<UserProvider>(context, listen: false).uid;
    myCollectionName();
    loadStarRow();
  }

  Future<void> updateFirestoreOrder(List<String> updatedCollectionNames) async {
    try {
      DocumentReference bookmarkDocRef =
          FirebaseFirestore.instance
          .collection('users')
        .doc(uid)
        .collection("Routine")
        .doc('Bookmark');

      DocumentSnapshot bookmarkDocSnapshot = await bookmarkDocRef.get();

      if (bookmarkDocSnapshot.exists) {
        await bookmarkDocRef.update({'names': updatedCollectionNames});
      } else {
        await bookmarkDocRef.set({'names': updatedCollectionNames});
      }

      myCollectionName();
    } catch (e) {
      print('Error updating Firestore order: $e');
    }
  }

  void deleteBookmark(String name) async {
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
        }
      }
    } catch (e) {
      print('Error removing name: $e');
    }
  }

  void myCollectionName() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
      .collection('users')
        .doc(uid)
          .collection("Routine")
          .doc('Routinename')
          .collection('Names')
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
      DocumentReference bookmarkDocRef =
          FirebaseFirestore.instance.collection('users')
        .doc(uid).collection("Routine").doc('Bookmark');

      DocumentSnapshot bookmarkDocSnapshot = await bookmarkDocRef.get();

      if (bookmarkDocSnapshot.exists) {
        List<dynamic> names = bookmarkDocSnapshot.get('names');
        setState(() {
          filteredCollectionNames = List<String>.from(names);
          modifiedCollectionNames = List<String>.from(names); // 초기화 시 현재 순서 저장
        });
      }
    } catch (e) {
      print('Error fetching names from Firestore: $e');
    }
  }

  void filterCollectionNames() {
    setState(() {
      filteredCollectionNames = collectionNames
          .where((name) => savedCollectionNames.contains(name))
          .toList();
    });
  }

  void saveChanges() async {
    await updateFirestoreOrder(modifiedCollectionNames);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "루틴 모음",
          style: TextStyle(
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
            Navigator.pop(context);
          },
          tooltip: '뒤로 가기',
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isChecked ? Icons.check : Icons.edit,
              color: Colors.white,
              size: 28,
            ),
            onPressed: () async {
              if (_isChecked) {
                saveChanges();
              }
              setState(() {
                _isChecked = !_isChecked;
              });
            },
            tooltip: _isChecked ? '완료' : '편집',
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
          onReorder: (int oldIndex, int newIndex) {
            setState(() {
              if (oldIndex < newIndex) {
                newIndex -= 1;
              }
              final String item = modifiedCollectionNames.removeAt(oldIndex);
              modifiedCollectionNames.insert(newIndex, item);
            });
          },
          children: <Widget>[
            for (int index = 0; index < filteredCollectionNames.length; index++)
              Padding(
                key: Key('$index'),
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade800,
                    borderRadius: BorderRadius.circular(15.0),
                    border: Border.all(color: Colors.blueGrey.shade700, width: 2),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 5.0, horizontal: 20.0),
                    title: Text(
                      filteredCollectionNames[index],
                      style: const TextStyle(
                        fontSize: 18.0,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Oswald',
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isChecked)
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.white),
                            onPressed: () {
                              deleteBookmark(filteredCollectionNames[index]);
                              setState(() {
                                filteredCollectionNames.removeAt(index);
                                modifiedCollectionNames.removeAt(index); // 삭제 시 수정된 리스트에서도 제거
                              });
                            },
                          ),
                        ReorderableDragStartListener(
                          index: index,
                          child: const Icon(
                            Icons.drag_handle,
                            size: 30.0,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StartRoutinePage(
                            clickroutinename: filteredCollectionNames[index],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
