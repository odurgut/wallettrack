class Income {
  final int id;
  final String name;
  final double amount;
  final DateTime date;
  final bool isRecurring;
  final String? recurringPeriod;
  final List<bool> receivedPaymentsList;

  Income({
    required this.id,
    required this.name,
    required this.amount,
    required this.date,
    this.isRecurring = false,
    this.recurringPeriod,
    List<bool>? receivedPaymentsList,
  }) : receivedPaymentsList = receivedPaymentsList ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'date': date.toIso8601String(),
      'isRecurring': isRecurring ? 1 : 0,
      'recurringPeriod': recurringPeriod,
      'receivedPaymentsList':
          receivedPaymentsList.map((e) => e ? 1 : 0).join(','),
    };
  }

  factory Income.fromMap(Map<String, dynamic> map) {
    final receivedPaymentsStr = map['receivedPaymentsList'] as String?;
    final receivedPaymentsList =
        receivedPaymentsStr?.split(',').map((e) => e == '1').toList() ?? [];

    return Income(
      id: map['id'] as int,
      name: map['name'] as String,
      amount: map['amount'] as double,
      date: DateTime.parse(map['date'] as String),
      isRecurring: map['isRecurring'] == 1,
      recurringPeriod: map['recurringPeriod'] as String?,
      receivedPaymentsList: receivedPaymentsList,
    );
  }

  Income copyWith({
    int? id,
    String? name,
    double? amount,
    DateTime? date,
    bool? isRecurring,
    String? recurringPeriod,
    List<bool>? receivedPaymentsList,
  }) {
    return Income(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringPeriod: recurringPeriod ?? this.recurringPeriod,
      receivedPaymentsList: receivedPaymentsList ?? this.receivedPaymentsList,
    );
  }
}
