// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'memoListProvider.dart';
import 'memoMainPage.dart';

class ContentPage extends StatefulWidget {
  // 생성자 초기화
  final dynamic content;
  const ContentPage({Key? key, required this.content}) : super(key: key);

  @override
  State<ContentPage> createState() => _ContentState(content: content);
}

class _ContentState extends State<ContentPage> {
  // 부모에게 받은 생성자 값 초기화
  final dynamic content;
  _ContentState({required this.content});

  // 메모의 정보를 저장할 변수
  List memoInfo = [];

  // 앱 바 메모 수정 버튼을 이용하여 메모를 수정할 제목과 내용
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();

  // 앱 바 메모 수정 클릭 이벤트
  Future<void> updateItemEvent(BuildContext context) {
    // Firestore에서 해당 메모를 업데이트
    TextEditingController titleController =
    TextEditingController(text: memoInfo[0]['memoTitle']);
    TextEditingController contentController =
    TextEditingController(text: memoInfo[0]['memoContent']);

    // 다이얼로그 폼 열기
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('메모 수정'),
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
              child: const Text('수정'),
              onPressed: () async {
                String memoTitle = titleController.text;
                String memoContent = contentController.text;

                // Firestore에서 메모 업데이트
                await FirebaseFirestore.instance
                    .collection('memos')
                    .doc(memoInfo[0]['id']) // 문서의 id로 찾음
                    .update({
                  'memoTitle': memoTitle,
                  'memoContent': memoContent,
                  'updateDate': Timestamp.now(),
                });

                Navigator.of(context).pop();
                setState(() {
                  // 업데이트된 메모 내용 반영
                  memoInfo[0]['memoTitle'] = memoTitle;
                  memoInfo[0]['memoContent'] = memoContent;
                  memoInfo[0]['updateDate'] = Timestamp.now();
                });
              },
            ),
          ],
        );
      },
    );
  }

  // Firestore에서 메모 삭제 이벤트
  Future<void> deleteMemoEvent(BuildContext context) async {
    // Firestore에서 메모 삭제
    await FirebaseFirestore.instance
        .collection('memos')
        .doc(memoInfo[0]['id']) // 문서의 id로 찾음
        .delete();

    // 메인 페이지로 돌아가기
    Navigator.of(context).pop();
  }

  @override
  void initState() {
    super.initState();
    // 메모 정보를 메모리로 가져옴
    var memo = {
      'id': content['id'],
      'userName': content['userName'],
      'memoTitle': content['memoTitle'],
      'memoContent': content['memoContent'],
      'createDate': content['createDate'],
      'updateDate': content['updateDate'],
    };

    // 메모 리스트 초기화
    List memoList = [];
    memoList.add(memo);

    // 빌드가 완료된 후 Provider의 데이터 읽기
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MemoUpdator>().updateList(memoList);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // 좌측 상단의 뒤로 가기 버튼
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, 1);
          },
        ),
        title: const Text('메모 상세 보기'),
        actions: [
          IconButton(
            onPressed: () => updateItemEvent(context), // 메모 수정 버튼
            icon: const Icon(Icons.edit),
            tooltip: "메모 수정",
          ),
          IconButton(
            onPressed: () => deleteMemoEvent(context), // 메모 삭제 버튼
            icon: const Icon(CupertinoIcons.delete_solid),
            tooltip: "메모 삭제",
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Builder(builder: (context) {
            // 특정 메모 정보 출력
            memoInfo = context.watch<MemoUpdator>().memoList;

            return Stack(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(),
                    Text(
                      memoInfo[0]['memoTitle'],
                      style: const TextStyle(
                          fontSize: 25, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const SizedBox(height: 35),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('작성자 : ${memoInfo[0]['userName']}')
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                            '작성일 : ${memoInfo[0]['createDate'].toDate().toString()}')
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                            '수정일 : ${memoInfo[0]['updateDate'].toDate().toString()}')
                      ],
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: SizedBox(
                          height: double.infinity,
                          width: double.infinity,
                          child: Text(
                            memoInfo[0]['memoContent'],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
