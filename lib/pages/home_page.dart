import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Get the currently logged-in user
  late final User? _user = FirebaseAuth.instance.currentUser;

  // Controllers for item name and quantity input fields
  final _itemController = TextEditingController();
  final _quantityController = TextEditingController();

  // Reference to the Firestore collection for the user's grocery items
  late final CollectionReference? _itemsRef =
      _user != null
          ? FirebaseFirestore.instance
              .collection('users')
              .doc(_user!.uid)
              .collection('groceryItems')
          : null;

  @override
  void dispose() {
    // Dispose controllers to free up resources
    _itemController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  // Add a new item to the Firestore collection
  Future<void> _addItem() async {
    if (_itemsRef == null) return;

    final name = _itemController.text.trim();
    final qtyText = _quantityController.text.trim();
    if (name.isEmpty || qtyText.isEmpty) return;

    final quantity = int.tryParse(qtyText) ?? 1;

    await _itemsRef!.add({
      'name': name,
      'quantity': quantity,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Clear input fields after adding the item
    _itemController.clear();
    _quantityController.clear();
  }

  // Remove an item from the Firestore collection
  Future<void> _removeItem(String docId) async {
    if (_itemsRef == null) return;
    await _itemsRef!.doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    // If no user is logged in, display a message
    if (_user == null) {
      return Scaffold(
        body: Center(child: Text('No user is currently logged in.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Grocery List',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade400, Colors.indigo.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          // Logout button
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo.shade50, Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              // Display the list of grocery items
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _itemsRef!.orderBy('timestamp').snapshots(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    final docs = snap.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return Center(
                        child: Text(
                          'Your list is empty',
                          style: TextStyle(fontSize: 18),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: docs.length,
                      itemBuilder: (context, i) {
                        final doc = docs[i];
                        final data = doc.data()! as Map<String, dynamic>;
                        final name = data['name'] as String;
                        final qty = data['quantity'] as int;
                        return Card(
                          elevation: 4,
                          margin: EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            title: Text(name, style: TextStyle(fontSize: 20)),
                            subtitle: Text(
                              'Quantity: $qty',
                              style: TextStyle(fontSize: 16),
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                              ),
                              onPressed: () => _removeItem(doc.id),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              // Input fields and button to add a new item
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 8,
                      color: Colors.black12,
                      offset: Offset(0, -2),
                    ),
                  ],
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    // Input field for item name
                    Expanded(
                      child: TextField(
                        controller: _itemController,
                        decoration: InputDecoration(
                          hintText: 'Add item',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          fillColor: Colors.grey.shade200,
                          filled: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    // Input field for item quantity
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Qty',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          fillColor: Colors.grey.shade200,
                          filled: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    // Button to add the item
                    ElevatedButton(
                      onPressed: _addItem,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        backgroundColor: Colors.indigo.shade600,
                      ),
                      child: Text(
                        'Add',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
