import 'package:assignment1/page3.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

class Page2 extends StatefulWidget {
  final String name;
  final String address;
  final String phone;
  final String email;
  final String bookingDate;
  final String bookingTime;
  final String tourDate;
  final String tourTime;
  final String additionalRequests;

  Page2({
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
  _Page2State createState() => _Page2State();
}

class _Page2State extends State<Page2> {
  String selectedTourType = 'Independent Tour';
  int adultsCount = 1;

  PageController pageController = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Jaley - Jaley Package'),
      ),
      body: Stack(
        children: [
          Image.asset(
            'assets/flower.jpg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(
              color: Colors.white.withOpacity(0.5),
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          Column(
            children: [
              SizedBox(height: 16.0),
              Text(
                'Packages Available',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.all(16.0),
                  children: [
                    _buildDropdown('Type of Tour', [
                      'Independent Tour',
                      'Escorted Tour',
                      'Hosted Tour',
                      'Freedom Tour',
                    ]),
                    SizedBox(height: 16.0),
                    _buildCounter('No. of Persons', adultsCount, (value) {
                      setState(() {
                        adultsCount = value;
                      });
                    }),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildStateButton(
                            'assets/kedah.jpg',
                            'Kedah, Malaysia',
                            'Price: \RM150/pax',
                            {
                              'Day 1': 'Explore the city',
                              'Day 2': 'Visit historical sites',
                              'Day 3': 'Enjoy local cuisine',
                              'Day 4': 'Island Hoping',
                            },
                            '150',
                          ),
                          SizedBox(width: 16.0),
                          _buildStateButton(
                            'assets/penang.jpg',
                            'Penang, Malaysia',
                            'Price: \RM300/pax',
                            {
                              'Day 1': 'Explore the city',
                              'Day 2': 'Visit historical sites',
                              'Day 3': 'Enjoy local cuisine',
                              'Day 4': 'Island Hoping',
                              'Day 5': 'Enjoy the Market',
                              'Day 6': 'Explore Bukit Bendera',
                              'Day 7': 'Shopping',
                            },
                            '300',
                          ),
                          SizedBox(width: 16.0),
                          _buildStateButton(
                            'assets/sabah.jpg',
                            'Sabah, Malaysia',
                            'Price: \RM400/pax',
                            {
                              'Day 1': 'Explore the city',
                              'Day 2': 'Visit historical sites',
                              'Day 3': 'Enjoy local cuisine',
                              'Day 4': 'Island Hoping',
                              'Day 5': 'Enjoy the Market',
                              'Day 6': 'Enjoy the Seafood Food',
                              'Day 7': 'Shopping',
                            },
                            '400',
                          ),
                          SizedBox(width: 16.0),
                          _buildStateButton(
                            'assets/japan.jpg',
                            'Tokyo, Japan',
                            'Price: \RM1,670/pax',
                            {
                              'Day 1': 'Kuala Lumpur - Chitose',
                              'Day 2': 'Chitose - Noboribetsu',
                              'Day 3': 'Noboribetsu  - Hakodate',
                              'Day 4': 'Hakodate - Lake Toya',
                              'Day 5': 'Lake Toya - Otaru - Sapporo',
                              'Day 6': 'Sapporo',
                              'Day 7': 'Chitose - Kuala Lumpur',
                            },
                            '1670',
                          ),
                          SizedBox(width: 16.0),
                          _buildStateButton(
                            'assets/korea.jpg',
                            'Seoul, Korea',
                            'Price: \RM1,500/pax',
                            {
                              'Day 1': 'Kuala Lumpur - Incheon (SEOUL)',
                              'Day 2': 'Arrival Incheon - Gunsan',
                              'Day 3': 'Gunsan - Jeonju',
                              'Day 4': 'Jeonju - Mokpo',
                              'Day 5': 'Mokpo - Gyeongju',
                              'Day 6': 'Gyeongju - Seoul',
                              'Day 7': 'Seoul - Kuala Lumpur',
                            },
                            '1500',
                          ),
                          SizedBox(width: 16.0),
                          _buildStateButton(
                            'assets/maldives.jpg',
                            'Maldives',
                            'Price: \RM1,800/pax',
                            {
                              'Day 1': 'Explore the city',
                              'Day 2': 'Visit historical sites',
                              'Day 3': 'Enjoy local cuisine',
                              'Day 4': 'Island Hoping',
                              'Day 5': 'Helicopter Ride',
                              'Day 6': 'Maldives Glowing Beach',
                              'Day 7': 'Long Walk on the Beach',
                            },
                            '1800',
                          ),
                          SizedBox(width: 16.0),
                          _buildStateButton(
                            'assets/switzerland.jpg',
                            'Switzerland, Central of Europe',
                            'Price: \RM2,300/pax',
                            {
                              'Day 1': 'Explore the city',
                              'Day 2': 'Visit historical sites',
                              'Day 3': 'Enjoy local cuisine',
                              'Day 4': 'Leasure Day',
                              'Day 5': 'Enjoy the Market',
                              'Day 6': 'Skiing',
                              'Day 7': 'Shopping',
                            },
                            '2300',
                          ),
                          SizedBox(width: 16.0),
                          _buildStateButton(
                            'assets/vietname.jpg',
                            'Ba Na Hills, Vietnam',
                            'Price: \RM870/pax',
                            {
                              'Day 1': 'Explore the city',
                              'Day 2': 'Visit historical sites',
                              'Day 3': 'Enjoy local cuisine',
                              'Day 4': 'Visit the Village',
                              'Day 5': 'Enjoy the Market',
                              'Day 6': 'Shopping Hoping',
                              'Day 7': 'Shopping',
                            },
                            '870',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> options) {
    return DropdownButtonFormField<String>(
      value: selectedTourType,
      onChanged: (value) {
        setState(() {
          selectedTourType = value!;
        });
      },
      items: options.map((option) {
        return DropdownMenuItem<String>(
          value: option,
          child: Text(option,
              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
        );
      }).toList(),
      decoration: InputDecoration(
        labelText: label,
      ),
    );
  }

  Widget _buildCounter(String label, int count, Function(int) onChanged) {
    return Container(
      padding: EdgeInsets.all(8.0),
      margin: EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.remove),
                onPressed: () {
                  if (count > 0) {
                    onChanged(count - 1);
                  }
                },
              ),
              Text('$count'),
              IconButton(
                icon: Icon(Icons.add),
                onPressed: () {
                  onChanged(count + 1);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPackageDetails(
      String packageName, Map<String, String> tentatives, String price) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Package Details'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$packageName'),
              SizedBox(height: 8.0),
              Text('Tentatives:'),
              for (var entry in tentatives.entries)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.0),
                      margin: EdgeInsets.only(left: 8.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.key),
                          SizedBox(height: 4.0),
                          SizedBox(width: 8.0),
                          Text(entry.value),
                        ],
                      ),
                    ),
                    SizedBox(height: 8.0),
                    SizedBox(width: 20.0),
                  ],
                ),
              SizedBox(height: 8.0),
              Text('Price: $price'), // Display the price
            ],
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    print('Selected Tentative: ${tentatives.values}');
                    Navigator.of(context).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Page3(
                          packageName: packageName,
                          price: price,
                          adultsCount: adultsCount,
                          name: widget.name,
                          address: widget.address,
                          phone: widget.phone,
                          email: widget.email,
                          bookingDate: widget.bookingDate,
                          bookingTime: widget.bookingTime,
                          tourDate: widget.tourDate,
                          tourTime: widget.tourTime,
                          additionalRequests: widget.additionalRequests,
                        ),
                      ),
                    );
                  },
                  child: Text('Choose'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Close'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStateButton(String assetPath, String stateName,
      String description, Map<String, String> tentatives, String price) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16.0),
        Text(
          'Explore Top Places Recommendation',
          style: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16.0),
        Container(
          width: 370.0,
          height: 270.0,
          child: Stack(
            children: [
              ElevatedButton(
                onPressed: () {
                  _showPackageDetails(stateName, tentatives, price);
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.asset(
                    assetPath,
                    width: 370.0,
                    height: 270.0,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 100,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.arrow_back),
                    color: Colors.black,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: 100,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.arrow_forward),
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8.0),
        Text(
          stateName,
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          description,
          style: TextStyle(
            fontSize: 14.0,
            fontStyle: FontStyle.italic,
            color: Colors.black26,
          ),
        ),
      ],
    );
  }
}
