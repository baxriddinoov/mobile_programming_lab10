import 'package:flutter/material.dart';
import 'package:tm_classifier/models/classification_record.dart';
import 'package:tm_classifier/screens/history_screen.dart';
import 'package:tm_classifier/screens/home_screen.dart';
import 'package:tm_classifier/screens/model_screen.dart';
import 'package:tm_classifier/services/classifier.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({
    super.key,
    required this.classifier,
  });

  final Classifier classifier;

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;
  final List<ClassificationRecord> _history = [];
  ClassificationRecord? _mostRecentRecord;

  void _handleRecordAdded(ClassificationRecord record) {
    setState(() {
      _history.insert(0, record); // Newest first
      _mostRecentRecord = record;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        classifier: widget.classifier,
        onRecordAdded: _handleRecordAdded,
        mostRecentRecord: _mostRecentRecord,
      ),
      HistoryScreen(history: _history),
      ModelScreen(classifier: widget.classifier),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.info_outline),
            selectedIcon: Icon(Icons.info),
            label: 'Model',
          ),
        ],
      ),
    );
  }
}
