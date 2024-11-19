import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Back4App
  const appId = "E8reLkHX4xTdjGiRZJDDlktQUGqj96JFWh2F7PBx";
  const clientKey = "Xz5qC54SbGY1wzztDxJlH74XqDsYlTMgswD7Kc9e";
  const serverUrl = "https://parseapi.back4app.com/";

  await Parse().initialize(appId, serverUrl, clientKey: clientKey, autoSendSessionId: true);
  
  runApp(QuickTaskApp());
}

class QuickTaskApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuickTask',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginPage(),
    );
  }
}

// Login Page
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  Future<void> login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    final user = ParseUser(username, password, null);
    final response = await user.login();

    if (response.success) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => TaskPage()));
    } else {
      _showMessage("Login failed: ${response.error!.message}");
    }
  }

  Future<void> signUp() async {
  final username = _usernameController.text.trim();
  final password = _passwordController.text.trim();
  final email = _emailController.text.trim(); // Get the email address

  final user = ParseUser(username, password, email);
  final response = await user.signUp();

  if (response.success) {
    _showMessage("Sign up successful! Please log in.");
  } else {
    _showMessage("Sign up failed: ${response.error!.message}");
  }
}

  void _showMessage(String message) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              content: Text(message),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context), child: Text('OK'))
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('QuickTask Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            SizedBox(height: 16),
            ElevatedButton(onPressed: login, child: Text('Log In')),
            TextButton(onPressed: signUp, child: Text('Sign Up'))
          ],
        ),
      ),
    );
  }
}

// Task Page
class TaskPage extends StatefulWidget {
  @override
  _TaskPageState createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();

  Future<List<ParseObject>> fetchTasks() async {
  // Get the current user asynchronously
  final user = await ParseUser.currentUser() as ParseUser?;

  if (user == null) {
    // Handle the case where no user is logged in
    print("No user logged in");
    return [];
  }

  // Build query for tasks
  final query = QueryBuilder<ParseObject>(ParseObject('Task'))
    ..whereEqualTo('user', user)
    ..orderByAscending('dueDate');

  final response = await query.query();

  if (response.success && response.results != null) {
    return response.results as List<ParseObject>;
  }
  return [];
}


  Future<void> addTask() async {
  final title = _titleController.text.trim();
  final dueDate = DateTime.parse(_dueDateController.text.trim());

  // Resolve the current user asynchronously
  final user = await ParseUser.currentUser() as ParseUser?;

  if (user == null) {
    // Handle the case where no user is logged in
    print("No user is logged in. Cannot add task.");
    return;
  }

  final task = ParseObject('Task')
    ..set('title', title)
    ..set('dueDate', dueDate)
    ..set('isCompleted', false)
    ..set('user', user); // Attach the current user to the task

  final response = await task.save();

  if (response.success) {
    // Task saved successfully
    print("Task added: ${response.result}");
    setState(() {}); // Refresh the task list
  } else {
    // Handle save error
    print("Failed to save task: ${response.error!.message}");
  }
}


  Future<void> toggleTaskStatus(ParseObject task) async {
    task.set('isCompleted', !(task.get<bool>('isCompleted')!));
    await task.save();
    setState(() {});
  }

  Future<void> deleteTask(ParseObject task) async {
    await task.delete();
    setState(() {});
  }

  Future<void> editTask(ParseObject task) async {
  final TextEditingController titleController = 
      TextEditingController(text: task.get<String>('title')!);
  final TextEditingController dueDateController = 
      TextEditingController(
          text: task.get<DateTime>('dueDate')!.toLocal().toIso8601String());

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Edit Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: 'Task Title'),
            ),
            TextField(
              controller: dueDateController,
              decoration: InputDecoration(labelText: 'Due Date (YYYY-MM-DD)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Cancel editing
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Update the task fields
              task
                ..set('title', titleController.text.trim())
                ..set('dueDate', DateTime.parse(dueDateController.text.trim()));

              final response = await task.save(); // Save changes to Back4App

              if (response.success) {
                print("Task updated successfully.");
                setState(() {}); // Refresh the task list
              } else {
                print("Failed to update task: ${response.error!.message}");
              }

              Navigator.pop(context); // Close the dialog
            },
            child: Text('Save'),
          ),
        ],
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('QuickTask')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: 'Task Title'),
                ),
                TextField(
                  controller: _dueDateController,
                  decoration: InputDecoration(labelText: 'Due Date (YYYY-MM-DD)'),
                ),
                SizedBox(height: 16),
                ElevatedButton(onPressed: addTask, child: Text('Add Task')),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<ParseObject>>(
              future: fetchTasks(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                final tasks = snapshot.data!;
                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return ListTile(
                      title: Text(task.get<String>('title')!),
                      subtitle: Text(task.get<DateTime>('dueDate')!.toLocal().toString()),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                           IconButton(
                               icon: Icon(Icons.edit),
                               onPressed: () => editTask(task)),
                          Checkbox(
                              value: task.get<bool>('isCompleted'),
                              onChanged: (_) => toggleTaskStatus(task)),
                          IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () => deleteTask(task)),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
