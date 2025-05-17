import 'package:flutter/material.dart';
import '../services/payment_service.dart';
import 'purchase_complete.dart';

class CheckoutScreen extends StatefulWidget {
  final String projectId;
  final String projectName;
  final String stageName;

  const CheckoutScreen({
    Key? key,
    required this.projectId,
    required this.projectName,
    required this.stageName,
  }) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _paymentService = PaymentService();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Checkout - ${widget.stageName}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Project: ${widget.projectName}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Stage: ${widget.stageName}',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing
                      ? null
                      : () async {
                          final trimmedProjectName = widget.projectName.trim();
                          print('RECEIVED DATA:');
                          print('Project Name received:"$trimmedProjectName"');
                          print('Project ID received:"${widget.projectId}"');
                          print('Stage Name received:"${widget.stageName}"');
                          
                          setState(() {
                            _isProcessing = true;
                          });

                          try {
                            await _paymentService.updatePaymentStatus(
                              projectName: trimmedProjectName,
                              stageName: widget.stageName,
                            );

                            if (mounted) {
                              print('==========================================');
                              print('PAYMENT SUCCESSFUL');
                              print('==========================================');
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Payment successful!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              // Navigate to PurchaseCompleteScreen
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const PurchaseCompleteScreen(),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              print('==========================================');
                              print('PAYMENT FAILED');
                              print('Error: $e');
                              print('==========================================');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Payment failed: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() {
                                _isProcessing = false;
                              });
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isProcessing
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Pay',
                              style: TextStyle(fontSize: 18),
                            ),
                          ],
                        )
                      : const Text(
                          'Pay Now',
                          style: TextStyle(fontSize: 18),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
