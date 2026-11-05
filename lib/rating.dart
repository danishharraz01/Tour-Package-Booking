import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'main.dart';

class RateAppPage extends StatefulWidget {
  @override
  _RateAppPageState createState() => _RateAppPageState();
}

class _RateAppPageState extends State<RateAppPage> {
  double _rating = 0;

  // Function to show the thank you message and navigate to main.dart
  void _showThankYouDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Thank You!'),
          content: Text('Thank you for choosing Jaley - Jaley Trip as your holiday!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                Navigator.pop(context); // Close the RateAppPage
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MyApp())); // Navigate to main.dart
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rate Our Package'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Rate Our Package:',
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 16),
              RatingBar.builder(
                initialRating: _rating,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemSize: 40,
                itemBuilder: (context, _) => Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                onRatingUpdate: (rating) {
                  setState(() {
                    _rating = rating;
                  });
                },
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                
                  _showThankYouDialog(context);
                },
                child: Text('Submit Rating'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
