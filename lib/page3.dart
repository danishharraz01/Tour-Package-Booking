import 'package:flutter/material.dart';
import 'receipt.dart';

class Page3 extends StatefulWidget {
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

  Page3({
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
  });

  @override
  _Page3State createState() => _Page3State();
}

class _Page3State extends State<Page3> {
  String? selectedDiscountCode; // Make it nullable
  final List<String> discountCodes = ['CODE 1', 'CODE 2', 'CODE 3'];

  double calculateTotalPayment() {
    double numericPrice = double.parse(widget.price);
    if (selectedDiscountCode == 'CODE 1') {
      return (numericPrice * widget.adultsCount) * 0.95;
    } else if (selectedDiscountCode == 'CODE 2') {
      return (numericPrice * widget.adultsCount) * 0.90;
    } else if (selectedDiscountCode == 'CODE 3') {
      return (numericPrice * widget.adultsCount) * 0.80;
    } else {
      return numericPrice * widget.adultsCount;
    }
  }

  Widget _buildTextField(String label, String value) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(5.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalpayment = calculateTotalPayment();
    return Scaffold(
      appBar: AppBar(
        title: Text('Customer Payment'),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/flower.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTextField('Name:', widget.name),
                _buildTextField('Address:', widget.address),
                _buildTextField('Phone:', widget.phone),
                _buildTextField('Email:', widget.email),
                _buildTextField('Booking Date:', widget.bookingDate),
                _buildTextField('Booking Time:', widget.bookingTime),
                _buildTextField('Tour Date:', widget.tourDate),
                _buildTextField('Tour Time:', widget.tourTime),
                _buildTextField('Number of Persons:', widget.adultsCount.toString()),
                _buildTextField('Price:', 'RM${widget.price}/pax'),
                DropdownButtonFormField<String?>(
                  value: selectedDiscountCode,
                  onChanged: (value) {
                    setState(() {
                      selectedDiscountCode = value;
                    });
                  },
                  items: discountCodes.map((code) {
                    return DropdownMenuItem<String?>(
                      value: code,
                      child: Text(code),
                    );
                  }).toList(),
                  decoration: InputDecoration(
                    labelText: 'Discount Code',
                  ),
                ),
                SizedBox(height: 16),
                _buildTextField('Total Payment:', 'RM${totalpayment}'),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReceiptPage(
                          packageName: widget.packageName,
                          price: widget.price,
                          adultsCount: widget.adultsCount,
                          name: widget.name,
                          address: widget.address,
                          phone: widget.phone,
                          email: widget.email,
                          bookingDate: widget.bookingDate,
                          bookingTime: widget.bookingTime,
                          tourDate: widget.tourDate,
                          tourTime: widget.tourTime,
                          additionalRequests: widget.additionalRequests,
                          selectedDiscountCode: selectedDiscountCode,
                          totalpayment: totalpayment,
                        ),
                      ),
                    );
                  },
                  child: Text('View Receipt'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
