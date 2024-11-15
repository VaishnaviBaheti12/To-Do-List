import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // Import for date formatting
import 'package:speech_to_text/speech_to_text.dart' as stt; // Speech-to-text package

void main() {
  runApp(ToDoApp());
}

class ToDoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ToDoListPage(),
    );
  }
}

class ToDoListPage extends StatefulWidget {
  @override
  _ToDoListPageState createState() => _ToDoListPageState();
}

class _ToDoListPageState extends State<ToDoListPage> {
  List<Map<String, String>> todoLists = [];
  List<Map<String, String>> filteredLists = [];
  stt.SpeechToText _speechToText = stt.SpeechToText(); // Initialize speech-to-text
  bool _isListening = false;
  String _taskInput = '';

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  // Load tasks from shared_preferences
  void loadTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? storedTasks = prefs.getStringList('tasks');
    List<String>? storedDates = prefs.getStringList('dates');

    if (storedTasks != null && storedDates != null) {
      setState(() {
        for (int i = 0; i < storedTasks.length; i++) {
          todoLists.add({
            'task': storedTasks[i],
            'dueDate': storedDates[i],
          });
        }
        filteredLists = todoLists;
      });
    }
  }

  // Save tasks to shared_preferences
  void saveTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> tasks = todoLists.map((taskMap) => taskMap['task']!).toList();
    List<String> dates = todoLists.map((taskMap) => taskMap['dueDate']!).toList();
    prefs.setStringList('tasks', tasks);
    prefs.setStringList('dates', dates);
  }

  // Function to delete task
  void deleteTask(int index) {
    setState(() {
      todoLists.removeAt(index);
      filteredLists = todoLists;
    });
    saveTasks();
  }

  // Start listening to mic input
  void _listen() async {
    if (!_isListening) {
      bool available = await _speechToText.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speechToText.listen(onResult: (val) {
          setState(() {
            _taskInput = val.recognizedWords;
          });
        });
      }
    } else {
      setState(() => _isListening = false);
      _speechToText.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(
        title: Text('To-Do List'),
        actions: [
          IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {
              _openMenu(context); // Open the menu when clicked
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: filteredLists.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                    filteredLists[index]['task']!,
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    'Due: ${filteredLists[index]['dueDate']!}',
                    style: TextStyle(color: Colors.white70),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.white),
                    onPressed: () {
                      deleteTask(index);
                    },
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TaskDetailPage(
                          task: filteredLists[index]['task']!,
                          dueDate: filteredLists[index]['dueDate']!,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SizedBox(height: 10), // Space between the ListView and the input section
          Padding(
            padding: const EdgeInsets.all(90.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: _taskInput),
                    onChanged: (val) {
                      setState(() {
                        _taskInput = val;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Enter Quick Task Here',
                      prefixIcon: Icon(Icons.task),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                  onPressed: _listen,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 40.0), // Add space to the bottom of the screen
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddTaskPage(onTaskAdded: (newTask, dueDate) {
                setState(() {
                  todoLists.add({'task': newTask, 'dueDate': dueDate});
                  filteredLists = todoLists;
                });
                saveTasks();
              })),
            );
          },
          child: Icon(Icons.add),
        ),
      ),
    );
  }

  void _openMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          height: 300, // Set a height for the bottom sheet
          child: ListView(
            children: [
              ListTile(
                title: Text('Task Lists'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TaskListPage()),
                ),
              ),
              ListTile(title: Text('Add in Batch Mode')),
              ListTile(title: Text('Remove Ads')),
              ListTile(title: Text('More Apps')),
              ListTile(title: Text('Send Feedback')),
              ListTile(title: Text('Follow Us')),
              ListTile(title: Text('Invite Friends')),
              ListTile(title: Text('Settings')),
            ],
          ),
        );
      },
    );
  }
}

class TaskDetailPage extends StatelessWidget {
  final String task;
  final String dueDate;

  TaskDetailPage({required this.task, required this.dueDate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue, // Set background color to blue
      appBar: AppBar(title: Text('Task Details')),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Task: $task', style: TextStyle(fontSize: 20, color: Colors.blue)),
            SizedBox(height: 15),
            Text('Due Date: $dueDate', style: TextStyle(fontSize: 20, color: Colors.blue)),
          ],
        ),
      ),
    );
  }
}

class AddTaskPage extends StatefulWidget {
  final Function(String, String) onTaskAdded;

  AddTaskPage({required this.onTaskAdded});

  @override
  _AddTaskPageState createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  TextEditingController taskController = TextEditingController();
  String dueDate = 'Due date';
  DateTime selectedDate = DateTime.now();

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        dueDate = DateFormat('yyyy-MM-dd').format(selectedDate);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue, // Set background color to blue
      appBar: AppBar(
        title: Text('Add New Task'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: taskController,
              decoration: InputDecoration(hintText: "Enter task name"),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Text(dueDate),
                Spacer(),
                ElevatedButton(
                  onPressed: () => _selectDate(context),
                  child: Text('Select Date'),
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                widget.onTaskAdded(taskController.text, dueDate);
                Navigator.pop(context);
              },
              child: Text("Add Task"),
            ),
          ],
        ),
      ),
    );
  }
}

class TaskListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Task Lists')),
      body: Center(
        child: Text('Task List Page'),
      ),
    );
  }
}