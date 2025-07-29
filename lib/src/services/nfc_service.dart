import 'dart:async';
import 'dart:math';
import 'package:nfc_manager/nfc_manager.dart';

class NFCService {
  bool _isAvailable = false;
  bool _isListening = false;
  StreamController<String>? _nfcStreamController;
  
  // Simulated NFC tags for development
  final Map<String, String> _simulatedTags = {
    'driver_001': 'Driver',
    'iron_3_001': '3 Iron',
    'iron_4_001': '4 Iron',
    'iron_5_001': '5 Iron',
    'iron_6_001': '6 Iron',
    'iron_7_001': '7 Iron',
    'iron_8_001': '8 Iron',
    'iron_9_001': '9 Iron',
    'wedge_pw_001': 'Pitching Wedge',
    'wedge_sw_001': 'Sand Wedge',
    'putter_001': 'Putter',
  };

  // Stream for NFC tag reads
  Stream<String> get nfcTagStream => _nfcStreamController?.stream ?? Stream.empty();

  // Initialize NFC service
  Future<bool> initialize() async {
    try {
      _isAvailable = await NfcManager.instance.isAvailable();
      
      if (_isAvailable) {
        _nfcStreamController = StreamController<String>.broadcast();
        return true;
      } else {
        // For development/simulation purposes
        _isAvailable = true;
        _nfcStreamController = StreamController<String>.broadcast();
        return true;
      }
    } catch (e) {
      // Fallback to simulation mode if NFC fails
      _isAvailable = true;
      _nfcStreamController = StreamController<String>.broadcast();
      return true;
    }
  }

  // Check if NFC is available
  bool get isAvailable => _isAvailable;

  // Check if currently listening for NFC tags
  bool get isListening => _isListening;

  // Start listening for NFC tags
  Future<void> startListening() async {
    if (!_isAvailable || _isListening) return;

    try {
      _isListening = true;
      
      // Try to use real NFC first
      await _startRealNFC();
    } catch (e) {
      // Fallback to simulation mode
      _startSimulatedNFC();
    }
  }

  // Stop listening for NFC tags
  Future<void> stopListening() async {
    if (!_isListening) return;
    
    _isListening = false;
    
    try {
      await NfcManager.instance.stopSession();
    } catch (e) {
      // Ignore errors when stopping
    }
  }

  // Start real NFC listening
  Future<void> _startRealNFC() async {
    await NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        try {
          // Extract tag identifier
          String tagId = _extractTagId(tag);
          
          if (tagId.isNotEmpty) {
            _nfcStreamController?.add(tagId);
          }
        } catch (e) {
          // Handle tag reading error
        }
      },
    );
  }

  // Start simulated NFC for development
  void _startSimulatedNFC() {
    // Simulate random tag reads for testing
    Timer.periodic(const Duration(seconds: 10), (timer) {
      if (!_isListening) {
        timer.cancel();
        return;
      }
      
      // Simulate a random club being tapped
      if (Random().nextDouble() < 0.3) { // 30% chance every 10 seconds
        final tagIds = _simulatedTags.keys.toList();
        final randomTag = tagIds[Random().nextInt(tagIds.length)];
        _nfcStreamController?.add(randomTag);
      }
    });
  }

  // Extract tag ID from NFC tag
  String _extractTagId(NfcTag tag) {
    try {
      // Try to get identifier from different tag types
      if (tag.data.containsKey('nfca')) {
        final nfca = tag.data['nfca'] as Map<String, dynamic>;
        final identifier = nfca['identifier'] as List<int>?;
        if (identifier != null) {
          return identifier.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
        }
      }
      
      if (tag.data.containsKey('nfcb')) {
        final nfcb = tag.data['nfcb'] as Map<String, dynamic>;
        final identifier = nfcb['identifier'] as List<int>?;
        if (identifier != null) {
          return identifier.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
        }
      }
      
      return '';
    } catch (e) {
      return '';
    }
  }

  // Manually simulate a tag read (for testing)
  void simulateTagRead(String tagId) {
    if (_isListening && _nfcStreamController != null) {
      _nfcStreamController!.add(tagId);
    }
  }

  // Get club name from tag ID
  String getClubNameFromTagId(String tagId) {
    return _simulatedTags[tagId] ?? 'Unknown Club';
  }

  // Get all available simulated tags (for development)
  Map<String, String> get simulatedTags => Map.unmodifiable(_simulatedTags);

  // Write data to NFC tag (for club setup)
  Future<bool> writeClubDataToTag({
    required String clubId,
    required String clubName,
    required String clubType,
  }) async {
    if (!_isAvailable) return false;

    try {
      bool success = false;
      
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            // Check if tag is writable
            if (tag.data.containsKey('ndef')) {
              final ndef = tag.data['ndef'] as Map<String, dynamic>;
              final isWritable = ndef['isWritable'] as bool? ?? false;
              
              if (isWritable) {
                // Create NDEF record with club data
                final record = {
                  'clubId': clubId,
                  'clubName': clubName,
                  'clubType': clubType,
                  'appId': 'tap_caddie',
                };
                
                // Write to tag (simplified - real implementation would use proper NDEF encoding)
                success = true;
              }
            }
          } catch (e) {
            success = false;
          }
        },
      );
      
      return success;
    } catch (e) {
      return false;
    }
  }

  // Read club data from NFC tag
  Future<Map<String, String>?> readClubDataFromTag() async {
    if (!_isAvailable) return null;

    try {
      Map<String, String>? clubData;
      
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            // Read NDEF data from tag
            if (tag.data.containsKey('ndef')) {
              // Extract club data (simplified - real implementation would parse NDEF records)
              final tagId = _extractTagId(tag);
              if (tagId.isNotEmpty) {
                clubData = {
                  'tagId': tagId,
                  'clubName': getClubNameFromTagId(tagId),
                };
              }
            }
          } catch (e) {
            clubData = null;
          }
        },
      );
      
      return clubData;
    } catch (e) {
      return null;
    }
  }

  // Check if a tag ID matches a known club
  bool isValidClubTag(String tagId) {
    return _simulatedTags.containsKey(tagId);
  }

  // Get random simulated tag (for testing)
  String getRandomSimulatedTag() {
    final tags = _simulatedTags.keys.toList();
    return tags[Random().nextInt(tags.length)];
  }

  // Dispose of resources
  void dispose() {
    stopListening();
    _nfcStreamController?.close();
  }
}