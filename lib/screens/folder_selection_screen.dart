import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../providers/scan_provider.dart';
import '../services/platform_service.dart';
import '../widgets/folder_list_tile.dart';

class FolderSelectionScreen extends StatefulWidget {
  const FolderSelectionScreen({super.key});

  @override
  State<FolderSelectionScreen> createState() => _FolderSelectionScreenState();
}

class _FolderSelectionScreenState extends State<FolderSelectionScreen> {
  List<DriveInfo> _drives = [];
  List<String> _defaultDirs = [];
  List<String> _customFolders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDrivesAndFolders();
  }

  Future<void> _loadDrivesAndFolders() async {
    final platformService = context.read<PlatformService>();
    final scanProvider = context.read<ScanProvider>();

    final drives = await platformService.getAvailableDrives();
    final defaultDirs = platformService.getDefaultPhotoDirectories();

    await scanProvider.loadFolders();
    final savedFolders = scanProvider.selectedFolders;

    // Identify custom folders (not matching any drive or default dir)
    final knownPaths = <String>{
      ...drives.map((d) => d.path),
      ...defaultDirs,
    };
    final customFolders =
        savedFolders.where((f) => !knownPaths.contains(f)).toList();

    if (!mounted) return;

    setState(() {
      _drives = drives;
      _defaultDirs = defaultDirs;
      _customFolders = customFolders;
      _isLoading = false;
    });

    // If no saved folders, select defaults
    if (savedFolders.isEmpty) {
      for (final dir in defaultDirs) {
        scanProvider.addFolder(dir);
      }
    }
  }

  Future<void> _addCustomFolder() async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select folder to scan',
    );
    if (result != null && mounted) {
      final scanProvider = context.read<ScanProvider>();
      scanProvider.addFolder(result);
      if (!_customFolders.contains(result) &&
          !_drives.any((d) => d.path == result) &&
          !_defaultDirs.contains(result)) {
        setState(() {
          _customFolders.add(result);
        });
      }
    }
  }

  void _startScan() {
    final scanProvider = context.read<ScanProvider>();
    if (scanProvider.selectedFolders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one folder.')),
      );
      return;
    }
    scanProvider.startScan();
    Navigator.of(context).pushReplacementNamed('/scanning');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Folders'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<ScanProvider>(
              builder: (context, scanProvider, _) {
                final selectedFolders = scanProvider.selectedFolders;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Choose which folders to scan for photos.',
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        children: [
                          if (_defaultDirs.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Text(
                                'Default Photo Directories',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            ..._defaultDirs.map((dir) => FolderListTile(
                                  key: ValueKey('default_$dir'),
                                  path: dir,
                                  label: p.basename(dir),
                                  isSelected: selectedFolders.contains(dir),
                                  isDefault: true,
                                  onChanged: (_) =>
                                      scanProvider.toggleFolder(dir),
                                )),
                            const Divider(),
                          ],
                          if (_drives.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Text(
                                'Drives & Volumes',
                                style: theme.textTheme.titleSmall,
                              ),
                            ),
                            ..._drives.map((drive) => FolderListTile(
                                  key: ValueKey('drive_${drive.path}'),
                                  path: drive.path,
                                  label: drive.label,
                                  isSelected:
                                      selectedFolders.contains(drive.path),
                                  onChanged: (_) =>
                                      scanProvider.toggleFolder(drive.path),
                                )),
                            const Divider(),
                          ],
                          if (_customFolders.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Text(
                                'Custom Folders',
                                style: theme.textTheme.titleSmall,
                              ),
                            ),
                            ..._customFolders.map((folder) => FolderListTile(
                                  key: ValueKey('custom_$folder'),
                                  path: folder,
                                  label: p.basename(folder),
                                  isSelected: selectedFolders.contains(folder),
                                  onChanged: (_) =>
                                      scanProvider.toggleFolder(folder),
                                )),
                            const Divider(),
                          ],
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: OutlinedButton.icon(
                              onPressed: _addCustomFolder,
                              icon: const Icon(Icons.add),
                              label: const Text('Add Folder'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: _startScan,
                          icon: const Icon(Icons.search),
                          label: Text(
                            'Scan ${selectedFolders.length} folder${selectedFolders.length == 1 ? '' : 's'}',
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
