class Investment {
  final int? id;
  final String category; // 'currency', 'commodity', 'crypto'
  final String name; // 'USD', 'EUR', 'Gold', 'BTC' vs.
  final double amount; // Amount
  final double buyPrice; // Buy price
  final double currentPrice; // Current price
  final DateTime date; // Buy date

  Investment({
    this.id,
    required this.category,
    required this.name,
    required this.amount,
    required this.buyPrice,
    required this.currentPrice,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'name': name,
      'amount': amount,
      'buyPrice': buyPrice,
      'currentPrice': currentPrice,
      'date': date.toIso8601String(),
    };
  }

  factory Investment.fromMap(Map<String, dynamic> map) {
    return Investment(
      id: map['id'],
      category: map['category'],
      name: map['name'],
      amount: map['amount'],
      buyPrice: map['buyPrice'],
      currentPrice: map['currentPrice'],
      date: DateTime.parse(map['date']),
    );
  }

  Investment copyWith({
    int? id,
    String? category,
    String? name,
    double? amount,
    double? buyPrice,
    double? currentPrice,
    DateTime? date,
  }) {
    return Investment(
      id: id ?? this.id,
      category: category ?? this.category,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      buyPrice: buyPrice ?? this.buyPrice,
      currentPrice: currentPrice ?? this.currentPrice,
      date: date ?? this.date,
    );
  }
}
