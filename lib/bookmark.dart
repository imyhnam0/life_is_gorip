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
          ), // Icons.list 대신 Icons.menu를 사용
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
              setState(() {
                _isChecked = !_isChecked;
              });
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
              offset: Offset(0, 3), // changes position of shadow
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
                                clickroutinename:
                                    filteredCollectionNames[index],
                              ),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              filteredCollectionNames[index],
                              style: TextStyle(
                                fontSize: 18.0,
                                color: Colors.white,
                              ),
                            ),
                            Visibility(
                              visible: _isChecked,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 200.0),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    deleteBookmark(
                                        filteredCollectionNames[index]);
                                    setState(() {
                                      filteredCollectionNames.removeAt(index);
                                    });
                                  },
                                ),
                              ),
                            ),
                            ReorderableDragStartListener(
                              index: index,
                              child: Container(
                                padding: const EdgeInsets.all(8.0),
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
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
