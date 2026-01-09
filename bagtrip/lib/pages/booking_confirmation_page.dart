import 'package:bagtrip/booking/bloc/booking_intent_bloc.dart';
import 'package:bagtrip/models/booking_intent.dart';
import 'package:bagtrip/payment/bloc/payment_bloc.dart';
import 'package:bagtrip/service/booking_intent_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class BookingConfirmationPage extends StatefulWidget {
  final String intentId;

  const BookingConfirmationPage({super.key, required this.intentId});

  @override
  State<BookingConfirmationPage> createState() =>
      _BookingConfirmationPageState();
}

class _BookingConfirmationPageState extends State<BookingConfirmationPage> {
  final BookingIntentService _bookingIntentService = BookingIntentService();
  BookingIntent? _bookingIntent;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBookingIntent();
  }

  Future<void> _loadBookingIntent() async {
    try {
      final intent = await _bookingIntentService.getBookingIntent(
        widget.intentId,
      );
      setState(() {
        _bookingIntent = intent;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _capturePayment() {
    if (_bookingIntent == null) return;

    context.read<PaymentBloc>().add(
      CapturePayment(intentId: _bookingIntent!.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $_error'),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      );
    }

    if (_bookingIntent == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Not Found')),
        body: const Center(child: Text('Booking intent not found')),
      );
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => BookingIntentBloc()),
        BlocProvider(create: (context) => PaymentBloc()),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<PaymentBloc, PaymentState>(
            listener: (context, state) {
              if (state is PaymentCaptured) {
                // Refresh booking intent after capture
                _loadBookingIntent();
              } else if (state is PaymentError) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${state.message}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
        child: Scaffold(
          appBar: AppBar(title: const Text('Booking Confirmation')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  _bookingIntent!.status == BookingIntentStatus.captured
                      ? Icons.check_circle
                      : _bookingIntent!.status == BookingIntentStatus.booked
                      ? Icons.payment
                      : Icons.info,
                  color:
                      _bookingIntent!.status == BookingIntentStatus.captured
                          ? Colors.green
                          : _bookingIntent!.status == BookingIntentStatus.booked
                          ? Colors.orange
                          : Colors.blue,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  _bookingIntent!.status == BookingIntentStatus.captured
                      ? 'Booking Confirmed!'
                      : _bookingIntent!.status == BookingIntentStatus.booked
                      ? 'Flight Booked!'
                      : 'Booking Details',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_bookingIntent!.status == BookingIntentStatus.booked) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Your flight has been booked. Please capture the payment to complete the transaction.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.orange),
                  ),
                ],
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Booking Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Booking ID: ${_bookingIntent!.id}'),
                        Text('Status: ${_bookingIntent!.status.value}'),
                        Text(
                          'Amount: ${_bookingIntent!.amount} ${_bookingIntent!.currency}',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (_bookingIntent!.status == BookingIntentStatus.booked) ...[
                  BlocBuilder<PaymentBloc, PaymentState>(
                    builder: (context, state) {
                      final isLoading = state is PaymentCapturing;
                      return ElevatedButton(
                        onPressed: isLoading ? null : _capturePayment,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.purple,
                        ),
                        child:
                            isLoading
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : const Text('Capture Payment'),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                ElevatedButton(
                  onPressed: () => context.go('/home'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Back to Home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
