import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:moneytracker/models/expense.dart';
import 'package:path_provider/path_provider.dart';

class ExpenseDatabase extends ChangeNotifier {
  static late Isar isar;
  List<Expense> _allExpenses = [];
  /*

  SETUP

  */
  //initialize database
  static Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open([ExpenseSchema], directory: dir.path);
  }

  /*

  GETTERS

  */
  List<Expense> get allExpenses => _allExpenses;
  /*

  OPERATIONS

  */
  // Create - a new expense
  Future<void> createNewExpense(Expense newExpense) async {
    //add to the db
    await isar.writeTxn(() => isar.expenses.put(newExpense));

    // re-read from the db
    await readExpenses();
  }

  // Read - expenses from the db
  Future<void> readExpenses() async {
    // fetch all existing expenses from db
    List<Expense> fetchedExpenses = await isar.expenses.where().findAll();

    // give to local expenses list
    _allExpenses.clear();
    _allExpenses.addAll(fetchedExpenses);
    // update  UI
    notifyListeners();
  }

  // Update - edte an expense
  Future<void> updateExpense(int id, Expense updatedExpense) async {
    //make sure new expense has same id as excited one
    updatedExpense.id = id;

    //update in db
    await isar.writeTxn(() => isar.expenses.put(updatedExpense));

    //re-read from the db
    await readExpenses();
  }

  // Delete - an expense
  Future<void> deleteExpense(int id) async {
    // delete from db
    await isar.writeTxn(() => isar.expenses.delete(id));

    // re-read from the db
    await readExpenses();
  }

  /*

  HELPER

  */

  // calculte total expenses for each month
  Future<Map<int, double>> calculateMonthlyTotals() async {
    // ensure the expenses are read form the database
    await readExpenses();

    // create a map to keep track of total expenses per month
    Map<int, double> monthlyTotals = {
      // 0 : 250 January
      // 1 : 250 February
    };

    // iterate over all the expenses
    for (var expense in _allExpenses) {
      // extratch the month from the date of the expense
      int month = expense.date.month;

      // if the month is not yet in the map, initialize to 0
      if (monthlyTotals.containsKey(month)) {
        monthlyTotals[month] = 0;
      }

      // add the expense amount to the total for the month
      monthlyTotals[month] = monthlyTotals[month]! + expense.amount;
    }

    return monthlyTotals;
  }

  // get start monthing
  int getStartMonth() {
    if (_allExpenses.isEmpty) {
      return DateTime.now()
          .month; // default to current month is no expenses are recorded.
    }
    // sort expenses by date to find the earlist
    _allExpenses.sort(
      (a, b) => a.date.compareTo(b.date),
    );
    return _allExpenses.first.date.month;
  }

  // get start year
  int getStartYear() {
    if (_allExpenses.isEmpty) {
      return DateTime.now()
          .year; // default to current year is no expenses are recorded.
    }
    // sort expenses by date to find the earlist
    _allExpenses.sort(
      (a, b) => a.date.compareTo(b.date),
    );
    return _allExpenses.first.date.year;
  }
}
