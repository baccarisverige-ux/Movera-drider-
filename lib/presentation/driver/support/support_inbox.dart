import 'package:flutter/material.dart';

class SupportInboxScreen extends StatefulWidget {
  const SupportInboxScreen({super.key});
  @override
  State<SupportInboxScreen> createState() => _SupportInboxScreenState();
}

class _SupportInboxScreenState extends State<SupportInboxScreen> {
  final List<_Ticket> tickets = [
    _Ticket('Scheduled ride question', 'Support confirmed your reservation.', 'OPEN', true),
    _Ticket('Wallet payout review', 'Your payout was reviewed and released.', 'RESOLVED', false),
  ];

  Future<void> _newTicket() async {
    final subject = TextEditingController();
    final message = TextEditingController();
    String category = 'Trip & rider';
    final created = await showModalBottomSheet<_Ticket>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
            decoration: const BoxDecoration(
              color: Color(0xFFF8F9FA),
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: SafeArea(
              top: false,
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFD2D8DC), borderRadius: BorderRadius.circular(8)))),
                const SizedBox(height: 20),
                const Text('New support ticket', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF20282E))),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: _decoration('Category'),
                  items: ['Trip & rider', 'Wallet & payments', 'Scheduled rides', 'Account & documents', 'Technical issue', 'Something else']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) { if (v != null) setSheetState(() => category = v); },
                ),
                const SizedBox(height: 12),
                TextField(controller: subject, decoration: _decoration('Subject')),
                const SizedBox(height: 12),
                TextField(controller: message, minLines: 4, maxLines: 6, decoration: _decoration('Tell us what happened')),
                const SizedBox(height: 18),
                SizedBox(width: double.infinity, height: 54, child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF202A30), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                  onPressed: () {
                    if (subject.text.trim().isEmpty || message.text.trim().isEmpty) return;
                    Navigator.pop(sheetContext, _Ticket(subject.text.trim(), message.text.trim(), 'OPEN', false));
                  },
                  child: const Text('Create ticket', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                )),
              ]),
            ),
          ),
        ),
      ),
    );
    subject.dispose();
    message.dispose();
    if (created != null && mounted) setState(() => tickets.insert(0, created));
  }

  InputDecoration _decoration(String label) => InputDecoration(
    labelText: label, filled: true, fillColor: Colors.white,
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE1E5E7))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF2FBE7B), width: 1.4)),
  );

  void _open(_Ticket ticket) {
    setState(() => ticket.unread = false);
    Navigator.push(context, MaterialPageRoute(builder: (_) => _Conversation(ticket: ticket)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF2F4F5),
    appBar: AppBar(
      backgroundColor: const Color(0xFFF2F4F5), surfaceTintColor: Colors.transparent,
      title: const Text('Support Inbox', style: TextStyle(fontWeight: FontWeight.w800)), centerTitle: true,
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _newTicket, backgroundColor: const Color(0xFF202A30), foregroundColor: Colors.white,
      icon: const Icon(Icons.add_rounded), label: const Text('New ticket', style: TextStyle(fontWeight: FontWeight.w700)),
    ),
    body: ListView(padding: const EdgeInsets.fromLTRB(16, 14, 16, 100), children: [
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: const Color(0xFF202A30), borderRadius: BorderRadius.circular(24)),
        child: const Row(children: [
          _SupportIcon(), SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Movera Support', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
            SizedBox(height: 3), Text('Usually replies within a few hours', style: TextStyle(color: Color(0xFFBFC8CD), fontSize: 12)),
          ])),
          CircleAvatar(radius: 5, backgroundColor: Color(0xFF2FBE7B)),
        ]),
      ),
      const SizedBox(height: 20),
      const Text('Your conversations', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF20282E))),
      const SizedBox(height: 12),
      ...tickets.map((t) => Padding(padding: const EdgeInsets.only(bottom: 10), child: _TicketCard(ticket: t, onTap: () => _open(t)))),
    ]),
  );
}

