
import 'package:flutter/material.dart';

class EditContentScreen extends StatelessWidget {
  const EditContentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Content'),
      ),
      body: const Center(
        child: Text('Edit Content Screen'),
      ),
    );
  }
}
