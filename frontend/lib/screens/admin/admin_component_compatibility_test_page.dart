/// Component Compatibility Test Page
///
/// Test page for ComponentCompatibility API endpoints.
/// This page allows testing all CRUD operations for component compatibilities.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/component_compatibility_provider.dart';
import 'package:frontend/widgets/navigation_bar.dart';

class AdminComponentCompatibilityTestPage extends ConsumerStatefulWidget {
  const AdminComponentCompatibilityTestPage({super.key});

  @override
  ConsumerState<AdminComponentCompatibilityTestPage> createState() => _AdminComponentCompatibilityTestPageState();
}

class _AdminComponentCompatibilityTestPageState extends ConsumerState<AdminComponentCompatibilityTestPage> {
  final _componentIdController = TextEditingController();
  final _compatibleComponentIdController = TextEditingController();
  final _compatibilityIdController = TextEditingController();
  final _noteController = TextEditingController();
  final _searchQueryController = TextEditingController();
  
  String _statusMessage = '';
  Color _statusColor = Colors.grey;
  bool _isLoading = false;

  @override
  void dispose() {
    _componentIdController.dispose();
    _compatibleComponentIdController.dispose();
    _compatibilityIdController.dispose();
    _noteController.dispose();
    _searchQueryController.dispose();
    super.dispose();
  }

  void _showStatus(String message, Color color) {
    setState(() {
      _statusMessage = message;
      _statusColor = color;
    });
  }

