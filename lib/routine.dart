import 'package:flutter/material.dart';
import 'create_routine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_provider.dart';
import 'package:provider/provider.dart';
import 'airoutine.dart';

class RoutinePage extends StatefulWidget {
  const RoutinePage({super.key});

  @override
  State<RoutinePage> createState() => _RoutinePageState();
}

class _RoutinePageState extends State<RoutinePage>
    with SingleTickerProviderStateMixin {
  TextEditingController nameController = TextEditingController();
  String _title = '';
  List<String> collectionNames = [];
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showNameInputDialog(context);
    });
    myCollectionName();
  }

  @override
  void dispose() {
    nameController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _updateRoutineTitle(String newTitle) async {
    try {
      DocumentReference docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('Routine')
          .doc('Myroutine');

      DocumentSnapshot documentSnapshot = await docRef.get();

      if (documentSnapshot.exists) {
        var data = documentSnapshot.data() as Map<String, dynamic>;

        if (data.containsKey(_title)) {
          List<dynamic> myRoutineList = data[_title];

          // Remove the old title
          await docRef.update({_title: FieldValue.delete()});

          // Add the new title with the same list
          data.remove(_title);
          data[newTitle] = myRoutineList;

          await docRef.set(data, SetOptions(merge: true));
        }
      }

      setState(() {
        _title = newTitle;
      });
    } catch (e) {
      print('Error updating document: $e');
    }
  }

  Future<void> deleteData(String routineTitle) async {
    try {
      DocumentReference docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('Routine')
          .doc('Myroutine');

      DocumentSnapshot documentSnapshot = await docRef.get();
      print(_title);
      print(routineTitle);

      if (documentSnapshot.exists) {
        var data = documentSnapshot.data() as Map<String, dynamic>;

        if (data.containsKey(_title)) {
          List<dynamic> myRoutineList = data[_title];

          // Find the index of the routine to delete
          int routineIndex = myRoutineList
              .indexWhere((routine) => routine.containsKey(routineTitle));

          // Remove the routine if found
          if (routineIndex != -1) {
            myRoutineList.removeAt(routineIndex);
            await docRef.update({_title: myRoutineList});
          }
        }
      }

      await myCollectionName();
    } catch (e) {
      print('Error deleting document: $e');
    }
  }

  Future<void> deleteAllData(String collectionPath) async {
    try {
      DocumentReference docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('Routine')
          .doc('Myroutine');

      DocumentSnapshot documentSnapshot = await docRef.get();

      if (documentSnapshot.exists) {
        var data = documentSnapshot.data() as Map<String, dynamic>;

        if (data.containsKey(_title)) {
          // Remove the entire collection (_title)
          data.remove(_title);
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

        if (data.containsKey(_title)) {
          List<dynamic> myRoutineList = data[_title];

          List<String> names = [];
          for (var routine in myRoutineList) {
            routine.forEach((key, value) {
              names.add(key);
            });
          }

          setState(() {
            collectionNames = names;
          });
        }
      }
    } catch (e) {
      print('Error fetching collection names: $e');
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
              '루틴 이름 생성',
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
                  _updateRoutineTitle(nameController.text);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Hero(
          tag: 'routine',
          child: Text(
            _title,
            style: TextStyle(
              color: Colors.white,
            ),
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
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('생성을 종료하시겠습니까?',
                      style: TextStyle(color: Colors.white)),
                  backgroundColor: Colors.cyan.shade900,
                  actions: <Widget>[
                    TextButton(
                      child: Text('아니오', style: TextStyle(color: Colors.white)),
                      onPressed: () {
                        Navigator.of(context).pop(); // 팝업 닫기
                      },
                    ),
                    TextButton(
                      child: Text('예', style: TextStyle(color: Colors.white)),
                      onPressed: () {
                        deleteAllData(_title).then((_) {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        });
                      },
                    ),
                  ],
                );
              },
            );
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
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('저장하시겠습니까?',
                            style: TextStyle(color: Colors.white)),
                        backgroundColor: Colors.cyan.shade900,
                        actions: <Widget>[
                          TextButton(
                            child: Text('아니오',
                                style: TextStyle(color: Colors.white)),
                            onPressed: () {
                              Navigator.of(context).pop(); // 팝업 닫기
                            },
                          ),
                          TextButton(
                            child: Text('예',
                                style: TextStyle(color: Colors.white)),
                            onPressed: () {
                              // saveRoutineName();
                              Navigator.of(context).pop();
                              Navigator.of(context).pop(true); // 확인 팝업 닫기
                            },
                          ),
                        ],
                      );
                    },
                  );
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
          padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 30.0),
          onReorder: (int oldIndex, int newIndex) {
            setState(() {
              if (newIndex > oldIndex) {
                newIndex -= 1;
              }
              final String item = collectionNames.removeAt(oldIndex);
              collectionNames.insert(newIndex, item);
            });
          },
          proxyDecorator:
              (Widget child, int index, Animation<double> animation) {
            return Material(
              color: Colors.transparent, // Material 위젯의 color 속성을 직접 조정
              child: child,
              elevation: 0.0,
            );
          },
          children: [
            for (int index = 0; index < collectionNames.length; index++)
              Padding(
                key: Key('$index'),
                padding: const EdgeInsets.symmetric(vertical: 8.0),
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
                              builder: (context) => CreateRoutinePage(
                                myroutinename: _title,
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
              ),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FloatingActionButton.extended(
            heroTag: null,
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
              "수동생성",
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.cyan.shade700,
          ),
          SizedBox(width: 10), // Add some space between the buttons
          FloatingActionButton.extended(
            heroTag: null,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Airoutine(
                    myroutinename: _title,
                  ),
                ),
              ).then((value) {
                if (value == true) {
                  print("루틴 저장 완료");
                  myCollectionName();
                }
              });
            },
            icon: Icon(
              Icons.create,
              color: Colors.white,
            ),
            label: Text(
              "자동생성",
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.cyan.shade700,
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
