import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import 'memoDetailPage.dart';
import 'memoListProvider.dart';
import 'user_provider.dart';
import 'package:provider/provider.dart';


class MyMemoPage extends StatefulWidget {
  const MyMemoPage({super.key});

  @override
  MyMemoState createState() => MyMemoState();
}

class MyMemoState extends State<MyMemoPage> {
  // 검색어
  String searchText = '';
  String? uid;

  // 플로팅 액션 버튼을 이용하여 항목을 추가할 제목과 내용
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    uid = Provider.of<UserProvider>(context, listen: false).uid;

  }

  // Firestore에서 메모 추가
  Future<void> addMemoToFirestore(String title, String content) async {
    CollectionReference memos = FirebaseFirestore.instance.collection('memos');

    return memos.add({
      'memoTitle': title,
      'memoContent': content,
      'createDate': Timestamp.now(),
      'updateDate': Timestamp.now(),
      'userName': 'User', // 유저 이름을 직접 추가하거나 사용자 인증을 통해 가져올 수 있습니다.
    }).then((value) {
      print("Memo Added");
      // 필요에 따라 추가 처리
    }).catchError((error) {
      print("Failed to add memo: $error");
    });
  }

  // 리스트뷰 카드 클릭 이벤트
  void cardClickEvent(BuildContext context, String docId) async {
    // Firestore에서 문서를 가져와서 수정할 수 있는 상세 페이지로 이동
    DocumentSnapshot document = await FirebaseFirestore.instance.collection('memos').doc(docId).get();
    var content = document.data();

    // 메모 상세 페이지로 이동
    var isMemoUpdate = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContentPage(content: content),
      ),
    );

    // 메모 수정 후 리프레시
    if (isMemoUpdate != null) {
      setState(() {
        // 데이터 새로고침
      });
    }
  }

  // 플로팅 액션 버튼 클릭 이벤트
  Future<void> addItemEvent(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('메모 추가'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: '제목',
                ),
              ),
              TextField(
                controller: contentController,
                maxLines: null, // 다중 라인 허용
                decoration: const InputDecoration(
                  labelText: '내용',
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('추가'),
              onPressed: () async {
                String title = titleController.text;
                String content = contentController.text;

                if (title.isNotEmpty && content.isNotEmpty) {
                  await addMemoToFirestore(title, content);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('메모장'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [  // 검색 기능
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {

            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('memos').snapshots(),
              builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('오류가 발생했습니다.'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final items = snapshot.data!.docs;

                if (items.isEmpty) {
                  return const Center(
                    child: Text(
                      "표시할 메모가 없습니다.",
                      style: TextStyle(fontSize: 20),
                    ),
                  );
                } else {
                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (BuildContext context, int index) {
                      var memoInfo = items[index].data() as Map<String, dynamic>;
                      String userName = memoInfo['userName'] ?? 'User';
                      String memoTitle = memoInfo['memoTitle'] ?? '제목 없음';
                      String memoContent = memoInfo['memoContent'] ?? '';
                      Timestamp createDate = memoInfo['createDate'];
                      Timestamp updateDate = memoInfo['updateDate'];

                      // 검색 기능, 제목으로만 검색
                      if (searchText.isNotEmpty &&
                          !memoTitle.toLowerCase().contains(searchText.toLowerCase())) {
                        return const SizedBox.shrink();
                      } else {
                        return Card(
                          elevation: 3,
                          shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(Radius.elliptical(20, 20))),
                          child: ListTile(
                            leading: Text(userName),
                            title: Text(memoTitle),
                            subtitle: Text(memoContent),
                            trailing: Text(updateDate.toDate().toString()),
                            onTap: () => cardClickEvent(context, items[index].id),
                          ),
                        );
                      }
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
      // 플로팅 액션 버튼
      floatingActionButton: FloatingActionButton(
        heroTag: 'addMemo',
        onPressed: () => addItemEvent(context), // 버튼을 누를 경우 메모 추가 UI 표시
        tooltip: 'Add Item', // 플로팅 액션 버튼 설명
        child: const Icon(Icons.add), // + 모양 아이콘
      ),
    );
  }
}
