import 'dart:math';
import '../models/group.dart';

class GroupService {
  // Calculate settlements for a group
  Map<String, List<Map<String, dynamic>>> calculateSettlements(Group group) {
    final settlements = <String, List<Map<String, dynamic>>>{};
    final members = group.members;
    
    // Calculate total amount and average share
    final totalAmount = group.totalAmount;
    final averageShare = totalAmount / members.length;
    
    // Calculate who owes and who should receive
    final balances = <String, double>{};
    for (final member in members) {
      balances[member.name] = member.totalPaid - averageShare;
    }
    
    // Sort members by balance (descending)
    final sortedMembers = members.toList()
      ..sort((a, b) => balances[b.name]!.compareTo(balances[a.name]!));
    
    // Calculate settlements
    var i = 0;
    var j = sortedMembers.length - 1;
    
    while (i < j) {
      final giver = sortedMembers[i];
      final receiver = sortedMembers[j];
      final giverBalance = balances[giver.name]!;
      final receiverBalance = balances[receiver.name]!;
      
      if (giverBalance > 0 && receiverBalance < 0) {
        final amount = min(giverBalance.abs(), receiverBalance.abs());
        
        // Add to settlements
        if (!settlements.containsKey(giver.name)) {
          settlements[giver.name] = [];
        }
        settlements[giver.name]!.add({
          'to': receiver.name,
          'amount': amount,
        });
        
        // Update balances
        balances[giver.name] = giverBalance - amount;
        balances[receiver.name] = receiverBalance + amount;
        
        if (balances[giver.name] == 0) i++;
        if (balances[receiver.name] == 0) j--;
      } else {
        break;
      }
    }
    
    return settlements;
  }

  // Add an expense and update member totals
  void addExpense(Group group, GroupExpense expense) {
    // Update member who paid
    for (var member in group.members) {
      if (member.name == expense.paidByName) {
        member.totalPaid += expense.amount;
      }
      if (expense.sharedByNames.contains(member.name)) {
        member.totalShare += expense.individualShares[member.name] ?? 0;
      }
    }
  }

  // Calculate equal shares for an expense
  Map<String, double> calculateEqualShares(double amount, List<String> sharedByNames) {
    final share = amount / sharedByNames.length;
    return Map.fromEntries(
      sharedByNames.map((name) => MapEntry(name, share))
    );
  }
} 