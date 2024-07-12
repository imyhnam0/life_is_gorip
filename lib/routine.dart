import 'package:flutter/material.dart';
import 'create_routine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_provider.dart';
import 'package:provider/provider.dart';

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

  Future<void> deleteData(String documentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection("Routine")
          .doc('Myroutine')
          .collection(_title)
          .doc(documentId)
          .delete();
      await myCollectionName();
    } catch (e) {
      print('Error deleting document: $e');
    }
  }

  Future<void> deleteCollection(String collectionPath) async {
    try {
      var collectionRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection("Routine")
          .doc('Myroutine')
          .collection(collectionPath);

      var snapshots = await collectionRef.get();

      for (var doc in snapshots.docs) {
        await doc.reference.delete();
      }

      await myCollectionName();
    } catch (e) {
      print('Error deleting collection: $e');
    }
  }

  Future<void> myCollectionName() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('Routine')
          .doc('Myroutine')
          .collection(_title)
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
                    myCollectionName(); // 이름 설정 후 컬렉션 이름 가져오기
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

  Future<void> saveRoutineName() async {
    var db = FirebaseFirestore.instance;

    if (nameController.text.isNotEmpty) {
      try {
        int order = collectionNames.length + 1; // 새로운 order 값 설정
        await db
            .collection('users')
            .doc(uid)
            .collection('Routine')
            .doc('Routinename')
            .collection('Names')
            .add({
          'name': nameController.text,
          'order': order,
        });
      } catch (e) {
        print('Error adding document: $e');
      }
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
                        deleteCollection(_title).then((_) {
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
                              saveRoutineName();
                              Navigator.of(context).pop(); 
                              Navigator.of(context).pop(true);// 확인 팝업 닫기
                              
                              
                              
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
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
