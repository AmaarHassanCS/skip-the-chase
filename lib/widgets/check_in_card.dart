import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skip_the_chase/models/check_in.dart';
import 'package:skip_the_chase/providers/location_provider.dart';

class CheckInCard extends StatelessWidget {
  final CheckIn checkIn;

  const CheckInCard({super.key, required this.checkIn});

  @override
  Widget build(BuildContext context) {
    final remainingTime = checkIn.remainingTime;
    final hours = remainingTime.inHours;
    final minutes = remainingTime.inMinutes.remainder(60);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        checkIn.venue.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Expires in ${hours > 0 ? '$hours hr ' : ''}${minutes > 0 ? '$minutes min' : ''}',
                        style: TextStyle(
                          color: remainingTime.inMinutes < 15
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _cancelCheckIn(context),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _cancelCheckIn(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Check-in?'),
        content: Text('Are you sure you want to cancel your check-in at ${checkIn.venue.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final locationProvider = Provider.of<LocationProvider>(context, listen: false);
              await locationProvider.cancelCheckIn(checkIn.id);
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }
}