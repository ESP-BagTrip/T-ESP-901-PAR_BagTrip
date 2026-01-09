import 'package:bagtrip/booking/bloc/booking_intent_bloc.dart';
import 'package:bagtrip/models/booking_intent.dart';
import 'package:bagtrip/models/traveler.dart';
import 'package:bagtrip/payment/bloc/payment_bloc.dart';
import 'package:bagtrip/service/traveler_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class FlightBookingPage extends StatefulWidget {
  final String tripId;
  final String flightOfferId;
  final double price;
  final String currency;
  final String? intentId; // Optional: if coming from payment page

  const FlightBookingPage({
    super.key,
    required this.tripId,
    required this.flightOfferId,
    required this.price,
    required this.currency,
    this.intentId,
  });

  static const String routePath = '/flight-booking/:tripId/:offerId';

  @override
  State<FlightBookingPage> createState() => _FlightBookingPageState();
}

class _FlightBookingPageState extends State<FlightBookingPage> {
  final TravelerService _travelerService = TravelerService();
  List<Traveler>? _travelers;
  Traveler? _selectedTraveler;
  bool _loadingTravelers = true;
  String? _error;
  BookingIntent? _currentBookingIntent;
  bool _intentLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadTravelers();
  }

  Future<void> _loadTravelers() async {
    setState(() {
      _loadingTravelers = true;
      _error = null;
    });

    try {
      final travelers = await _travelerService.getTravelersByTrip(
        widget.tripId,
      );
      setState(() {
        _travelers = travelers;
        if (travelers.isNotEmpty) {
          _selectedTraveler = travelers.first;
        }
        _loadingTravelers = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loadingTravelers = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => BookingIntentBloc()),
        BlocProvider(create: (context) => PaymentBloc()),
      ],
      child: Builder(
        builder: (context) {
          // Load booking intent if intentId is provided and not yet loaded
          if (widget.intentId != null && !_intentLoaded) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_intentLoaded) {
                setState(() {
                  _intentLoaded = true;
                });
                context.read<BookingIntentBloc>().add(
                  GetBookingIntent(intentId: widget.intentId!),
                );
              }
            });
          }

          return Scaffold(
            appBar: AppBar(title: const Text('Book Flight')),
            body: MultiBlocListener(
              listeners: [
                BlocListener<BookingIntentBloc, BookingIntentState>(
                  listener: (context, state) {
                    if (!mounted) return;

                    if (state is BookingIntentCreated) {
                      final bookingIntent = state.bookingIntent;
                      setState(() {
                        _currentBookingIntent = bookingIntent;
                      });

                      if (bookingIntent.status == BookingIntentStatus.init) {
                        // Navigate to payment
                        if (mounted) {
                          context.go(
                            '/payment/${bookingIntent.id}',
                            extra: {
                              'tripId': widget.tripId,
                              'price': widget.price,
                              'currency': widget.currency,
                              'flightOfferId':
                                  widget.flightOfferId, // Pass flightOfferId
                            },
                          );
                        }
                      } else if (bookingIntent.status ==
                          BookingIntentStatus.captured) {
                        // Payment captured, navigate to confirmation
                        if (mounted) {
                          context.go(
                            '/booking-confirmation/${bookingIntent.id}',
                          );
                        }
                      }
                    } else if (state is BookingIntentError) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: ${state.message}')),
                        );
                      }
                    }
                  },
                ),
                BlocListener<PaymentBloc, PaymentState>(
                  listener: (context, state) {
                    if (!mounted) return;

                    if (state is PaymentCaptured) {
                      // Payment captured, refresh booking intent to get updated status
                      if (_currentBookingIntent != null) {
                        context.read<BookingIntentBloc>().add(
                          GetBookingIntent(intentId: _currentBookingIntent!.id),
                        );
                      }
                    } else if (state is PaymentError) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Payment error: ${state.message}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
              child: BlocBuilder<BookingIntentBloc, BookingIntentState>(
                builder: (context, bookingIntentState) {
                  if (_loadingTravelers) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (_error != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Error: $_error'),
                          ElevatedButton(
                            onPressed: _loadTravelers,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (_travelers == null || _travelers!.isEmpty) {
                    return Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.person_add_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No travelers found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Please add a traveler to continue with the booking.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () {
                                if (context.mounted) {
                                  _showCreateTravelerDialog(context);
                                }
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Add Traveler'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () => context.pop(),
                              child: const Text('Go Back'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Flight summary
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Flight Summary',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Price: ${widget.price} ${widget.currency}',
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Traveler selection
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Select Traveler',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                RadioGroup<Traveler>(
                                  groupValue: _selectedTraveler,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedTraveler = value;
                                    });
                                  },
                                  child: Column(
                                    children:
                                        _travelers!.map((traveler) {
                                          return RadioListTile<Traveler>(
                                            title: Text(
                                              '${traveler.firstName} ${traveler.lastName}',
                                            ),
                                            subtitle: Text(
                                              traveler.travelerType,
                                            ),
                                            value: traveler,
                                          );
                                        }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Show different buttons based on booking intent status
                        if (_currentBookingIntent == null ||
                            _currentBookingIntent!.status ==
                                BookingIntentStatus.init) ...[
                          // Create booking intent button (initial state)
                          ElevatedButton(
                            onPressed:
                                bookingIntentState is BookingIntentLoading
                                    ? null
                                    : () {
                                      if (_selectedTraveler == null) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Please select a traveler',
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      context.read<BookingIntentBloc>().add(
                                        CreateBookingIntent(
                                          tripId: widget.tripId,
                                          type: BookingIntentType.flight,
                                          flightOfferId: widget.flightOfferId,
                                        ),
                                      );
                                    },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child:
                                bookingIntentState is BookingIntentLoading
                                    ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Text('Continue to Payment'),
                          ),
                        ] else if (_currentBookingIntent!.status ==
                            BookingIntentStatus.authorized) ...[
                          // Book flight button (only when AUTHORIZED)
                          Builder(
                            builder: (buttonContext) {
                              return ElevatedButton(
                                onPressed:
                                    bookingIntentState is BookingIntentLoading
                                        ? null
                                        : () {
                                          if (_selectedTraveler == null) {
                                            ScaffoldMessenger.of(
                                              buttonContext,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Please select a traveler',
                                                ),
                                              ),
                                            );
                                            return;
                                          }

                                          _bookFlight(
                                            _currentBookingIntent!.id,
                                            buttonContext,
                                          );
                                        },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                                child:
                                    bookingIntentState is BookingIntentLoading
                                        ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                        : const Text('Book Flight'),
                              );
                            },
                          ),
                        ] else if (_currentBookingIntent!.status ==
                            BookingIntentStatus.booked) ...[
                          // Show status and capture option
                          Card(
                            color: Colors.blue.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Flight Booked!',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Your flight has been booked. You can now capture the payment.',
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () {
                                      context.read<PaymentBloc>().add(
                                        CapturePayment(
                                          intentId: _currentBookingIntent!.id,
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      backgroundColor: Colors.purple,
                                    ),
                                    child: const Text('Capture Payment'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void _bookFlight(String intentId, BuildContext? context) {
    if (_selectedTraveler == null) return;
    if (context == null || !context.mounted) return;

    try {
      context.read<BookingIntentBloc>().add(
        BookFlight(
          intentId: intentId,
          travelerIds: [_selectedTraveler!.id],
          contacts: [
            {
              'emailAddress':
                  _selectedTraveler!.contacts?['emailAddress'] ??
                  'user@example.com',
            },
          ],
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error booking flight: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showCreateTravelerDialog(BuildContext context) async {
    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder:
          (dialogContext) => _CreateTravelerDialog(
            tripId: widget.tripId,
            onTravelerCreated: () async {
              await _loadTravelers();
              // Use the dialog context for showing snackbar, or parent context if dialog is closed
              if (!context.mounted) return;
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              scaffoldMessenger.showSnackBar(
                const SnackBar(content: Text('Traveler added successfully')),
              );
            },
          ),
    );
  }
}

class _CreateTravelerDialog extends StatefulWidget {
  final String tripId;
  final VoidCallback onTravelerCreated;

  const _CreateTravelerDialog({
    required this.tripId,
    required this.onTravelerCreated,
  });

  @override
  State<_CreateTravelerDialog> createState() => _CreateTravelerDialogState();
}

class _CreateTravelerDialogState extends State<_CreateTravelerDialog> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  final _formKey = GlobalKey<FormState>();
  final TravelerService _travelerService = TravelerService();
  DateTime? _selectedDateOfBirth;
  String? _selectedGender;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;

    // Validate date of birth (required for Amadeus)
    if (_selectedDateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Date of birth is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _travelerService.createTraveler(
        widget.tripId,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        dateOfBirth: _selectedDateOfBirth,
        gender: _selectedGender,
        travelerType: 'ADULT',
        contacts: {
          'emailAddress': _emailController.text.trim(),
          if (_phoneController.text.trim().isNotEmpty)
            'phoneNumber': _phoneController.text.trim(),
        },
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onTravelerCreated();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Traveler'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name *',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name *',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Required';
                  }
                  if (!value.contains('@')) {
                    return 'Invalid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedGender,
                decoration: const InputDecoration(
                  labelText: 'Gender *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                items: const [
                  DropdownMenuItem(value: 'MALE', child: Text('Male')),
                  DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().subtract(
                      const Duration(days: 365 * 25),
                    ),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (date != null && mounted) {
                    setState(() {
                      _selectedDateOfBirth = date;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date of Birth *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _selectedDateOfBirth != null
                        ? DateFormat('yyyy-MM-dd').format(_selectedDateOfBirth!)
                        : 'Select date',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _handleSubmit,
          child:
              _isSubmitting
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Add'),
        ),
      ],
    );
  }
}
