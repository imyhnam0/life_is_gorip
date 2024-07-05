import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'start_routine.dart';

class BookMarkPage extends StatefulWidget {
  @override
  State<BookMarkPage> createState() => _BookMarkPageState();
}

class _BookMarkPageState extends State<BookMarkPage> {
  List<String> collectionNames = [];
  List<String> savedCollectionNames = [];
  List<String> filteredCollectionNames = [];

  bool _isChecked = false;

  @override
  void initState() {
    super.initState();
    myCollectionName();
    loadStarRow();
  }

  Future<void> updateFirestoreOrder(List<String> updatedCollectionNames) async {
    try {
      // Bookmark 문서를 참조합니다.
      DocumentReference bookmarkDocRef =
          FirebaseFirestore.instance.collection("Routine").doc('Bookmark');

      // Bookmark 문서를 가져와서 names 필드를 업데이트합니다.
      DocumentSnapshot bookmarkDocSnapshot = await bookmarkDocRef.get();

      if (bookmarkDocSnapshot.exists) {
        // 변경된 순서를 names 필드에 반영합니다.
        await bookmarkDocRef.update({'names': updatedCollectionNames});
      } else {
        // Bookmark 문서가 존재하지 않을 경우, 새로 생성합니다.
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
        }
      }
    } catch (e) {
      print('Error removing name: $e');
    }
  }

  void myCollectionName() async {
    try {
      // '_title' 컬렉션에서 하위 문서 ID들 가져오기
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
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
          FirebaseFirestore.instance.collection("Routine").doc('Bookmark');

      DocumentSnapshot bookmarkDocSnapshot = await bookmarkDocRef.get();

      if (bookmarkDocSnapshot.exists) {
        List<dynamic> names = bookmarkDocSnapshot.get('names');
        setState(() {
          filteredCollectionNames = List<String>.from(names);
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
            onPressed: () {
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
          onReorder: (int oldIndex, int newIndex) async {
            setState(() {
              if (oldIndex < newIndex) {
                newIndex -= 1;
              }
              final String item = filteredCollectionNames.removeAt(oldIndex);
              filteredCollectionNames.insert(newIndex, item);
            });
            await updateFirestoreOrder(filteredCollectionNames);
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
