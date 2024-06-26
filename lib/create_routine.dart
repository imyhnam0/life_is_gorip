import 'package:flutter/material.dart';

class CreateRoutinePage extends StatefulWidget {
  const CreateRoutinePage({super.key});

  @override
  _CreateRoutinePageState createState() => _CreateRoutinePageState();
}

class _CreateRoutinePageState extends State<CreateRoutinePage> {
  String _title = '';
  List<Widget> _rows = [];
  int _counter = 1;

  @override
  // void initState() {
  //   super.initState();
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     _showNameInputDialog(context);
  //   });
  // }
  // 초기 이름 뜨게 해주는 창 일단 비활성화

  void _showNameInputDialog(BuildContext context) {
    TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey,
          title: Text(
            '루틴 이름 입력',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(
              hintText: "이름을 입력하세요",
              hintStyle: TextStyle(color: Colors.grey), // 힌트 텍스트 색상
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.red), // 기본 상태의 밑줄 색상
              ),
              fillColor: Colors.white, // 텍스트 필드 배경 색상
              filled: true,
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
              },
            ),
            TextButton(
              child: Text(
                '확인',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                setState(() {
                  _title = nameController.text;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _addTextFields() {
    setState(() {
      _rows.add(
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(
                padding: EdgeInsets.all(16.0),
                color: Colors.red,
                child: Text(
                  '$_counter',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              SizedBox(width: 10),
              CreateTextField(hintText: "무게를 입력하세요"),
              SizedBox(width: 10),
              CreateTextField(hintText: "횟수를 입력하세요"),
            ],
          ),
        ),
      );
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            _title,
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
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.account_box,
                color: Colors.white,
              ),
              onPressed: () {
                print('Search icon pressed');
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            Container(
              color: Colors.black,
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: _rows,
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Container(
                margin: EdgeInsets.only(left: 40.0, bottom: 20.0), // margin 추가
                width: 200, // FloatingActionButton의 너비 조정
                height: 60,
                child: FloatingActionButton(
                  onPressed: () {
                    _addTextFields();
                  },
                  child: Icon(Icons.add),
                  backgroundColor: Colors.red, // 버튼의 배경색을 설정합니다.
                ),
              ),
            ),
            Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  margin:
                      EdgeInsets.only(right: 40.0, bottom: 20.0), // margin 추가
                  width: 200, // FloatingActionButton의 너비 조정
                  height: 60,
                  child: FloatingActionButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Icon(Icons.save),
                    backgroundColor: Colors.red, // 버튼의 배경색을 설정합니다.
                  ),
                )),
          ],
        ));
  }
}

class CreateTextField extends StatelessWidget {
  final String hintText;

  const CreateTextField({Key? key, required this.hintText}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TextField(
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.red),
          ),
          fillColor: Colors.white,
          filled: true,
        ),
      ),
    );
  }
}
