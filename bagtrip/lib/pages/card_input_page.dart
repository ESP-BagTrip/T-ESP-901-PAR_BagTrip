import 'package:bagtrip/payment/bloc/payment_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class CardInputPage extends StatefulWidget {
  final String intentId;
  final String tripId;
  final double price;
  final String currency;
  final String? flightOfferId;

  const CardInputPage({
    super.key,
    required this.intentId,
    required this.tripId,
    required this.price,
    required this.currency,
    this.flightOfferId,
  });

  static const String routePath = '/card-input/:intentId';

  @override
  State<CardInputPage> createState() => _CardInputPageState();
}

class _CardInputPageState extends State<CardInputPage> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardholderNameController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardholderNameController.dispose();
    super.dispose();
  }

  String _formatCardNumber(String value) {
    // Remove all non-digits
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');

    // Add spaces every 4 digits
    final buffer = StringBuffer();
    for (int i = 0; i < digitsOnly.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(digitsOnly[i]);
    }
    return buffer.toString();
  }

  String _formatExpiry(String value) {
    // Remove all non-digits
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');

    // Format as MM/YY
    if (digitsOnly.length >= 2) {
      return '${digitsOnly.substring(0, 2)}/${digitsOnly.length > 2 ? digitsOnly.substring(2, 4) : ''}';
    }
    return digitsOnly;
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    // In test mode, confirm payment with test card
    // The card details are fake/for display only
    context.read<PaymentBloc>().add(ConfirmPayment(intentId: widget.intentId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PaymentBloc, PaymentState>(
      listener: (context, state) {
        if (state is PaymentAuthorizedConfirmed) {
          // Payment confirmed and authorized, navigate to booking page
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
          setState(() {
            _isSubmitting = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Payment error: ${state.message}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Payment Information')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Payment Summary Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Payment Summary',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Amount: ${widget.price} ${widget.currency}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Card Number
                TextFormField(
                  controller: _cardNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Card Number',
                    hintText: '4242 4242 4242 4242',
                    prefixIcon: Icon(Icons.credit_card),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(
                      19,
                    ), // 16 digits + 3 spaces
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      final formatted = _formatCardNumber(newValue.text);
                      return TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(
                          offset: formatted.length,
                        ),
                      );
                    }),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter card number';
                    }
                    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
                    if (digitsOnly.length < 13 || digitsOnly.length > 19) {
                      return 'Invalid card number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Cardholder Name
                TextFormField(
                  controller: _cardholderNameController,
                  decoration: const InputDecoration(
                    labelText: 'Cardholder Name',
                    hintText: 'John Doe',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter cardholder name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Expiry and CVV Row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _expiryController,
                        decoration: const InputDecoration(
                          labelText: 'Expiry Date',
                          hintText: 'MM/YY',
                          prefixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                          TextInputFormatter.withFunction((oldValue, newValue) {
                            final formatted = _formatExpiry(newValue.text);
                            return TextEditingValue(
                              text: formatted,
                              selection: TextSelection.collapsed(
                                offset: formatted.length,
                              ),
                            );
                          }),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          final digitsOnly = value.replaceAll(
                            RegExp(r'\D'),
                            '',
                          );
                          if (digitsOnly.length != 4) {
                            return 'Invalid format';
                          }
                          final month = int.tryParse(
                            digitsOnly.substring(0, 2),
                          );
                          if (month == null || month < 1 || month > 12) {
                            return 'Invalid month';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _cvvController,
                        decoration: const InputDecoration(
                          labelText: 'CVV',
                          hintText: '123',
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          if (value.length < 3 || value.length > 4) {
                            return 'Invalid CVV';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Info Banner (Test Mode)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Test Mode: Use card 4242 4242 4242 4242',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                BlocBuilder<PaymentBloc, PaymentState>(
                  builder: (context, state) {
                    final isLoading =
                        _isSubmitting || state is PaymentConfirming;
                    return ElevatedButton(
                      onPressed: isLoading ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green,
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
                              : const Text(
                                'Confirm Payment',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
