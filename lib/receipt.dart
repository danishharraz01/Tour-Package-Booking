import 'package:flutter/material.dart';
import 'rating.dart';

class ReceiptPage extends StatelessWidget {
  final String packageName;
  final String price;
  final int adultsCount;
  final String name;
  final String address;
  final String phone;
  final String email;
  final String bookingDate;
  final String bookingTime;
  final String tourDate;
  final String tourTime;
  final String additionalRequests;
  final String? selectedDiscountCode;
  final double totalpayment;

  ReceiptPage({
    required this.packageName,
    required this.price,
    required this.adultsCount,
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
    required this.bookingDate,
    required this.bookingTime,
    required this.tourDate,
    required this.tourTime,
    required this.additionalRequests,
    required this.selectedDiscountCode,
    required this.totalpayment,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Receipt'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Receipt Information'),
              _buildReceiptItem('Package Name', packageName),
              _buildReceiptItem('Number of Persons', adultsCount.toString()),
              _buildReceiptItem('Name', name),
              _buildReceiptItem('Address', address),
              _buildReceiptItem('Phone', phone),
              _buildReceiptItem('Email', email),
              _buildReceiptItem('Booking Date', bookingDate),
              _buildReceiptItem('Booking Time', bookingTime),
              _buildReceiptItem('Tour Date', tourDate),
              _buildReceiptItem('Tour Time', tourTime),
              _buildReceiptItem('Additional Requests', additionalRequests),
              _buildReceiptItem('Discount Code', selectedDiscountCode ?? 'N/A'),
              SizedBox(height: 16),
              _buildSectionTitle('Total Payment :'),
              _buildTotalPayment(),
              SizedBox(height: 16),
              _buildRateAppButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20.0,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildReceiptItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label + ":",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildTotalPayment() {
    return Text(
      'RM$totalpayment',
      style: TextStyle(
        fontSize: 22.0,
        fontWeight: FontWeight.bold,
        color: Colors.green,
      ),
    );
  }

Widget _buildRateAppButton(BuildContext context) {
  return Center(
    child: ElevatedButton(
      onPressed: () {
        // Navigate to the page for rating the app
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RateAppPage(), // Replace RateAppPage with the actual rating page
          ),
        );
      },
      child: Text('Give us ratings'),
    ),
  );
}

}

