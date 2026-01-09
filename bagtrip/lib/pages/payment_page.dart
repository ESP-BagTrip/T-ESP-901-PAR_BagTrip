import 'package:bagtrip/payment/bloc/payment_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class PaymentPage extends StatefulWidget {
  final String intentId;
  final String tripId;
  final double price;
  final String currency;
  final String? flightOfferId; // Optional: to pass back to booking page

  const PaymentPage({
    super.key,
    required this.intentId,
    required this.tripId,
    required this.price,
    required this.currency,
    this.flightOfferId,
  });

  static const String routePath = '/payment/:intentId';

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  @override
  void initState() {
    super.initState();
    // Authorize payment when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PaymentBloc>().add(
          AuthorizePayment(intentId: widget.intentId),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: BlocConsumer<PaymentBloc, PaymentState>(
        listener: (context, state) {
          if (!mounted) return;

          if (state is PaymentAuthorized) {
            // Payment authorized, confirm it (test mode)
            // Auto-confirm in test mode
            if (mounted) {
              context.read<PaymentBloc>().add(
                ConfirmPayment(intentId: widget.intentId),
              );
            }
          } else if (state is PaymentAuthorizedConfirmed) {
            // Payment confirmed and authorized, navigate to flight booking
            if (mounted) {
              context.go(
                '/flight-booking',
                extra: {
                  'tripId': widget.tripId,
                  'offerId': widget.flightOfferId ?? '',
                  'price': widget.price,
                  'currency': widget.currency,
                  'intentId': widget.intentId,
                },
              );
            }
          } else if (state is PaymentError) {
            if (mounted) {
              // Show detailed error message
              final errorMsg = state.message;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Payment error: $errorMsg'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 5),
                ),
              );
            }
          }
        },
        builder: (context, state) {
          if (state is PaymentAuthorizing) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Authorizing payment...'),
                ],
              ),
            );
          }

          if (state is PaymentAuthorized) {
            // Payment authorized, auto-confirming (handled in listener)
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Confirming payment...'),
                ],
              ),
            );
          }

          if (state is PaymentConfirming) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Confirming payment...'),
                  SizedBox(height: 8),
                  Text(
                    'Waiting for payment authorization...',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            );
          }

          // Show polling state when waiting for AUTHORIZED status
          // This happens after PaymentConfirming when we're polling
          if (state is PaymentAuthorizedConfirmed) {
            // This state means we're done polling and authorized
            // Navigation will happen in the listener
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Payment authorized!'),
                  SizedBox(height: 8),
                  Text('Redirecting...', style: TextStyle(fontSize: 12)),
                ],
              ),
            );
          }

          if (state is PaymentError) {
            return SingleChildScrollView(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text('Error: ${state.message}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.read<PaymentBloc>().add(
                            AuthorizePayment(intentId: widget.intentId),
                          );
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
