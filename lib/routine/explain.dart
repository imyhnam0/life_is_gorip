import 'package:flutter/material.dart';

class ExplainPage extends StatefulWidget {
  const ExplainPage({super.key});

  @override
  State<ExplainPage> createState() => _ExplainPageState();
}

class _ExplainPageState extends State<ExplainPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explain Page', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueGrey.shade700,
        leading:  IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
      ),
      ),
      body: Container(
  color: Colors.blueGrey.shade900, // 배경색 설정
  child:Padding(
     
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const RoutineExplainPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey.shade700,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: const Text('루틴 설명', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const FoodExplainPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey.shade700,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: const Text('식단 설명', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                // 사진첩 설명 버튼 클릭 시 수행할 작업
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey.shade700,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: const Text('사진첩 설명', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                // 친구 관리 설명 버튼 클릭 시 수행할 작업
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey.shade700,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: const Text('친구 관리 설명', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class RoutineExplainPage extends StatefulWidget {
  const RoutineExplainPage({super.key});

  @override
  State<RoutineExplainPage> createState() => _RoutineExplainPageState();
}

class _RoutineExplainPageState extends State<RoutineExplainPage> {
  final PageController _pageController = PageController();
  final List<String> _images = [
    'assets/routine_1.png',
    'assets/routine_2.png',
    'assets/routine_3.png',
    'assets/routine_4.png',
    'assets/routine_5.png',
    'assets/routine_6.png',
    'assets/routine_7.png',
    'assets/routine_8.png',
    'assets/routine_9.png',
    'assets/routine_10.png',
    'assets/routine_11.png',
    'assets/routine_12.png',
    'assets/routine_13.png',
    'assets/routine_14.png',
  ];

  int _currentPage = 0;

  void _nextPage() {
    if (_currentPage < _images.length - 1) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() {
        _currentPage++;
      });
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() {
        _currentPage--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('루틴 설명', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueGrey.shade900,
        leading:  IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },  
      ),),
      body: Container(
  decoration: BoxDecoration(
    color: Colors.blueGrey.shade900, // 여기에 원하는 배경색을 지정하세요.
  ),
  child: Stack(
    children: [
      PageView.builder(
        controller: _pageController,
        itemCount: _images.length,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(_images[index]),
              ),
            ),
          );
        },
      ),
      Positioned(
        left: 16.0,
        top: MediaQuery.of(context).size.height / 2 - 24,
        child: IconButton(
          onPressed: _previousPage,
          icon: Icon(Icons.arrow_left, size: 48.0, color: Colors.white),
          color: Colors.black.withOpacity(0.3),
          padding: EdgeInsets.all(8.0),
          splashColor: Colors.transparent,
        ),
      ),
      Positioned(
        right: 16.0,
        top: MediaQuery.of(context).size.height / 2 - 24,
        child: IconButton(
          onPressed: _nextPage,
          icon: Icon(Icons.arrow_right, size: 48.0, color: Colors.white),
          color: Colors.black.withOpacity(0.3),
          padding: EdgeInsets.all(8.0),
          splashColor: Colors.transparent,
        ),
      ),
    ],
  ),
    ),
    );
  }
}


class FoodExplainPage extends StatefulWidget {
  const FoodExplainPage({super.key});

  @override
  State<FoodExplainPage> createState() => _FoodExplainPageState();
}

class _FoodExplainPageState extends State<FoodExplainPage> {
  final PageController _pageController = PageController();
  final List<String> _images = [
    'assets/food_1.png',
    'assets/food_2.png',
    'assets/food_3.png',
    'assets/food_4.png',
    'assets/food_5.png',
    'assets/food_6.png',
    'assets/food_7.png',
    'assets/food_8.png',
    'assets/food_9.png',
    'assets/food_10.png',
    'assets/food_11.png',
    'assets/food_12.png',
    'assets/food_13.png',
    'assets/food_14.png',
  ];

  int _currentPage = 0;

  void _nextPage() {
    if (_currentPage < _images.length - 1) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() {
        _currentPage++;
      });
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() {
        _currentPage--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('루틴 설명', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueGrey.shade900,
        leading:  IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },  
      ),),
      body: Container(
  decoration: BoxDecoration(
    color: Colors.blueGrey.shade900, // 여기에 원하는 배경색을 지정하세요.
  ),
  child: Stack(
    children: [
      PageView.builder(
        controller: _pageController,
        itemCount: _images.length,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(_images[index]),
              ),
            ),
          );
        },
      ),
      Positioned(
        left: 16.0,
        top: MediaQuery.of(context).size.height / 2 - 24,
        child: IconButton(
          onPressed: _previousPage,
          icon: Icon(Icons.arrow_left, size: 48.0, color: Colors.white),
          color: Colors.black.withOpacity(0.3),
          padding: EdgeInsets.all(8.0),
          splashColor: Colors.transparent,
        ),
      ),
      Positioned(
        right: 16.0,
        top: MediaQuery.of(context).size.height / 2 - 24,
        child: IconButton(
          onPressed: _nextPage,
          icon: Icon(Icons.arrow_right, size: 48.0, color: Colors.white),
          color: Colors.black.withOpacity(0.3),
          padding: EdgeInsets.all(8.0),
          splashColor: Colors.transparent,
        ),
      ),
    ],
  ),
    ),
    );
  }
}


