class Expense {
  final int id;
  final String name;
  final double amount;
  final DateTime date;
  final bool isInstallment;
  final int? totalInstallments;
  final int? paidInstallments;
  final List<bool> paidInstallmentsList;
  final int currentInstallmentIndex;

  Expense({
    required this.id,
    required this.name,
    required this.amount,
    required this.date,
    this.isInstallment = false,
    this.totalInstallments,
    this.paidInstallments,
    List<bool>? paidInstallmentsList,
    this.currentInstallmentIndex = 0,
  }) : paidInstallmentsList = paidInstallmentsList ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'date': date.toIso8601String(),
      'isInstallment': isInstallment ? 1 : 0,
      'totalInstallments': totalInstallments,
      'paidInstallments': paidInstallments,
      'paidInstallmentsList':
          paidInstallmentsList.map((e) => e ? 1 : 0).join(','),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    final paidInstallmentsStr = map['paidInstallmentsList'] as String?;
    final paidInstallmentsList =
        paidInstallmentsStr?.split(',').map((e) => e == '1').toList() ?? [];

    return Expense(
      id: map['id'],
      name: map['name'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      isInstallment: map['isInstallment'] == 1,
      totalInstallments: map['totalInstallments'],
      paidInstallments: map['paidInstallments'],
      paidInstallmentsList: paidInstallmentsList,
      currentInstallmentIndex: map['currentInstallmentIndex'],
    );
  }

  Expense copyWith({
    int? id,
    String? name,
    double? amount,
    DateTime? date,
    bool? isInstallment,
    int? totalInstallments,
    int? paidInstallments,
    List<bool>? paidInstallmentsList,
    int? currentInstallmentIndex,
  }) {
    return Expense(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      isInstallment: isInstallment ?? this.isInstallment,
      totalInstallments: totalInstallments ?? this.totalInstallments,
      paidInstallments: paidInstallments ?? this.paidInstallments,
      paidInstallmentsList: paidInstallmentsList ?? this.paidInstallmentsList,
      currentInstallmentIndex:
          currentInstallmentIndex ?? this.currentInstallmentIndex,
    );
  }
}
