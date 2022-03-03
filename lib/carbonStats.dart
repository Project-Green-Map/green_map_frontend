import 'package:flutter/animation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:map/help.dart';

class CarbonStats extends StatefulWidget {
  const CarbonStats({Key? key}) : super(key: key);

  @override
  State<CarbonStats> createState() => _CarbonStatsState();
}

/*
                                          !!!!!
      NOTE: This only uses a fixed value of 12.2 (see line 30) for the carbon saved value.
      I will add the actual tracker once we have merged the carbon calculator into the app.
                                          !!!!!
*/

class _CarbonStatsState extends State<CarbonStats> {
  final int scrollVelocity = 10;
  int _timesScrolled = 1;
  int _count = 8;
  ScrollController _controller = ScrollController(initialScrollOffset: 0.0);
  late double width;
  late double carbonSaved;
  late List<ListTile> tiles;
  late List<dynamic> recommendations;

  _CarbonStatsState() {
    carbonSaved = 12.2; //TODO: actually implement

    recommendations = [
      [
        "Reduce car emissions",
        "You're spending a lot of time in your car. Have you looked into public transport or car pooling?",
        Icons.time_to_leave
      ],
      [
        "City-provided e-vehicles", //probably only show this one if bikes are disabled in settings
        "E-scooters{/bikes/etc} are available in your city. Have you tried using them?\n",
        Icons.electric_scooter //or Icons.electric_bike
      ],
      [
        "Bikes",
        "Bikes are a fantastic way to get around, and completely green to use! Have you ever considered getting one?",
        Icons.pedal_bike
      ]
    ];

    tiles = [
      //1KG CARBON EQUIVALENTS: 5000 searches, 1 YEAR OF LIGHTBULB,
      //https://css.umich.edu/factsheets/carbon-footprint-factsheet
      [(5000 * carbonSaved).toStringAsFixed(0), "Web searches\n", Icons.search],
      [(365 * carbonSaved).toStringAsFixed(0), "Days using an LED lightbulb", Icons.lightbulb],
      [(0.17 * carbonSaved).toStringAsFixed(2), "4oz burgers", Icons.fastfood],
      [(0.05 * carbonSaved).toStringAsFixed(2), "Flights from LHR to JFK", Icons.flight_takeoff]
      //TODO: add more (the leftmost value is the emissions per kilogram)
    ]
        .map(((List<dynamic> e) => ListTile(
              title: Text(
                e[0] as String,
                style:
                    const TextStyle(color: Colors.lightBlue, fontSize: 24, fontFamily: 'Quicksand'),
                textAlign: TextAlign.center,
              ),
              subtitle: Text(
                e[1] as String,
                textAlign: TextAlign.center,
              ),
              leading: Icon(e[2] as IconData, size: 28),
              minLeadingWidth: 20,
              contentPadding: const EdgeInsets.all(8.0),
            )))
        .toList();

    _controller.addListener(() {
      var isEnd = _controller.offset + 20 > _controller.position.maxScrollExtent;
      if (isEnd) {
        setState(() {
          _timesScrolled = _controller.offset ~/ (width / 2.6);
          _count = tiles.length * (_timesScrolled.abs() + 1);
        });
      }
    });

    WidgetsBinding.instance?.addPostFrameCallback((timeStamp) {
      _controller.position.isScrollingNotifier.addListener(() {
        if (!_controller.position.isScrollingNotifier.value) {
          scroll();
        }
      });
      scroll();
    });
  }

  void scroll() {
    _controller.animateTo(_controller.position.maxScrollExtent,
        duration: Duration(
            seconds: 1 +
                ((_controller.position.maxScrollExtent - _controller.offset) /
                        (3 * scrollVelocity)) ~/
                    1),
        curve: Curves.linear);
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    this.width = width;

    return Scaffold(
      /*appBar: AppBar(
        title: const Text('Carbon Tracker'),
      ),*/
      backgroundColor: const Color.fromARGB(255, 253, 250, 234),
      body: Center(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                height: height / 1.7,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                      image: AssetImage("lib/assets/images/leaf.png"),
                      fit: BoxFit.scaleDown,
                      opacity: 0.1),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: height,
                width: width,
                child: ListView(
                  children: [
                    const SizedBox(height: 100),
                    const Align(
                      child: Text(
                        "You've saved...",
                        style: TextStyle(fontSize: 32, fontFamily: 'Quicksand'),
                      ),
                    ),
                    const Align(
                      child: Text(
                        "12.2",
                        style: TextStyle(
                            fontSize: 96, color: Colors.lightGreen, fontFamily: 'Quicksand'),
                      ),
                    ),
                    Align(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            "kilograms CO₂e!",
                            style: TextStyle(
                                fontSize: 32,
                                color: Colors.lightGreen,
                                fontFamily: 'Quicksand',
                                height: 0.6),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 60),
                    const Align(
                      child: Text(
                        "That's equivalent to ...",
                        style: TextStyle(fontSize: 20, fontFamily: 'Quicksand'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: height / 7,
                      width: width,
                      child: ListView.builder(
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        controller: _controller,
                        physics: const NeverScrollableScrollPhysics(),
                        //there's a flutter bug (https://github.com/flutter/flutter/issues/14452) that has still not been fixed
                        //that crashes flutter when you try to interrupt a scroll animation. while both would look so good, i've
                        //opted to disable user input in favour of auto-scroll. let me know if you want to see the other way around :)
                        itemCount: _count,
                        itemBuilder: ((context, index) {
                          return Card(
                            shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(15.0))),
                            elevation: 3,
                            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                            child: SizedBox(
                              height: height, //inherit height of entire row of cards
                              width: width / 2.6, //quarter the width of the entire row per card
                              child: tiles[index % tiles.length],
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 100),
                    const Align(
                      child: Text(
                        "Want to save more?",
                        style: TextStyle(
                            fontSize: 24, color: Colors.lightGreen, fontFamily: 'Quicksand'),
                      ),
                    ),
                    const Align(
                      child: Text(
                        "Here are some recommendations...",
                        style: TextStyle(fontSize: 18, fontFamily: 'Quicksand'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Align(
                      child: SizedBox(
                        height: height / 1.7,
                        //TODO: calculate the exact height based on how many cards are shown
                        width: width / 1.2,
                        child: ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: recommendations.length,
                          itemBuilder: ((context, index) {
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.all(5.0),
                              child: SizedBox(
                                height: height / 8,
                                child: ListTile(
                                    title: Text(
                                      recommendations[index][0] as String,
                                      textAlign: TextAlign.center,
                                    ),
                                    subtitle: Text(
                                      recommendations[index][1] as String,
                                      textAlign: TextAlign.center,
                                    ),
                                    leading: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Icon(recommendations[index][2] as IconData,
                                            color: Colors.lightGreen),
                                      ],
                                    )),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Column(
              children: [
                const SizedBox(height: 280),
                Row(
                  children: [
                    const SizedBox(width: 310),
                    TextButton(
                      child: const Text(
                        "(?)",
                        style: TextStyle(
                            fontSize: 18.0,
                            color: Colors.transparent,
                            shadows: [
                              Shadow(
                                color: Colors.black38,
                                offset: Offset(0, -5),
                              )
                            ],
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.black38),
                        textAlign: TextAlign.center,
                      ),
                      //style: ButtonStyle(
                      //backgroundColor: MaterialStateProperty.all(Colors.black12),
                      //shape: MaterialStateProperty.all(const CircleBorder())),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const Help()),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            Align(
              //needs to be on top of everything, so last entry in the stack list
              alignment: Alignment.topLeft,
              child: BackButton(
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
