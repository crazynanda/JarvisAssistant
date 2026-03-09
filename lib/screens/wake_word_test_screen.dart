import 'package:flutter/material.dart';
import '../services/jarvis_listener.dart';

class WakeWordTestScreen extends StatefulWidget {
  const WakeWordTestScreen({super.key});

  @override
  State<WakeWordTestScreen> createState() => _WakeWordTestScreenState();
}

class _WakeWordTestScreenState extends State<WakeWordTestScreen> {
  final JarvisListener _listener = JarvisListener();
  bool _isInitialized = false;
  bool _isListening = false;
  bool _isActive = false;
  String _lastWords = '';
  String _status = 'Not started';
  List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _addLog('Screen opened');
  }

  void _addLog(String message) {
    setState(() {
      _logs.insert(0, '${DateTime.now().toString().split('.').first}: $message');
      if (_logs.length > 20) _logs.removeLast();
    });
  }

  Future<void> _initialize() async {
    _addLog('Initializing wake word listener...');
    setState(() => _status = 'Initializing...');
    
    final success = await _listener.initialize();
    
    setState(() {
      _isInitialized = success;
      _status = success ? 'Initialized ✓' : 'Failed to initialize ✗';
    });
    
    _addLog('Initialization result: $success');
    
    if (success) {
      _listener.onWakeWordDetected = () {
        setState(() => _isActive = true);
        _addLog('🎉 WAKE WORD DETECTED!');
      };
      
      _listener.onError = (error) {
        _addLog('Error: $error');
      };
      
      _listener.onListeningStateChanged = (isListening) {
        setState(() => _isListening = isListening);
        _addLog('Listening state: $isListening');
      };
      
      _listener.onReturnToIdle = () {
        setState(() => _isActive = false);
        _addLog('Returned to idle');
      };
    }
  }

  Future<void> _startListening() async {
    _addLog('Starting wake word detection...');
    setState(() => _status = 'Listening...');
    await _listener.startListening();
  }

  Future<void> _stopListening() async {
    _addLog('Stopping wake word detection...');
    await _listener.stopListening();
    setState(() => _status = 'Stopped');
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E2749),
        title: const Text(
          'Wake Word Test',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Status Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2749),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Status: $_status',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatusIndicator('Initialized', _isInitialized),
                      _buildStatusIndicator('Listening', _isListening),
                      _buildStatusIndicator('Active', _isActive),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Instructions
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF00A8E8).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF00A8E8).withValues(alpha: 0.3),
                ),
              ),
              child: const Column(
                children: [
                  Text(
                    'How to test:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1. Tap "Initialize"\n2. Tap "Start Listening"\n3. Say "JARVIS" clearly\n4. Check if it detects in the logs below',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Control Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isInitialized ? null : _initialize,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A8E8),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Initialize'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: !_isInitialized || _isListening ? null : _startListening,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00FF88),
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Start'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isListening ? _stopListening : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Stop'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Last Heard Words
            if (_listener.debugStatus['lastRecognizedWords']?.isNotEmpty == true)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A3254),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Last heard: "${_listener.debugStatus['lastRecognizedWords']}"',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            
            // Logs
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0E27),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Logs:',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              _logs[index],
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? const Color(0xFF00FF88) : Colors.red,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? const Color(0xFF00FF88) : Colors.red,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
