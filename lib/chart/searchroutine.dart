import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/user_provider.dart';
import 'RoutineChartPage.dart';


class SearchRoutinePage extends StatefulWidget {
  const SearchRoutinePage({super.key});

  @override
  State<SearchRoutinePage> createState() => _SearchRoutinePageState();
}

class _SearchRoutinePageState extends State<SearchRoutinePage> {
  TextEditingController _controller = TextEditingController();
  String? uid;
  List<String> allRoutines = [];
  List<String> filteredRoutines = [];

  @override
  void initState() {
    super.initState();
    uid = Provider.of<UserProvider>(context, listen: false).uid;
    loadRoutineList();
  }

  Future<void> loadRoutineList() async {
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("Routine")
        .doc("Routinename")
        .get();

    if (doc.exists) {
      List<String> routines = List<String>.from(doc['details'] ?? []);
      setState(() {
        allRoutines = routines;
        filteredRoutines = routines;
      });
    }
  }

  void filter(String input) {
    setState(() {
      filteredRoutines = allRoutines
          .where((r) => r.toLowerCase().contains(input.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade900,
      appBar: AppBar(
        title: Text('루틴 검색', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueGrey.shade900,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 실시간 검색창
            TextField(
              controller: _controller,
              onChanged: filter,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '운동 루틴명을 입력하세요',
                hintStyle: TextStyle(color: Colors.white60),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.cyan),
                ),
              ),
            ),
            SizedBox(height: 20),

            // 루틴 리스트
            Expanded(
              child: filteredRoutines.isEmpty
                  ? Center(
                child: Text(
                  "일치하는 루틴이 없습니다.",
                  style: TextStyle(color: Colors.white70),
                ),
              )
                  : ListView.builder(
                itemCount: filteredRoutines.length,
                itemBuilder: (context, index) {
                  final routine = filteredRoutines[index];
                  return Card(
                    color: Colors.white10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(routine,
                          style: TextStyle(color: Colors.white)),
                      trailing: Icon(Icons.arrow_forward_ios,
                          color: Colors.cyan),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RoutineChartPage(
                                routineName: routine),
                          ),
                        );

                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