class _TicketCard extends StatelessWidget {
  final _Ticket ticket; final VoidCallback onTap;
  const _TicketCard({required this.ticket, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final open = ticket.status == 'OPEN';
    return Material(color: Colors.white, borderRadius: BorderRadius.circular(21), child: InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(21),
      child: Padding(padding: const EdgeInsets.all(16), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(height: 44, width: 44, decoration: BoxDecoration(color: open ? const Color(0xFFE7F6EF) : const Color(0xFFF0F2F3), borderRadius: BorderRadius.circular(14)), child: Icon(open ? Icons.support_agent_rounded : Icons.task_alt_rounded, color: open ? const Color(0xFF16895B) : const Color(0xFF758087))),
        const SizedBox(width: 13),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: Text(ticket.subject, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800))), if (ticket.unread) const CircleAvatar(radius: 4, backgroundColor: Color(0xFF2FBE7B))]),
          const SizedBox(height: 5), Text(ticket.preview, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF6F7B82), fontSize: 12, height: 1.35)),
          const SizedBox(height: 10), Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4), decoration: BoxDecoration(color: open ? const Color(0xFFE7F6EF) : const Color(0xFFF0F2F3), borderRadius: BorderRadius.circular(20)), child: Text(ticket.status, style: TextStyle(color: open ? const Color(0xFF16895B) : const Color(0xFF758087), fontSize: 9, fontWeight: FontWeight.w800))),
        ])),
        const Icon(Icons.chevron_right_rounded, color: Color(0xFFABB3B8)),
      ])),
    ));
  }
}

class _Conversation extends StatefulWidget {
  final _Ticket ticket; const _Conversation({required this.ticket});
  @override State<_Conversation> createState() => _ConversationState();
}

class _ConversationState extends State<_Conversation> {
  final input = TextEditingController();
  void send() { if (input.text.trim().isEmpty) return; setState(() { widget.ticket.messages.add(_Message(input.text.trim(), false)); widget.ticket.preview = input.text.trim(); }); input.clear(); }
  @override void dispose() { input.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF2F4F5),
    appBar: AppBar(backgroundColor: const Color(0xFFF2F4F5), surfaceTintColor: Colors.transparent, title: Text(widget.ticket.subject, style: const TextStyle(fontWeight: FontWeight.w800))),
    body: Column(children: [
      Expanded(child: ListView(padding: const EdgeInsets.all(16), children: widget.ticket.messages.map((m) => Align(
        alignment: m.support ? Alignment.centerLeft : Alignment.centerRight,
        child: Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14), constraints: const BoxConstraints(maxWidth: 300), decoration: BoxDecoration(color: m.support ? Colors.white : const Color(0xFF202A30), borderRadius: BorderRadius.circular(18)), child: Text(m.text, style: TextStyle(color: m.support ? const Color(0xFF283138) : Colors.white, height: 1.35))),
      )).toList())),
      Container(color: Colors.white, padding: EdgeInsets.fromLTRB(14, 10, 14, MediaQuery.paddingOf(context).bottom + 10), child: Row(children: [
        Expanded(child: TextField(controller: input, decoration: InputDecoration(hintText: 'Write a message', filled: true, fillColor: const Color(0xFFF2F4F5), border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none)))),
        const SizedBox(width: 9), IconButton.filled(onPressed: send, style: IconButton.styleFrom(backgroundColor: const Color(0xFF202A30)), icon: const Icon(Icons.arrow_upward_rounded)),
      ])),
    ]),
  );
}

class _SupportIcon extends StatelessWidget {
  const _SupportIcon();
  @override Widget build(BuildContext context) => Container(height: 46, width: 46, decoration: BoxDecoration(color: const Color(0xFF2FBE7B), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.support_agent_rounded, color: Colors.white));
}

class _Ticket {
  final String subject; String preview; final String status; bool unread; final List<_Message> messages;
  _Ticket(this.subject, this.preview, this.status, this.unread) : messages = [_Message(preview, true)];
}

class _Message { final String text; final bool support; _Message(this.text, this.support); }
