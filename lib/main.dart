// main.dart

import 'package:flutter/material.dart';
import 'page1.dart'; 

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tour Package Booking',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MainPage(),
    );
  }
}

class MainPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('WELCOME TO JALEY - JALEY TRIP'),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/tour.jpg'), // Replace with your tour package image asset
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Align(
              alignment: Alignment.bottomCenter, // Adjust the alignment as needed
              child: Padding(
                padding: const EdgeInsets.only(bottom: 50.0), // Adjust the padding as needed
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MyCustomForm()),
                    );
                  },
                  child: Text('Get Started'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
