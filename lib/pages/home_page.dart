import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final User? _user = FirebaseAuth.instance.currentUser;
  final _itemController = TextEditingController();
  final _quantityController = TextEditingController();

  late final CollectionReference? _itemsRef = _user != null
      ? FirebaseFirestore.instance
      .collection('users')
      .doc(_user!.uid)
      .collection('groceryItems')
      : null;

  List<String> _aiPredictions = [];

  @override
  void dispose() {
    _itemController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

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

    _itemController.clear();
    _quantityController.clear();
  }

  Future<void> _removeItem(String docId) async {
    if (_itemsRef == null) return;
    await _itemsRef!.doc(docId).delete();
  }

  Future<void> _fetchAIPredictions() async {
    if (_itemsRef == null) return;

    try {
      final snapshot = await _itemsRef!.get();
      final history = snapshot.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['name'] as String)
          .toList();

      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/predict'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'history': history}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _aiPredictions = List<String>.from(data['predictions']);
        });
      } else {
        print('API error: ${response.statusCode}');
      }
    } catch (e) {
      print('Prediction error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                            contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            title: Text(name, style: TextStyle(fontSize: 20)),
                            subtitle: Text('Quantity: $qty',
                                style: TextStyle(fontSize: 16)),
                            trailing: IconButton(
                              icon: Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () => _removeItem(doc.id),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // AI Suggest Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ElevatedButton.icon(
                  onPressed: _fetchAIPredictions,
                  icon: Icon(Icons.auto_awesome),
                  label: Text('AI Suggest Items'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade600,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ),

              // Show AI predictions
              if (_aiPredictions.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'AI Recommendations:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ..._aiPredictions.map(
                      (item) => ListTile(
                    leading: Icon(Icons.recommend, color: Colors.teal),
                    title: Text(item),
                  ),
                ),
              ],

              // Input area
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
                    ElevatedButton(
                      onPressed: _addItem,
                      style: ElevatedButton.styleFrom(
                        padding:
                        EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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
