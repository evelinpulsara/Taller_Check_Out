import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/database_service.dart';
import '../models/payment_card.dart';

class CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.length > 16) text = text.substring(0, 16);
    String formatted = '';
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) formatted += ' ';
      formatted += text[i];
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.length > 4) text = text.substring(0, 4);
    String formatted = text;
    if (text.length > 2) formatted = text.substring(0, 2) + '/' + text.substring(2);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final DatabaseService _dbService = DatabaseService();
  PaymentCard? _savedCard;
  String _selectedMethod = 'Credit';
  bool _saveCardData = true;

  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _holderController = TextEditingController();
  final TextEditingController _promoController = TextEditingController(text: 'PROMO20-08');

  String _lastFourDigits = '';
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadSavedCard();
  }

  Future<void> _loadSavedCard() async {
    final card = await _dbService.getLastPaymentCard();
    if (card != null) {
      setState(() {
        _savedCard = card;
        _lastFourDigits = card.number.length >= 2 ? card.number.substring(card.number.length - 2) : '';
      });
    }
  }

  void _proceedToConfirm() {
    if (_formKey.currentState!.validate()) {
      if (_saveCardData) {
        final cleanNumber = _cardNumberController.text.replaceAll(' ', '');
        final card = PaymentCard(
          number: cleanNumber,
          expiry: _expiryController.text,
          cvv: _cvvController.text,
          holder: _holderController.text,
        );
        _dbService.savePaymentCard(card).then((_) {
          setState(() {
            _savedCard = card;
            _lastFourDigits = cleanNumber.length >= 2 ? cleanNumber.substring(cleanNumber.length - 2) : '';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Card data saved successfully!')),
          );
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Proceeded to confirm without saving')),
        );
      }
    }
  }

  void _pay() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment successful! Thank you.')),
    );
  }

  void _editSavedCard() {
    if (_savedCard != null) {
      String formatted = '';
      final clean = _savedCard!.number;
      for (int i = 0; i < clean.length; i++) {
        if (i > 0 && i % 4 == 0) formatted += ' ';
        formatted += clean[i];
      }
      _cardNumberController.text = formatted;
      _expiryController.text = _savedCard!.expiry;
      _cvvController.text = _savedCard!.cvv;
      _holderController.text = _savedCard!.holder;
      setState(() => _selectedMethod = 'Credit');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Card data loaded for editing')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '\$50 off',
                          style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                        ),
                        const Text(
                          'On your first order',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '* Promo code valid for orders over \$150.',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Total price', style: TextStyle(fontSize: 16, color: Colors.grey)),
                const Text(
                  '\$2,280.00',
                  style: TextStyle(fontSize: 36, color: Color(0xFF6366F1), fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                const Text('Payment Method', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildPaymentMethod('PayPal', 'PayPal'),
                    _buildPaymentMethod('Credit', 'Credit'),
                    _buildPaymentMethod('Wallet', 'Wallet'),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Card number', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _cardNumberController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefix: _masterCardLogo(),
                    hintText: '**** **** **** ****',
                  ),
                  inputFormatters: [CardNumberFormatter()],
                  keyboardType: TextInputType.number,
                  validator: (v) => v != null && v.replaceAll(' ', '').length == 16 ? null : 'Enter valid 16 digit card number',
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Valid until'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _expiryController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              hintText: 'MM / YY',
                            ),
                            inputFormatters: [ExpiryDateFormatter()],
                            keyboardType: TextInputType.number,
                            validator: (v) => (v != null && v.length == 5 && v.contains('/')) ? null : 'MM/YY required',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('CVV'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _cvvController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              hintText: '***',
                            ),
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
                            keyboardType: TextInputType.number,
                            validator: (v) => (v != null && v.length == 3) ? null : '3 digits required',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Card holder'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _holderController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    hintText: 'Your name and surname',
                  ),
                  validator: (v) => v != null && v.isNotEmpty ? null : 'Card holder required',
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Save card data for future payments'),
                  value: _saveCardData,
                  activeColor: const Color(0xFF6366F1),
                  onChanged: (v) => setState(() => _saveCardData = v),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _proceedToConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text('Proceed to confirm', style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Payment information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    TextButton(onPressed: _editSavedCard, child: const Text('Edit')),
                  ],
                ),
                const SizedBox(height: 12),
                if (_savedCard != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        _masterCardLogo(),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Master Card', style: TextStyle(fontWeight: FontWeight.w500)),
                            Text('ending **$_lastFourDigits', style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  )
                else
                  const Text('No saved card yet. Save one above.'),
                const SizedBox(height: 24),
                const Text('Use promo code', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                TextField(
                  controller: _promoController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _pay,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text('Pay', style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethod(String label, String method) {
    bool isSelected = _selectedMethod == method;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = method),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : Colors.grey[200],
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.check_circle,
              color: isSelected ? Colors.white : Colors.grey,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _masterCardLogo() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 36,
          height: 24,
          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
        ),
        Positioned(
          left: 14,
          child: Container(
            width: 36,
            height: 24,
            decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(4)),
          ),
        ),
      ],
    );
  }
}