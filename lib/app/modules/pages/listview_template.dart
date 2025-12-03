import 'package:flutter/material.dart';

class ListviewTemplate extends StatefulWidget {
  const ListviewTemplate({super.key});

  @override
  State<ListviewTemplate> createState() => _ListviewTemplateState();
}

class _ListviewTemplateState extends State<ListviewTemplate> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text('Item $index'),
        );
      },
    );
  }
}
