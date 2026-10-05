import 'package:flutter/material.dart';
import 'package:movera/core/money/bank_account.dart';

/// Payout account: one quiet list, Swedish clearing + account number or an
/// international IBAN + BIC. The bank is read from the numbers, not typed.
class AddNewAccount extends StatefulWidget {
  const AddNewAccount({super.key});

  @override
  State<AddNewAccount> createState() => _AddNewAccountState();
}

class _AddNewAccountState extends State<AddNewAccount> {
  static const Color _ink = Color(0xFF111614);
  static const Color _muted = Color(0xFF8A9390);
  static const Color _line = Color(0xFFE7E9EA);
  static const Color _green = Color(0xFF1FA463);
  static const Color _red = Color(0xFFC2453A);

  final _holder = TextEditingController();
  final _clearing = TextEditingController();
  final _account = TextEditingController();
  final _iban = TextEditingController();
  final _bic = TextEditingController();
  bool _international = false;
  bool _tried = false;

  @override
  void dispose() {
    for (final c in [_holder, _clearing, _account, _iban, _bic]) {
      c.dispose();
    }
    super.dispose();
  }

  String? get _bank => _international
      ? BankAccountRules.bankForIban(_iban.text)
      : BankAccountRules.bankForClearing(_clearing.text);

  String? get _problem {
    if (_holder.text.trim().isEmpty) return 'Add the account holder’s name.';
    if (_international) {
      if (!BankAccountRules.validIban(_iban.text)) {
        return 'Check the IBAN. A Swedish IBAN has 24 characters and starts with SE.';
      }
      if (!BankAccountRules.validBic(_bic.text)) {
        return 'BIC / SWIFT has 8 or 11 letters and digits.';
      }
      return null;
    }
    if (_bank == null) {
      return 'Check the clearing number: 4 digits, or 5 starting with 8 for Swedbank.';
    }
    if (!BankAccountRules.validAccount(_account.text)) {
      return 'The account number has 6 to 10 digits.';
    }
    return null;
  }

  void _save() {
    setState(() => _tried = true);
    final problem = _problem;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(problem ?? 'Preview only — account not saved.'),
    ));
  }

  Widget _tabs() => Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F3F3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            for (final (label, intl) in [('Sweden', false), ('International', true)])
              Expanded(
                child: GestureDetector(
                  key: ValueKey<String>('bank-tab-$label'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() {
                    _international = intl;
                    _tried = false;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    constraints: const BoxConstraints(minHeight: 36),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _international == intl
                          ? Colors.white
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: _international == intl
                            ? _line
                            : Colors.transparent,
                      ),
                    ),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _international == intl ? _ink : _muted,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );

  Widget _row(
    String label, {
    TextEditingController? controller,
    String? value,
    String hint = '',
    bool ok = false,
    bool last = false,
    TextInputType? keyboard,
    TextCapitalization caps = TextCapitalization.none,
    int maxLines = 1,
  }) {
    const valueStyle = TextStyle(
      color: _ink,
      fontSize: 15.5,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    );
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: last ? null : const Border(bottom: BorderSide(color: _line)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(label, style: const TextStyle(color: _muted, fontSize: 15)),
          ),
          Expanded(
            child: controller == null
                ? Text(
                    value ?? '—',
                    key: ValueKey<String>('bank-row-$label'),
                    textAlign: TextAlign.right,
                    style: value == null
                        ? valueStyle.copyWith(color: const Color(0xFFB4BBB8))
                        : valueStyle,
                  )
                : TextField(
                    key: ValueKey<String>('bank-field-$label'),
                    controller: controller,
                    textAlign: TextAlign.right,
                    keyboardType: keyboard,
                    textCapitalization: caps,
                    minLines: 1,
                    maxLines: maxLines,
                    autocorrect: false,
                    style: valueStyle,
                    cursorColor: _ink,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: hint,
                      hintStyle: valueStyle.copyWith(
                        color: const Color(0xFFB4BBB8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: ok
                ? const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.check_rounded, color: _green, size: 18),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bank = _bank;
    final problem = _tried ? _problem : null;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded, color: _ink, size: 24),
        ),
        centerTitle: true,
        title: const Text(
          'Bank account',
          style: TextStyle(color: _ink, fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
        children: [
          _tabs(),
          const SizedBox(height: 26),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'ACCOUNT',
              style: TextStyle(
                color: _muted,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: _line),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _row('Holder',
                    controller: _holder,
                    hint: 'Full name',
                    caps: TextCapitalization.words),
                _row('Bank', value: bank),
                if (!_international) ...[
                  _row('Clearing',
                      controller: _clearing,
                      hint: '8327-9',
                      ok: bank != null,
                      keyboard: TextInputType.number),
                  _row('Account',
                      controller: _account,
                      hint: '123 456 789-0',
                      ok: BankAccountRules.validAccount(_account.text),
                      keyboard: TextInputType.number,
                      last: true),
                ] else ...[
                  _row('IBAN',
                      controller: _iban,
                      hint: 'SE45 5000 0000 …',
                      ok: BankAccountRules.validIban(_iban.text),
                      caps: TextCapitalization.characters,
                      // 24+ characters: wraps rather than scrolling out of sight.
                      maxLines: 2),
                  _row('BIC',
                      controller: _bic,
                      hint: 'ESSESESS',
                      ok: BankAccountRules.validBic(_bic.text),
                      caps: TextCapitalization.characters,
                      last: true),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
            child: Text(
              problem ??
                  (_international
                      ? 'IBAN as on your bank statement. The bank is found from it.'
                      : 'The bank is found from the clearing number.'),
              key: const ValueKey<String>('bank-note'),
              style: TextStyle(
                color: problem == null ? _muted : _red,
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 52,
            child: FilledButton(
              key: const ValueKey<String>('bank-save'),
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: _ink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
              child: const Text(
                'Save account',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline_rounded, size: 14, color: _muted),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Demo: account not saved or sent to a bank',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _muted, fontSize: 12.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
