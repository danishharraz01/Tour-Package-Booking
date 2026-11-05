import 'package:flutter/material.dart';
import 'page2.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Tour Booking App',
      home: MyCustomForm(),
    );
  }
}

class MyCustomForm extends StatefulWidget {
  const MyCustomForm({Key? key}) : super(key: key);

  @override
  _MyCustomFormState createState() => _MyCustomFormState();
}

class _MyCustomFormState extends State<MyCustomForm> {
  final nameController = TextEditingController();
  final addressController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final bookingDateController = TextEditingController();
  final bookingTimeController = TextEditingController();
  final tourDateController = TextEditingController();
  final tourTimeController = TextEditingController();
  final additionalRequestsController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    addressController.dispose();
    phoneController.dispose();
    emailController.dispose();
    bookingDateController.dispose();
    bookingTimeController.dispose();
    tourDateController.dispose();
    tourTimeController.dispose();
    additionalRequestsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(TextEditingController controller) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null && pickedDate != DateTime.now()) {
      controller.text = pickedDate.toLocal().toString().split(' ')[0];
    }
  }

  Future<void> _selectTime(TextEditingController controller) async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      controller.text = pickedTime.format(context);
    }
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint, [
    TextInputType keyboardType = TextInputType.text,
    VoidCallback? onTap,
  ]) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.45,
      height: 65.0,
      padding: EdgeInsets.all(4.0),
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
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildDropdownField(
    List<String> items,
    String selectedValue,
    String label,
    String hint,
    void Function(String?)? onChanged,
  ) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.45,
      height: 65.0,
      padding: EdgeInsets.all(4.0),
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
      child: DropdownButtonFormField<String>(
        value: selectedValue.isNotEmpty ? selectedValue : null,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: InputBorder.none,
        ),
        items: items.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
      ),
    );
  }

  bool _validateInputs() {
    return nameController.text.isNotEmpty &&
        addressController.text.isNotEmpty &&
        phoneController.text.isNotEmpty &&
        emailController.text.isNotEmpty &&
        bookingDateController.text.isNotEmpty &&
        bookingTimeController.text.isNotEmpty &&
        tourDateController.text.isNotEmpty &&
        tourTimeController.text.isNotEmpty;
  }

  void _showUserInformation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("User Information"),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Name: ${nameController.text}'),
              Text('Address: ${addressController.text}'),
              Text('Phone No: ${phoneController.text}'),
              Text('Email: ${emailController.text}'),
              SizedBox(height: 10),
              Text('Booking Detail:'),
              Text('Booking Date: ${bookingDateController.text}'),
              Text('Booking Time: ${bookingTimeController.text}'),
              SizedBox(height: 10),
              Text('Tour Details:'),
              Text('Tour Date: ${tourDateController.text}'),
              Text('Tour Time: ${tourTimeController.text}'),
              SizedBox(height: 10),
              Text('Additional Requests: ${additionalRequestsController.text}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the current dialog

                // Pass the data to Page2
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Page2(
                      name: nameController.text,
                      address: addressController.text,
                      phone: phoneController.text,
                      email: emailController.text,
                      bookingDate: bookingDateController.text,
                      bookingTime: bookingTimeController.text,
                      tourDate: tourDateController.text,
                      tourTime: tourTimeController.text,
                      additionalRequests: additionalRequestsController.text,
                    ),
                  ),
                );
              },
              child: Text('Next'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialogBox(BuildContext context, String errorMessage) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text(errorMessage),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jaley - Jaley Booking'),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/flower.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'User Information:',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildTextField(
                          nameController, 'Name', 'Enter your name...'),
                      _buildTextField(addressController, 'Address',
                          'Enter your address...'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildTextField(phoneController, 'Phone No',
                          'Enter your phone number...', TextInputType.phone),
                      _buildTextField(emailController, 'Email',
                          'Enter your email...', TextInputType.emailAddress),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Booking Details:',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildTextField(
                          bookingDateController,
                          'Booking Date',
                          'Enter booking date...',
                          TextInputType.datetime,
                          () => _selectDate(bookingDateController)),
                      _buildTextField(
                          bookingTimeController,
                          'Booking Time',
                          'Enter booking time...',
                          TextInputType.datetime,
                          () => _selectTime(bookingTimeController)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tour Details:',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildTextField(
                          tourDateController,
                          'Tour Date',
                          'Enter tour date...',
                          TextInputType.datetime,
                          () => _selectDate(tourDateController)),
                      _buildTextField(
                          tourTimeController,
                          'Tour Time',
                          'Enter tour time...',
                          TextInputType.datetime,
                          () => _selectTime(tourTimeController)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Additional Requests:',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  _buildDropdownField(
                    ['Insurance', 'No Insurance'], // Replace with your options
                    additionalRequestsController.text,
                    'Additional Requests',
                    'Select additional requests...',
                    (String? value) {
                      setState(() {
                        additionalRequestsController.text = value ?? "";
                      });
                    },
                  ),
                  SizedBox(height: 8),
                  Container(
                    alignment: Alignment.center,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_validateInputs()) {
                          _showUserInformation(context);
                        } else {
                          _showErrorDialogBox(
                              context, 'Please fill in all required fields.');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        primary: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 10.0,
                        ),
                        child: Text(
                          'Submit',
                          style: TextStyle(fontSize: 16.0),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
