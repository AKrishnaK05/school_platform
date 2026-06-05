import 'package:flutter/material.dart';
import '../../services/snitch_api.dart';
import '../../theme/snitch_theme.dart';
import '../../widgets/snitch_card.dart';

class SnitchFees extends StatefulWidget {
  const SnitchFees({super.key});

  @override
  State<SnitchFees> createState() => _SnitchFeesState();
}

class _SnitchFeesState extends State<SnitchFees> {
  List<Map<String, dynamic>> _invoices = [];
  bool _loading = true;
  int? _studentId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final sid = await SnitchApi.getPrimaryStudentId();
    _studentId = sid;
    if (sid != null) {
      final inv = await SnitchApi.fetchStudentInvoices(sid);
      if (!mounted) return;
      setState(() {
        _invoices = inv;
        _loading = false;
      });
    } else {
      setState(() {
        _invoices = [];
        _loading = false;
      });
    }
  }

  Future<void> _pay(Map<String, dynamic> invoice) async {
    if (_studentId == null) return;
    final invoiceId = invoice['id'] as int;
    final balance = invoice['total_amount'] ?? invoice['pending_amount'] ?? '0';
    final amountController = TextEditingController(text: balance.toString());

    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Pay Invoice #$invoiceId'),
        content: TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Pay')),
        ],
      ),
    );

    if (res != true) return;
    final paid = await SnitchApi.payInvoice(_studentId!, invoiceId, amount: amountController.text);
    if (!mounted) return;
    if (paid != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment recorded')));
      });
      await _load();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment failed')));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fee Payments')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _invoices.isEmpty
              ? const Center(child: Text('No invoices'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    SnitchCard(
                      child: Row(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(color: SnitchTheme.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16)),
                            child: const Icon(Icons.account_balance_wallet_outlined, color: SnitchTheme.primary),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Outstanding Balance', style: TextStyle(fontWeight: FontWeight.w700)), SizedBox(height: 4), Text('Tap an invoice to clear pending dues', style: TextStyle(color: Colors.black54))])),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._invoices.map((inv) {
                      final pending = inv['pending_amount'] ?? inv['total_amount'] ?? '0';
                      final dueDate = inv['due_date'] ?? '';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SnitchCard(
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(inv['title'] ?? 'Invoice', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 4),
                                    Text('Due: $dueDate', style: const TextStyle(color: Colors.black54)),
                                    const SizedBox(height: 8),
                                    Text('Pending: Rs $pending', style: const TextStyle(fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 108,
                                child: ElevatedButton(
                                  onPressed: () => _pay(inv),
                                  child: const Text('Pay'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
    );
  }
}
