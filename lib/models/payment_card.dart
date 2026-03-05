class PaymentCard {
  final int? id;
  final String number;
  final String expiry;
  final String cvv;
  final String holder;

  PaymentCard({
    this.id,
    required this.number,
    required this.expiry,
    required this.cvv,
    required this.holder,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'number': number,
      'expiry': expiry,
      'cvv': cvv,
      'holder': holder,
    };
  }

  factory PaymentCard.fromMap(Map<String, dynamic> map) {
    return PaymentCard(
      id: map['id'],
      number: map['number'],
      expiry: map['expiry'],
      cvv: map['cvv'],
      holder: map['holder'],
    );
  }
}