import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skip_the_chase/models/venue.dart';
import 'package:skip_the_chase/providers/location_provider.dart';
import 'package:skip_the_chase/widgets/check_in_card.dart';
import 'package:skip_the_chase/widgets/venue_card.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    await locationProvider.initialize();
  }

  void _showCheckInDialog(Venue venue) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Check in to ${venue.name}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const Text('How long will you be here?'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildDurationChip(venue, const Duration(minutes: 30), '30 min'),
                _buildDurationChip(venue, const Duration(hours: 1), '1 hour'),
                _buildDurationChip(venue, const Duration(hours: 2), '2 hours'),
                _buildDurationChip(venue, const Duration(hours: 3), '3 hours'),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationChip(Venue venue, Duration duration, String label) {
    return ActionChip(
      label: Text(label),
      onPressed: () async {
        Navigator.pop(context);
        final locationProvider = Provider.of<LocationProvider>(context, listen: false);
        final success = await locationProvider.checkInToVenue(venue.id, duration);
        
        if (!mounted) return;
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Checked in to ${venue.name}')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to check in')),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Check In'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: Consumer<LocationProvider>(
        builder: (context, locationProvider, child) {
          if (locationProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (locationProvider.currentPosition == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Location services are disabled'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshData,
                    child: const Text('Enable Location'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (locationProvider.activeCheckIns.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Your Active Check-ins',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: locationProvider.activeCheckIns.length,
                      itemBuilder: (context, index) {
                        final checkIn = locationProvider.activeCheckIns[index];
                        return CheckInCard(checkIn: checkIn);
                      },
                    ),
                    const Divider(height: 32),
                  ],
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Nearby Venues',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if (locationProvider.nearbyVenues.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: Text('No venues found nearby')),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: locationProvider.nearbyVenues.length,
                      itemBuilder: (context, index) {
                        final venue = locationProvider.nearbyVenues[index];
                        return VenueCard(
                          venue: venue,
                          onTap: () => _showCheckInDialog(venue),
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}