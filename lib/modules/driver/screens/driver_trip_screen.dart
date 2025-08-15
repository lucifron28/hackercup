import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DriverTripScreen extends StatefulWidget {
  const DriverTripScreen({super.key});

  @override
  State<DriverTripScreen> createState() => _DriverTripScreenState();
}

class _DriverTripScreenState extends State<DriverTripScreen> {
  final String _currentRoute = 'Divisoria - Fairview';
  final Duration _tripDuration = const Duration(minutes: 45);
  final double _currentSpeed = 25.0;
  bool _isGPSEnabled = true;
  bool _isAcceptingPassengers = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Trip'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Route Info Card
            Card(
              color: Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.route,
                          color: Colors.green[700],
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _currentRoute,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.green[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInfoChip(
                          'Duration',
                          '${_tripDuration.inMinutes}m',
                          Icons.timer,
                        ),
                        _buildInfoChip(
                          'Speed',
                          '${_currentSpeed.toInt()} km/h',
                          Icons.speed,
                        ),
                        _buildInfoChip(
                          'Status',
                          _isAcceptingPassengers ? 'Available' : 'Full',
                          _isAcceptingPassengers ? Icons.check_circle : Icons.block,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // GPS Status Card
            Card(
              color: _isGPSEnabled ? Colors.blue[50] : Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      _isGPSEnabled ? Icons.gps_fixed : Icons.gps_off,
                      color: _isGPSEnabled ? Colors.blue : Colors.red,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isGPSEnabled ? 'GPS Tracking Active' : 'GPS Disabled',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: _isGPSEnabled ? Colors.blue[800] : Colors.red[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _isGPSEnabled 
                                ? 'Broadcasting location every 15 seconds'
                                : 'Enable GPS to track your location',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: _isGPSEnabled ? Colors.blue[600] : Colors.red[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isGPSEnabled,
                      onChanged: (value) {
                        setState(() {
                          _isGPSEnabled = value;
                        });
                      },
                      activeThumbColor: Colors.blue,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Passenger Management
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Availability Status',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _isAcceptingPassengers = !_isAcceptingPassengers;
                          });
                        },
                        icon: Icon(_isAcceptingPassengers 
                            ? Icons.pause 
                            : Icons.play_arrow),
                        label: Text(_isAcceptingPassengers 
                            ? 'Stop Accepting Passengers (Full)' 
                            : 'Start Accepting Passengers (Available)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isAcceptingPassengers 
                              ? Colors.orange 
                              : Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Trip Status Indicator
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(
                            'Trip in Progress',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            
            const Spacer(),
            
            // End Trip Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  _showEndTripDialog(context);
                },
                icon: const Icon(Icons.stop),
                label: const Text(
                  'End Trip',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.green[700]),
          const SizedBox(width: 4),
          Column(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEndTripDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('End Trip'),
          content: const Text('Are you sure you want to end this trip?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.pop(); // Go back to driver home
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('End Trip'),
            ),
          ],
        );
      },
    );
  }
}
