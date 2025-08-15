import 'package:flutter/material.dart';
import '../../../core/utils/route_utils.dart';

class RouteSelectorWidget extends StatefulWidget {
  final String? selectedRouteId;
  final Function(String) onRouteSelected;

  const RouteSelectorWidget({
    super.key,
    this.selectedRouteId,
    required this.onRouteSelected,
  });

  @override
  State<RouteSelectorWidget> createState() => _RouteSelectorWidgetState();
}

class _RouteSelectorWidgetState extends State<RouteSelectorWidget> {
  String? _selectedRouteId;

  @override
  void initState() {
    super.initState();
    _selectedRouteId = widget.selectedRouteId ?? 'route_divisoria_fairview';
  }

  @override
  Widget build(BuildContext context) {
    final routes = RouteUtils.getAllRoutes();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.route,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Select Your Route',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedRouteId,
                  isExpanded: true,
                  hint: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text('Choose a route...'),
                  ),
                  items: routes.map((route) {
                    return DropdownMenuItem<String>(
                      value: route['id'],
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.directions_bus,
                              size: 20,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                route['name']!,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedRouteId = newValue;
                      });
                      widget.onRouteSelected(newValue);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_selectedRouteId != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Selected: ${RouteUtils.getRouteName(_selectedRouteId)}',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
