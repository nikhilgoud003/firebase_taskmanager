import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CW06 Tasks',
      home: AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasData) {
          return TaskListScreen();
        } else {
          return LoginScreen();
        }
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  Future<void> login() async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: emailController.text,
      password: passwordController.text,
    );
  }

  Future<void> register() async {
    await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: emailController.text,
      password: passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'Email')),
            TextField(
                controller: passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true),
            Row(
              children: [
                ElevatedButton(onPressed: login, child: Text('Login')),
                SizedBox(width: 10),
                ElevatedButton(onPressed: register, child: Text('Register')),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class TaskListScreen extends StatefulWidget {
  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final taskController = TextEditingController();
  String selectedPriority = 'Medium';
  final user = FirebaseAuth.instance.currentUser!;

  CollectionReference get tasks => FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('tasks');

  Future<void> addTask() async {
    await tasks.add({
      'title': taskController.text,
      'completed': false,
      'priority': selectedPriority,
      'timestamp': FieldValue.serverTimestamp(),
    });
    taskController.clear();
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Tasks'),
        actions: [IconButton(onPressed: logout, icon: Icon(Icons.logout))],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: taskController,
                    decoration: InputDecoration(labelText: 'Task'),
                  ),
                ),
                DropdownButton<String>(
                  value: selectedPriority,
                  items: ['High', 'Medium', 'Low']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) => setState(() => selectedPriority = val!),
                ),
                IconButton(onPressed: addTask, icon: Icon(Icons.add))
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: tasks.orderBy('timestamp').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();
                final docs = snapshot.data!.docs;
                return ListView(
                  children: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return ListTile(
                      leading: Checkbox(
                        value: data['completed'],
                        onChanged: (val) {
                          doc.reference.update({'completed': val});
                        },
                      ),
                      title: Text(data['title']),
                      subtitle: Text('Priority: ${data['priority']}'),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => doc.reference.delete(),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
