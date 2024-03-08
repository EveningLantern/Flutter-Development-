// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:moneytracker/bar%20graph/bar_graph.dart';
import 'package:moneytracker/components/my_list_tile.dart';
import 'package:moneytracker/database/expense_database.dart';
import 'package:moneytracker/models/expense.dart';
import 'package:moneytracker/helper/helper_functions.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //text controllers
  TextEditingController nameController = TextEditingController();
  TextEditingController amountController = TextEditingController();

  // futures to load graph data
  Future<Map<int, double>>? _monthlyTotalsFuture;

  @override
  void initState() {
    // read database on the initail startup
    Provider.of<ExpenseDatabase>(context, listen: false).readExpenses();

    // load futures
    refreshGraphData();

    super.initState();
  }

  // refresh graph data
  void refreshGraphData() {
    _monthlyTotalsFuture = Provider.of<ExpenseDatabase>(context, listen: false)
        .calculateMonthlyTotals();
  }

  //open new expense box
  void openNewExpenseBox() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('New Expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // user input -> expense name
            TextField(
              controller: nameController,
              decoration: InputDecoration(hintText: "Expense Name"),
            ),
            // user input -> expense amount
            TextField(
              controller: amountController,
              decoration: InputDecoration(hintText: "Amount"),
            ),
          ],
        ),
        actions: [
          // cancel button
          _cancelButton(),
          //save button
          _createNewExpenseButton()
        ],
      ),
    );
  }

  //open edit box
  void openEditBox(Expense expense) {
    // pre-fill the existing values into textfileds
    String existingName = expense.name;
    String existingAmount = expense.amount.toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // user input -> expense name
            TextField(
              controller: nameController,
              decoration: InputDecoration(hintText: existingName),
            ),
            // user input -> expense amount
            TextField(
              controller: amountController,
              decoration: InputDecoration(hintText: existingAmount),
            ),
          ],
        ),
        actions: [
          // cancel button
          _cancelButton(),
          //save button
          _editExpenseButton(expense),
        ],
      ),
    );
  }

  //open delete box
  void openDeleteBox(Expense expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        actions: [
          // cancel button
          _cancelButton(),
          // delete button
          _deleteExpenseButton(expense.id),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseDatabase>(
      builder: (context, value, child) {
        // get dates
        int startMonth = value.getStartMonth();
        int startYear = value.getStartYear();
        int currentMonth = DateTime.now().month;
        int currentYear = DateTime.now().year;

        //calculate the number of months since the first month
        int monthCount = calculateMonthCount(
            startYear, startMonth, currentYear, currentMonth);

        // only display the expenses for the current month

        // return UI
        return Scaffold(
            floatingActionButton: FloatingActionButton(
              onPressed: openNewExpenseBox,
              child: Icon(Icons.add),
            ),
            body: SafeArea(
                child: Column(
              children: [
                // GRAPH UI

                SizedBox(
                  height: 250,
                  child: FutureBuilder(
                    future: _monthlyTotalsFuture,
                    builder: (context, snapshot) {
                      // data is loaded
                      if (snapshot.connectionState == ConnectionState.done) {
                        final monthlyTotals = snapshot.data ?? {};

                        // create the list of monthly summary
                        List<double> monthlySummary = List.generate(
                            monthCount,
                            (index) =>
                                monthlyTotals[startMonth + index] ?? 0.0);

                        return MyBarGraph(
                            monthlySummary: monthlySummary,
                            startMonth: startMonth);
                      }

                      // loding ...
                      else {
                        return const Center(
                          child: Text("Loading..."),
                        );
                      }
                    },
                  ),
                ),

                // EXPENSE LIST UI
                Expanded(
                  child: ListView.builder(
                    itemCount: value.allExpenses.length,
                    itemBuilder: (context, index) {
                      //get individual expenses
                      Expense individualExpense = value.allExpenses[index];
                      // return list tile UI
                      return MyListTile(
                        title: individualExpense.name,
                        trailing: formatAsRupees(individualExpense.amount),
                        onEditPressed: (context) =>
                            openEditBox(individualExpense),
                        onDeletePressed: (context) =>
                            openDeleteBox(individualExpense),
                      );
                    },
                  ),
                )
              ],
            )));
      },
    );
  }

  // CANCEL BUTTON
  Widget _cancelButton() {
    return MaterialButton(
      onPressed: () {
        // pop box
        Navigator.pop(context);

        // clear controllers
        nameController.clear();
        amountController.clear();
      },
      child: const Text('Cancel'),
    );
  }

  // SAVE BUTTON -> Create new expense
  Widget _createNewExpenseButton() {
    return MaterialButton(
      onPressed: () async {
        //only save if there is something in the textfield to save
        if (nameController.text.isNotEmpty &&
            amountController.text.isNotEmpty) {
          // pop box
          Navigator.pop(context);
          // create new expense
          Expense newExpense = Expense(
            name: nameController.text,
            amount: convertStringToDouble(amountController.text),
            date: DateTime.now(),
          ); //Expense
          // save to db
          await context.read<ExpenseDatabase>().createNewExpense(newExpense);

          // refresh graph
          refreshGraphData();

          // clear controllers
          nameController.clear();
          amountController.clear();
        }
      },
      child: const Text('Save'),
    );
  }

  // SAVE BUTTON -> Edit existing expense
  Widget _editExpenseButton(Expense expense) {
    return MaterialButton(
        onPressed: () async {
          // save as long as at leaset one text field has been changed
          if (nameController.text.isNotEmpty ||
              amountController.text.isNotEmpty) {
            // pop box
            Navigator.pop(context);

            //  create a new updated expense
            Expense updatedExpense = Expense(
              name: nameController.text.isNotEmpty
                  ? nameController.text
                  : expense.name,
              amount: amountController.text.isNotEmpty
                  ? convertStringToDouble(amountController.text)
                  : expense.amount,
              date: DateTime.now(),
            );
            // old expense id
            int existingId = expense.id;

            // save to db
            await context
                .read<ExpenseDatabase>()
                .updateExpense(existingId, updatedExpense);
            // refresh graph
            refreshGraphData();
          }
        },
        child: const Text("Save"));
  }

  // DELETE BUTTON
  Widget _deleteExpenseButton(int id) {
    return MaterialButton(
      onPressed: () async {
        // pop box
        Navigator.pop(context);
        // delete from db
        await context.read<ExpenseDatabase>().deleteExpense(id);
        // refresh graph
        refreshGraphData();
      },
      child: const Text("Delete"),
    );
  }
}
