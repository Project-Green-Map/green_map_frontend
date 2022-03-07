import 'package:flutter/material.dart';

class Help extends StatefulWidget {
  const Help({Key? key}) : super(key: key);

  @override
  State<Help> createState() => _HelpState();
}

class Item {
  String headerText;
  String bodyText;
  bool isExpanded;

  Item({required this.headerText, required this.bodyText, this.isExpanded = false});
}

class _HelpState extends State<Help> {
  final List<Item> _items = [
    Item(
      headerText: "What is this app?",
      bodyText: "This is a maps app with a focus on the carbon emissions you generate. "
          "Any time you enter a route, it will show you the emissions and "
          "time taken to travel it.",
    ),
    Item(
      headerText: "What is \"emissions saved\"?",
      bodyText: "The emissions saved is the difference in emissions between you and "
          "the average person travelling the same distance as you. Try to "
          "beat the average by as much as you can!",
    ),
    Item(
      headerText: "What is KG CO₂e?",
      bodyText: "KG CO₂e stands for kilograms (of) carbon dioxide equivalent. There "
          "are several different kinds of greenhouse gas, some of which are worse "
          "for the environment than others. To visualise how much impact we're "
          "having more easily, we use the equivalent amount of carbon dioxide that "
          "would be emitted to have the same environmental impact as all the different "
          "greenhouse gases combined.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Help")),
      body: SingleChildScrollView(
        child: Container(
          child: _buildPanels(),
          //padding: const EdgeInsets.symmetric(horizontal: 5.0),
        ),
      ),
    );
  }

  Widget _buildPanels() {
    return ExpansionPanelList(
      expansionCallback: ((panelIndex, isExpanded) {
        setState(() {
          _items[panelIndex].isExpanded = !isExpanded;
        });
      }),
      expandedHeaderPadding: EdgeInsets.zero,
      children: _items
          .map((Item i) => ExpansionPanel(
                headerBuilder: ((context, isExpanded) => ListTile(
                      title: Text(
                        i.headerText,
                        style: const TextStyle(
                            fontSize: 24, fontFamily: "Quicksand", color: Colors.lightBlue),
                        textAlign: TextAlign.center,
                      ),
                      dense: true,
                      contentPadding: const EdgeInsets.all(15.0),
                    )),
                body: Padding(
                  padding: const EdgeInsets.only(left: 15.0, right: 15.0, bottom: 15.0),
                  child: Text(
                    i.bodyText,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                isExpanded: i.isExpanded,
                canTapOnHeader: true,
              ))
          .toList(),
    );
  }
}
