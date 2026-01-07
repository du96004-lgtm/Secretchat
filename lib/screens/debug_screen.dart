import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final _db = FirebaseDatabase.instance;
  final _idController = TextEditingController();
  String _output = '';
  bool _isLoading = false;

  Future<void> _fixAllPublicIdMappings() async {
    setState(() {
      _isLoading = true;
      _output = 'Scanning all users...\n';
    });

    try {
      final usersSnap = await _db.ref('users').get();
      if (usersSnap.exists && usersSnap.value != null) {
        Map<dynamic, dynamic> users = usersSnap.value as Map;
        int fixed = 0;
        int total = users.length;

        for (var uid in users.keys) {
          try {
            final userValue = users[uid];
            
            // Skip if the value is not a Map
            if (userValue == null || userValue is! Map) {
              setState(() {
                _output += '⚠️ Skipping $uid: Invalid data type (${userValue.runtimeType})\n';
              });
              continue;
            }
            
            final userData = userValue as Map;
            final publicId = userData['publicId']?.toString();

            if (publicId != null && publicId.isNotEmpty) {
              // Check if mapping exists
              final mappingSnap = await _db.ref('publicIds/$publicId').get();
              if (!mappingSnap.exists) {
                // Create mapping
                await _db.ref('publicIds/$publicId').set(uid);
                setState(() {
                  _output += '✅ Fixed: $publicId -> $uid\n';
                });
                fixed++;
              } else {
                setState(() {
                  _output += '✓ OK: $publicId\n';
                });
              }
            } else {
              setState(() {
                _output += '⚠️ User $uid has no publicId\n';
              });
            }
          } catch (e) {
            setState(() {
              _output += '❌ Error for user $uid: $e\n';
            });
          }
        }

        setState(() {
          _output += '\n📊 Summary:\n';
          _output += 'Total users: $total\n';
          _output += 'Fixed mappings: $fixed\n';
          _output += '\n✅ Done!';
        });
      } else {
        setState(() {
          _output = 'No users found in database.';
        });
      }
    } catch (e) {
      setState(() {
        _output += '\n❌ Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkSpecificId(String publicId) async {
    setState(() {
      _isLoading = true;
      _output = 'Checking ID: $publicId...\n';
    });

    try {
      // Check if mapping exists
      final mappingSnap = await _db.ref('publicIds/$publicId').get();
      
      if (mappingSnap.exists) {
        final uid = mappingSnap.value.toString();
        setState(() {
          _output += '✅ Mapping exists: $publicId -> $uid\n';
        });

        // Get user data
        final userSnap = await _db.ref('users/$uid').get();
        if (userSnap.exists && userSnap.value != null && userSnap.value is Map) {
          final userData = userSnap.value as Map;
          setState(() {
            _output += 'User: ${userData['name'] ?? 'N/A'}\n';
            _output += 'Email: ${userData['email'] ?? 'N/A'}\n';
          });
        }
      } else {
        setState(() {
          _output += '❌ No mapping found for ID: $publicId\n';
          _output += 'Searching in users...\n';
        });

        // Search for user with this publicId
        final usersSnap = await _db.ref('users').get();
        if (usersSnap.exists) {
          Map<dynamic, dynamic> users = usersSnap.value as Map;
          bool found = false;

          for (var uid in users.keys) {
            try {
              final userValue = users[uid];
              
              // Skip if not a Map
              if (userValue == null || userValue is! Map) {
                continue;
              }
              
              final userData = userValue as Map;
              if (userData['publicId'] == publicId) {
                found = true;
                setState(() {
                  _output += '✅ Found user: ${userData['name']}\n';
                  _output += 'Creating mapping...\n';
                });

                await _db.ref('publicIds/$publicId').set(uid);
                
                setState(() {
                  _output += '✅ Mapping created: $publicId -> $uid\n';
                });
                break;
              }
            } catch (e) {
              // Skip this user and continue
              continue;
            }
          }

          if (!found) {
            setState(() {
              _output += '❌ No user found with publicId: $publicId\n';
            });
          }
        }
      }
    } catch (e) {
      setState(() {
        _output += '❌ Error: $e\n';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Tools'),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _fixAllPublicIdMappings,
              icon: const Icon(Icons.build),
              label: const Text('Fix All PublicId Mappings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _idController,
                    decoration: InputDecoration(
                      hintText: 'Enter ID to check',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[800],
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 5,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : () {
                    if (_idController.text.trim().isNotEmpty) {
                      _checkSpecificId(_idController.text.trim());
                    }
                  },
                  icon: const Icon(Icons.search),
                  label: const Text('Check'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Output:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _output.isEmpty ? 'Click a button to start...' : _output,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Colors.greenAccent,
                    ),
                  ),
                ),
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
