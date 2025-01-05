import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:wallettrack/models/expense.dart';
import 'package:wallettrack/models/income.dart';
import 'package:wallettrack/models/investment.dart';
import 'package:wallettrack/services/database_service.dart';
import 'package:wallettrack/widgets/logo.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({
    super.key,
    required this.database,
  });

  final AppDbService database;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<Income> _incomes = [];
  List<Expense> _expenses = [];
  List<Investment> _investments = [];
  DateTime _currentMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final incomes = await widget.database.getIncomes();
    final expenses = await widget.database.getExpenses();
    final investments = await widget.database.getInvestments();
    if (!mounted) return;
    setState(() {
      _incomes = incomes;
      _expenses = expenses;
      _investments = investments;
    });
  }

  String formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'en_US', symbol: '₺').format(amount);
  }

  String formatChartCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M ₺';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K ₺';
    }
    return '${amount.toStringAsFixed(0)} ₺';
  }

  Widget _buildChartCurrencyText(double amount) {
    return Text(
      formatChartCurrency(amount.abs()),
      style: TextStyle(
        fontSize: 10,
        color: amount < 0 ? Colors.redAccent.shade200 : null,
      ),
    );
  }

  Map<int, double> _calculateMonthlyTotals(List<dynamic> items) {
    final Map<int, double> monthlyTotals = {
      1: 0,
      2: 0,
      3: 0,
      4: 0,
      5: 0,
      6: 0,
      7: 0,
      8: 0,
      9: 0,
      10: 0,
      11: 0,
      12: 0
    };

    for (var item in items) {
      if (item is Income) {
        if (item.isRecurring) {
          DateTime checkDate = item.date;
          while (checkDate.year == DateTime.now().year) {
            switch (item.recurringPeriod) {
              case 'weekly':
                if (checkDate.month <= 12) {
                  monthlyTotals[checkDate.month] =
                      (monthlyTotals[checkDate.month] ?? 0) + item.amount;
                }
                checkDate = checkDate.add(const Duration(days: 7));
              case 'monthly':
                if (checkDate.month <= 12) {
                  monthlyTotals[checkDate.month] =
                      (monthlyTotals[checkDate.month] ?? 0) + item.amount;
                }
                checkDate = DateTime(
                    checkDate.year, checkDate.month + 1, checkDate.day);
              case 'yearly':
                if (checkDate.month <= 12) {
                  monthlyTotals[checkDate.month] =
                      (monthlyTotals[checkDate.month] ?? 0) + item.amount;
                }
            }
            if (checkDate.month > 12) break;
          }
        } else {
          if (item.date.year == DateTime.now().year && item.date.month <= 12) {
            monthlyTotals[item.date.month] =
                (monthlyTotals[item.date.month] ?? 0) + item.amount;
          }
        }
      } else if (item is Expense) {
        if (item.isInstallment) {
          final monthlyAmount = item.amount / (item.totalInstallments ?? 1);
          final startDate = item.date;

          for (var i = 0; i < (item.totalInstallments ?? 1); i++) {
            final installmentDate = DateTime(
              startDate.year,
              startDate.month + i,
              startDate.day,
            );

            if (installmentDate.year == DateTime.now().year &&
                installmentDate.month <= 12) {
              monthlyTotals[installmentDate.month] =
                  (monthlyTotals[installmentDate.month] ?? 0) + monthlyAmount;
            }
          }
        } else {
          if (item.date.year == DateTime.now().year && item.date.month <= 12) {
            monthlyTotals[item.date.month] =
                (monthlyTotals[item.date.month] ?? 0) + item.amount;
          }
        }
      }
    }

    return monthlyTotals;
  }

  Widget _buildIncomeExpenseChart() {
    final monthlyIncomes = _calculateMonthlyTotals(_incomes);
    final monthlyExpenses = _calculateMonthlyTotals(_expenses);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Income vs Expense',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          AspectRatio(
            aspectRatio: 1.7,
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: Theme.of(context).cardColor,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          formatCurrency(spot.y),
                          TextStyle(
                            color: spot.barIndex == 0
                                ? Colors.green.shade400
                                : Colors.redAccent.shade200,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            DateFormat('MMM')
                                .format(DateTime(2024, value.toInt())),
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: _buildChartCurrencyText(value),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(12, (index) {
                      final month = index + 1;
                      return FlSpot(
                          month.toDouble(), monthlyIncomes[month] ?? 0);
                    }),
                    isCurved: true,
                    color: Colors.green.shade400,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.green.shade400.withOpacity(0.1),
                    ),
                  ),
                  LineChartBarData(
                    spots: List.generate(12, (index) {
                      final month = index + 1;
                      return FlSpot(
                          month.toDouble(), monthlyExpenses[month] ?? 0);
                    }),
                    isCurved: true,
                    color: Colors.redAccent.shade200,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.redAccent.shade200.withOpacity(0.1),
                    ),
                  ),
                ],
                minX: 1,
                maxX: 12,
                minY: 0,
                maxY: _calculateMaxY(monthlyIncomes, monthlyExpenses),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Income', Colors.green.shade400),
              const SizedBox(width: 24),
              _buildLegendItem('Expense', Colors.redAccent.shade200),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }

  double _calculateMaxY(Map<int, double> incomes, Map<int, double> expenses) {
    double maxIncome =
        incomes.values.fold(0, (max, value) => value > max ? value : max);
    double maxExpense =
        expenses.values.fold(0, (max, value) => value > max ? value : max);
    return (maxIncome > maxExpense ? maxIncome : maxExpense) * 1.2;
  }

  Widget _buildMonthlySummary() {
    final monthlyIncomes = _calculateMonthlyTotals(_incomes);
    final monthlyExpenses = _calculateMonthlyTotals(_expenses);
    final currentMonthIncome = monthlyIncomes[_currentMonth.month] ?? 0;
    final currentMonthExpense = monthlyExpenses[_currentMonth.month] ?? 0;
    final balance = currentMonthIncome - currentMonthExpense;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Summary (${DateFormat('MMMM y', 'en_US').format(_currentMonth)})',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          _buildSummaryItem('Total Income', currentMonthIncome, Colors.green),
          const SizedBox(height: 16),
          _buildSummaryItem('Total Expense', currentMonthExpense, Colors.red),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(),
          ),
          _buildSummaryItem(
              'Balance', balance, balance >= 0 ? Colors.green : Colors.red),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          formatCurrency(amount),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              title: const Text('Reports'),
              pinned: true,
              floating: true,
              leading: WalletLogo(),
              snap: false,
              forceElevated: innerBoxIsScrolled,
              backgroundColor: Theme.of(context).colorScheme.surface,
              bottom: TabBar(
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Monthly Details'),
                  Tab(text: 'Income/Expense Trend'),
                  Tab(text: 'Installment Schedule'),
                  Tab(text: 'Investment Performance'),
                  Tab(text: 'Savings Analysis'),
                ],
                indicatorColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _buildOverview(),
              _buildMonthlySummary(),
              _buildIncomeExpenseChart(),
              _buildInstallmentTimeline(),
              _buildInvestmentPerformance(),
              _buildSavingsAnalysis(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverview() {
    final totalInvestmentValue = _investments.fold<double>(
      0,
      (sum, inv) => sum + (inv.amount * inv.currentPrice),
    );

    final totalInvestmentProfit = _investments.fold<double>(
      0,
      (sum, inv) => sum + ((inv.currentPrice - inv.buyPrice) * inv.amount),
    );

    final totalInstallmentDebt =
        _expenses.where((e) => e.isInstallment).fold<double>(
              0,
              (sum, e) =>
                  sum +
                  (e.amount /
                      e.totalInstallments! *
                      (e.totalInstallments! - e.paidInstallments!)),
            );

    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Financial Overview',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                _buildOverviewItem(
                  'Total Assets',
                  totalInvestmentValue,
                  Icons.account_balance_wallet,
                  Colors.blue,
                ),
                const SizedBox(height: 16),
                _buildOverviewItem(
                  'Total Profit/Loss',
                  totalInvestmentProfit,
                  Icons.trending_up,
                  totalInvestmentProfit >= 0 ? Colors.green : Colors.red,
                ),
                const SizedBox(height: 16),
                _buildOverviewItem(
                  'Installment Debt',
                  totalInstallmentDebt,
                  Icons.payment,
                  Colors.orange,
                ),
              ],
            ),
          ),
          _buildMonthlyComparisonChart(),
          _buildUpcomingPayments(),
          _buildTopPerformers(),
        ],
      ),
    );
  }

  Widget _buildOverviewItem(
      String title, double value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                formatCurrency(value),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyComparisonChart() {
    final monthlyIncomes = _calculateMonthlyTotals(_incomes);
    final monthlyExpenses = _calculateMonthlyTotals(_expenses);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Comparison',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 1.7,
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: Theme.of(context).cardColor,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          formatCurrency(spot.y),
                          TextStyle(
                            color: spot.barIndex == 0
                                ? Colors.green.shade400
                                : Colors.redAccent.shade200,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            DateFormat('MMM')
                                .format(DateTime(2024, value.toInt())),
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: _buildChartCurrencyText(value),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(12, (index) {
                      final month = index + 1;
                      final balance = (monthlyIncomes[month] ?? 0) -
                          (monthlyExpenses[month] ?? 0);
                      return FlSpot(month.toDouble(), balance);
                    }),
                    isCurved: true,
                    color: Colors.blue.shade400,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 6,
                          color: spot.y >= 0
                              ? Colors.green.shade400
                              : Colors.redAccent.shade200,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.shade400.withOpacity(0.1),
                          Colors.blue.shade400.withOpacity(0.05),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                minX: 1,
                maxX: 12,
                minY: _calculateMinY(monthlyIncomes, monthlyExpenses),
                maxY: _calculateMaxY(monthlyIncomes, monthlyExpenses),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateMinY(Map<int, double> incomes, Map<int, double> expenses) {
    double minBalance = 0;
    for (int i = 1; i <= 12; i++) {
      final balance = (incomes[i] ?? 0) - (expenses[i] ?? 0);
      if (balance < minBalance) minBalance = balance;
    }
    return minBalance * 1.2;
  }

  Widget _buildUpcomingPayments() {
    final now = DateTime.now();
    final upcomingPayments = _expenses
        .where((e) => e.isInstallment)
        .where((e) =>
            e.paidInstallments! < e.totalInstallments! &&
            e.date.month >= now.month)
        .take(3)
        .toList();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Upcoming Payments',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  'Top 3',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...upcomingPayments.map((e) => ListTile(
                  title: Text(e.name),
                  subtitle: Text(
                      'Installment ${e.paidInstallments! + 1}/${e.totalInstallments}'),
                  trailing: Text(
                    formatCurrency(e.amount / e.totalInstallments!),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildTopPerformers() {
    final sortedInvestments = List<Investment>.from(_investments)
      ..sort((a, b) {
        final profitA = (a.currentPrice - a.buyPrice) / a.buyPrice * 100;
        final profitB = (b.currentPrice - b.buyPrice) / b.buyPrice * 100;
        return profitB.compareTo(profitA);
      });

    final topPerformers = sortedInvestments.take(3).toList();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Best Performance',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  'Top 3',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...topPerformers.map((inv) {
              final profitPercentage =
                  (inv.currentPrice - inv.buyPrice) / inv.buyPrice * 100;
              return ListTile(
                title: Text(inv.name),
                subtitle: Text(
                    inv.category[0].toUpperCase() + inv.category.substring(1)),
                trailing: Text(
                  '${profitPercentage.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: profitPercentage >= 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSavingsAnalysis() {
    final monthlyIncomes = _calculateMonthlyTotals(_incomes);
    final monthlyExpenses = _calculateMonthlyTotals(_expenses);

    final monthlySavings = Map.fromEntries(
      monthlyIncomes.entries.map(
        (e) => MapEntry(
          e.key,
          e.value - (monthlyExpenses[e.key] ?? 0),
        ),
      ),
    );

    final averageSavings = monthlySavings.values.reduce((a, b) => a + b) /
        monthlySavings.values.length;

    return SingleChildScrollView(
      child: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Savings Statistics',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildMetricTile(
                    'Average Monthly Savings',
                    averageSavings,
                    Icons.savings,
                    Colors.green,
                  ),
                  // Savings trend chart
                ],
              ),
            ),
          ),
          // Savings tips card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Saving Tips',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildSavingTip(
                    'Installment Management',
                    'Plan your installment payments according to your income periods.',
                    Icons.calendar_today,
                  ),
                  _buildSavingTip(
                    'Investment Diversification',
                    'Distribute your investments across different categories to reduce risk.',
                    Icons.pie_chart,
                  ),
                  _buildSavingTip(
                    'Regular Savings',
                    'Set aside a percentage of your monthly income for savings.',
                    Icons.repeat,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingTip(String title, String description, IconData icon) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue.withOpacity(0.1),
        child: Icon(icon, color: Colors.blue),
      ),
      title: Text(title),
      subtitle: Text(description),
    );
  }

  Widget _buildInvestmentPerformance() {
    final categoryColors = {
      'Currency': Colors.blue,
      'Commodity': Colors.amber,
      'Crypto': Colors.purple,
    };

    // Investment categories pie chart
    final categoryTotals = <String, double>{
      'Currency': 0,
      'Commodity': 0,
      'Crypto': 0,
    };

    for (var investment in _investments) {
      final total = investment.amount * investment.currentPrice;
      switch (investment.category) {
        case 'currency':
          categoryTotals['Currency'] =
              (categoryTotals['Currency'] ?? 0) + total;
        case 'commodity':
          categoryTotals['Commodity'] =
              (categoryTotals['Commodity'] ?? 0) + total;
        case 'crypto':
          categoryTotals['Crypto'] = (categoryTotals['Crypto'] ?? 0) + total;
      }
    }

    // Profit/loss calculation
    final profitByCategory = <String, double>{
      'Currency': 0,
      'Commodity': 0,
      'Crypto': 0,
    };

    for (var investment in _investments) {
      final profit =
          (investment.currentPrice - investment.buyPrice) * investment.amount;
      switch (investment.category) {
        case 'currency':
          profitByCategory['Currency'] =
              (profitByCategory['Currency'] ?? 0) + profit;
        case 'commodity':
          profitByCategory['Commodity'] =
              (profitByCategory['Commodity'] ?? 0) + profit;
        case 'crypto':
          profitByCategory['Crypto'] =
              (profitByCategory['Crypto'] ?? 0) + profit;
      }
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Investment Distribution',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  AspectRatio(
                    aspectRatio: 1.3,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: categoryTotals.entries
                            .map(
                              (e) => PieChartSectionData(
                                value: e.value,
                                title: e.key,
                                titleStyle: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                radius: 100,
                                color: categoryColors[e.key],
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...categoryTotals.entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: categoryColors[e.key],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(e.key),
                          const Spacer(),
                          Text(
                            formatCurrency(e.value),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profit/Loss Analysis',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ...profitByCategory.entries.map(
                    (e) => ListTile(
                      title: Text(e.key),
                      trailing: Text(
                        formatCurrency(e.value),
                        style: TextStyle(
                          color: e.value >= 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstallmentTimeline() {
    final installmentExpenses =
        _expenses.where((e) => e.isInstallment).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: installmentExpenses.length,
      itemBuilder: (context, index) {
        final expense = installmentExpenses[index];
        final monthlyAmount = expense.amount / expense.totalInstallments!;
        final paidAmount = monthlyAmount * expense.paidInstallments!;
        final remainingAmount = expense.amount - paidAmount;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      expense.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    formatCurrency(expense.amount),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: List.generate(
                  expense.totalInstallments!,
                  (i) {
                    final isCurrentMonth = i == expense.paidInstallments;
                    final isPaid = i < expense.paidInstallments!;

                    return Expanded(
                      child: Container(
                        height: 36,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        child: Column(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: isPaid
                                    ? Colors.green.shade400
                                    : isCurrentMonth
                                        ? Colors.orange
                                        : Colors.grey.shade300,
                                shape: BoxShape.circle,
                                border: isCurrentMonth
                                    ? Border.all(
                                        color: Colors.orange.shade700,
                                        width: 2,
                                      )
                                    : null,
                              ),
                              child: isPaid
                                  ? const Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            if (i < expense.totalInstallments! - 1)
                              Expanded(
                                child: Container(
                                  width: 2,
                                  color: isPaid
                                      ? Colors.green.shade400
                                      : Colors.grey.shade300,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monthly Payment',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      Text(
                        formatCurrency(monthlyAmount),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Remaining',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      Text(
                        formatCurrency(remainingAmount),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricTile(
      String title, double value, IconData icon, Color color) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      trailing: Text(
        formatCurrency(value),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
