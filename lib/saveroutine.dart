import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SaveRoutinePage extends StatefulWidget {
  const SaveRoutinePage({super.key});

  @override
  State<SaveRoutinePage> createState() => _SaveRoutinePageState();
}

class _SaveRoutinePageState extends State<SaveRoutinePage> {
  List<String> collectionNames = [];

  //  void myCollectionName() async {
  //   try {
  //     // '_title' 컬렉션에서 하위 문서 ID들 가져오기
  //     QuerySnapshot querySnapshot = await FirebaseFirestore.instance
  //         .collection(nameController.text)
  //         .get();
  //     List<String> names = querySnapshot.docs.map((doc) => doc.id).toList();

  //     setState(() {
  //       collectionNames = names;
  //     });
  //   } catch (e) {
  //     print('Error fetching collection names: $e');
  //   }
  // }

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
          IconButton(
            icon: Icon(
              Icons.edit,
              color: Colors.white,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: Container(
        color: Colors.black,
      ),
    );
  }
}