  Future<void> _testCreateCompatibility() async {
    if (_componentIdController.text.isEmpty || _compatibleComponentIdController.text.isEmpty) {
      _showStatus('Please enter both Component IDs', Colors.red);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final service = ref.read(componentCompatibilityServiceProvider);
      final id = await service.createComponentCompatibility(
        componentId: _componentIdController.text.trim(),
        compatibleComponentId: _compatibleComponentIdController.text.trim(),
      );
      _showStatus('✅ Created successfully! ID: $id', Colors.green);
      _componentIdController.clear();
      _compatibleComponentIdController.clear();
    } catch (e) {
      _showStatus('❌ Error: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testGetCompatibility() async {
    if (_compatibilityIdController.text.isEmpty) {
      _showStatus('Please enter Compatibility ID', Colors.red);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final compatibility = await ref.read(componentCompatibilityProvider(_compatibilityIdController.text.trim()).future);
      _showStatus(
        '✅ Found: Component ${compatibility.componentId} ↔ ${compatibility.compatibleComponentId}',
        Colors.green,
      );
    } catch (e) {
      _showStatus('❌ Error: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testGetAllCompatibilities() async {
    setState(() => _isLoading = true);
    try {
      final compatibilities = await ref.read(componentCompatibilitiesProvider({
        'paging': false,
        if (_searchQueryController.text.isNotEmpty) 'query': _searchQueryController.text.trim(),
      }).future);
      
      _showStatus('✅ Found ${compatibilities.length} compatibilities', Colors.green);
    } catch (e) {
      _showStatus('❌ Error: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testGetByComponentId() async {
    if (_componentIdController.text.isEmpty) {
      _showStatus('Please enter Component ID', Colors.red);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final compatibleIds = await ref.read(compatibleComponentIdsProvider(_componentIdController.text.trim()).future);
      _showStatus('✅ Found ${compatibleIds.length} compatible components', Colors.green);
    } catch (e) {
      _showStatus('❌ Error: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testCheckCompatibility() async {
    if (_componentIdController.text.isEmpty || _compatibleComponentIdController.text.isEmpty) {
      _showStatus('Please enter both Component IDs', Colors.red);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final isCompatible = await ref.read(componentsCompatibilityCheckProvider({
        'componentId1': _componentIdController.text.trim(),
        'componentId2': _compatibleComponentIdController.text.trim(),
      }).future);
      
      _showStatus(
        isCompatible ? '✅ Components ARE compatible' : '❌ Components are NOT compatible',
        isCompatible ? Colors.green : Colors.orange,
      );
    } catch (e) {
      _showStatus('❌ Error: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testUpdateCompatibility() async {
    if (_compatibilityIdController.text.isEmpty) {
      _showStatus('Please enter Compatibility ID', Colors.red);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final service = ref.read(componentCompatibilityServiceProvider);
      await service.updateComponentCompatibility(
        _compatibilityIdController.text.trim(),
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );
      _showStatus('✅ Updated successfully!', Colors.green);
      _noteController.clear();
    } catch (e) {
      _showStatus('❌ Error: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testDeleteCompatibility() async {
    if (_compatibilityIdController.text.isEmpty) {
      _showStatus('Please enter Compatibility ID', Colors.red);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final service = ref.read(componentCompatibilityServiceProvider);
      await service.deleteComponentCompatibility(_compatibilityIdController.text.trim());
      _showStatus('✅ Deleted successfully!', Colors.green);
      _compatibilityIdController.clear();
    } catch (e) {
      _showStatus('❌ Error: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Column(
        children: [
          CustomNavigationBar(scaffoldKey: GlobalKey<ScaffoldState>()),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Component Compatibility API Test',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Test all ComponentCompatibility API endpoints',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Status Message
                  if (_statusMessage.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: _statusColor.withOpacity(0.1),
                        border: Border.all(color: _statusColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: _statusColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _statusMessage,
                              style: TextStyle(color: _statusColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // CREATE Section
                  _buildSection(
                    theme,
                    '1. CREATE Compatibility (Admin Only)',
                    [
                      TextField(
                        controller: _componentIdController,
                        decoration: const InputDecoration(
                          labelText: 'Component ID',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _compatibleComponentIdController,
                        decoration: const InputDecoration(
                          labelText: 'Compatible Component ID',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _testCreateCompatibility,
                        child: const Text('Create Compatibility'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // GET Single Section
                  _buildSection(
                    theme,
                    '2. GET Single Compatibility',
                    [
                      TextField(
                        controller: _compatibilityIdController,
                        decoration: const InputDecoration(
                          labelText: 'Compatibility ID',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _testGetCompatibility,
                        child: const Text('Get Compatibility'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // GET All Section
                  _buildSection(
                    theme,
                    '3. GET All Compatibilities',
                    [
                      TextField(
                        controller: _searchQueryController,
                        decoration: const InputDecoration(
                          labelText: 'Search Query (Optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _testGetAllCompatibilities,
                        child: const Text('Get All Compatibilities'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // GET Compatible Components Section
                  _buildSection(
                    theme,
                    '4. GET Compatible Components for Component',
                    [
                      TextField(
                        controller: _componentIdController,
                        decoration: const InputDecoration(
                          labelText: 'Component ID',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _testGetByComponentId,
                        child: const Text('Get Compatible Components'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // CHECK Compatibility Section
                  _buildSection(
                    theme,
                    '5. CHECK if Components are Compatible',
                    [
                      TextField(
                        controller: _componentIdController,
                        decoration: const InputDecoration(
                          labelText: 'Component ID 1',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _compatibleComponentIdController,
                        decoration: const InputDecoration(
                          labelText: 'Component ID 2',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _testCheckCompatibility,
                        child: const Text('Check Compatibility'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // UPDATE Section
                  _buildSection(
                    theme,
                    '6. UPDATE Compatibility Note (Admin Only)',
                    [
                      TextField(
                        controller: _compatibilityIdController,
                        decoration: const InputDecoration(
                          labelText: 'Compatibility ID',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _noteController,
                        decoration: const InputDecoration(
                          labelText: 'Note (Optional)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _testUpdateCompatibility,
                        child: const Text('Update Compatibility'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // DELETE Section
                  _buildSection(
                    theme,
                    '7. DELETE Compatibility (Admin Only)',
                    [
                      TextField(
                        controller: _compatibilityIdController,
                        decoration: const InputDecoration(
                          labelText: 'Compatibility ID',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _testDeleteCompatibility,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Delete Compatibility'),
                      ),
                    ],
                  ),
                  
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(ThemeData theme, String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

