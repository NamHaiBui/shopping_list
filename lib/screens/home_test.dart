import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';

import '../data/categories.dart';

class HomeScreens extends StatefulWidget {
  const HomeScreens({super.key});

  @override
  State<HomeScreens> createState() => _HomeScreensState();
}

class _HomeScreensState extends State<HomeScreens> {
  final List<GroceryItem> _groceryItems = [];

  late Future<List<GroceryItem>> _loadedItems;

  @override
  void initState() {
    super.initState();
    _loadedItems = _loadItem();
//
  }

  Future<List<GroceryItem>> _loadItem() async {
    final url = Uri.https(
        'shoppinglist-95f21-default-rtdb.firebaseio.com', 'shopping-list.json');

    final response = await http.get(url);
    if (response.statusCode >= 400) {
      throw Exception('Failed to fetch data. Please try again later');
      // setState(() => _error = 'Failed to fetch data. Please try again later');
    }
    if (response.body == 'null') {
      // setState(() {
      //   _isLoading = false;
      // });
      return [];
    }

    final Map<String, dynamic> listData = json.decode(response.body);
    final List<GroceryItem> loadedItems = [];
    for (final item in listData.entries) {
      final category = categories.entries
          .firstWhere(
              (catItem) => catItem.value.title == item.value['category'])
          .value;
      loadedItems.add(GroceryItem(
          id: item.key,
          name: item.value['name'],
          quantity: item.value['quantity'],
          category: category));
    }
    return loadedItems;
    // setState(() => _error = 'Something went wrong. Please try again later');
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
        MaterialPageRoute(builder: (ctx) => const NewItem()));
    if (newItem == null) {
      return;
    }
  }

  Future<void> _removeItem(item) async {
    final index = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems.remove(item);
    });
    final url = Uri.https('shoppinglist-95f21-default-rtdb.firebaseio.com',
        'shopping-list/${item.id}.json');
    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      setState(() {
        _groceryItems.insert(index, item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Your Groceries',
              style: Theme.of(context).textTheme.titleLarge),
          actions: [
            IconButton(
              onPressed: _addItem,
              icon: const Icon(Icons.add),
            )
          ],
        ),
        body: FutureBuilder(
            future: _loadedItems,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    snapshot.error.toString(),
                  ),
                );
              }
              if (snapshot.data!.isEmpty) {
                return const Text(
                  "Oops! Your shopping list is empty \n try adding something!",
                  style: TextStyle(color: Colors.white, fontSize: 15),
                  textAlign: TextAlign.center,
                );
              }
              return ListView.builder(
                  itemBuilder: (ctx, index) {
                    return Dismissible(
                      key: ValueKey(snapshot.data![index].id),
                      onDismissed: (direction) {
                        _removeItem(snapshot.data![index]);
                      },
                      child: ListTile(
                          title: Text(snapshot.data![index].name),
                          leading: Container(
                              width: 24,
                              height: 24,
                              color: snapshot.data![index].category.color),
                          trailing:
                              Text(snapshot.data![index].quantity.toString())),
                    );
                  },
                  itemCount: snapshot.data!.length);
            }));
  }
}
