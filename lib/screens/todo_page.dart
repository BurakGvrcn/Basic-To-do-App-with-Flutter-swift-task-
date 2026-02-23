import 'package:flutter/material.dart';
import '../models/task.dart';

class TodoPage extends StatelessWidget {
  final String name;
  final List<Task> tasks;
  final Function(int) onDelete;
  final Function(int) onToggle;

  const TodoPage({
    super.key,
    required this.name,
    required this.tasks,
    required this.onDelete,
    required this.onToggle,
  });

  String _formatDate(DateTime dt) {
    return "${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("To-do List"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const Text(
                  "Hello",
                  style: TextStyle(fontSize: 24, color: Colors.grey),
                ),
                Text(
                  name.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: tasks.isEmpty
                ? const Center(child: Text("No tasks yet. Add one!"))
                : ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return Dismissible(
                        key: UniqueKey(),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) {
                          onDelete(index);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${task.title} erased'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 5,
                          ),
                          color: task.isCompleted
                              ? Colors.grey.shade200
                              : Colors.white,
                          child: CheckboxListTile(
                            value: task.isCompleted,
                            onChanged: (value) => onToggle(index),
                            title: Text(
                              task.title,
                              style: TextStyle(
                                decoration: task.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: task.isCompleted
                                    ? Colors.grey
                                    : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: task.date != null
                                ? Text(
                                    "⏰ ${_formatDate(task.date!)}",
                                    style: TextStyle(
                                      color: task.isCompleted
                                          ? Colors.grey
                                          : Colors.blueGrey,
                                      fontSize: 12,
                                    ),
                                  )
                                : null,
                            secondary: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => onDelete(index),
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
