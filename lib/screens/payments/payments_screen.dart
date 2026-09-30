import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/payments_provider.dart';
import '../../widgets/payment_card.dart';
import 'payment_details_dialog.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildFilterChip(String label, String currentFilter, ValueChanged<String> onSelected) {
    final bool isSelected = currentFilter == label;
    return GestureDetector(
      onTap: () => onSelected(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : AppTheme.borderLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paymentsProv = Provider.of<PaymentsProvider>(context);

    final filteredList = paymentsProv.payments.where((p) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return p.trxId.toLowerCase().contains(query) ||
          p.sender.toLowerCase().contains(query) ||
          p.provider.toLowerCase().contains(query) ||
          (p.orderId != null && p.orderId!.toLowerCase().contains(query)) ||
          p.amount.toString().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments History'),
        backgroundColor: AppTheme.primaryBlue,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search by TrxID, Sender or Order #',
                      prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: AppTheme.textMuted),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppTheme.backgroundLight,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All', paymentsProv.activeFilter, paymentsProv.setFilter),
                        const SizedBox(width: 8),
                        _buildFilterChip('Verified', paymentsProv.activeFilter, paymentsProv.setFilter),
                        const SizedBox(width: 8),
                        _buildFilterChip('Pending', paymentsProv.activeFilter, paymentsProv.setFilter),
                        const SizedBox(width: 8),
                        _buildFilterChip('Unmatched', paymentsProv.activeFilter, paymentsProv.setFilter),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: filteredList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.search_off, size: 48, color: AppTheme.textMuted),
                          SizedBox(height: 8),
                          Text(
                            'No payment records found',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final p = filteredList[index];
                        return PaymentCard(
                          payment: p,
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => PaymentDetailsDialog(payment: p),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
