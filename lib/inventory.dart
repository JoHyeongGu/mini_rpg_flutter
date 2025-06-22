import 'package:flutter/material.dart';
import 'package:mini_rpg_flutter/api_service.dart';

class Inventory extends StatefulWidget {
  final Map<String, dynamic> data;
  const Inventory(this.data, {super.key});

  @override
  State<Inventory> createState() => _InventoryState();
}

class _InventoryState extends State<Inventory> {
  late ScrollController controller;
  List<dynamic>? shopData;
  List<dynamic>? inventoryData;
  String page = "inventory";
  TextStyle textStyle = TextStyle(
    fontFamily: "pixel",
    fontSize: 30,
    color: Colors.white,
  );

  void loadData() async {
    shopData = await getShopData(context);
    inventoryData = await getInventoryData(
      context,
      widget.data["character"]["char_id"],
    );
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    controller = ScrollController();
    loadData();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    TextStyle untitleStyle = textStyle.copyWith(
      color: Colors.white.withAlpha(150),
      fontSize: 20,
    );
    return Container(
      margin: EdgeInsets.symmetric(
        vertical: MediaQuery.of(context).size.height / 10,
        horizontal: MediaQuery.of(context).size.width / 4,
      ),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Color(0xffb39162),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            Column(
              children: [
                Row(
                  spacing: 15,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    MouseRegion(
                      child: GestureDetector(
                        onTap:
                            () => setState(() {
                              page = "inventory";
                            }),
                        child: Text(
                          "Inventory",
                          style: page == "inventory" ? textStyle : untitleStyle,
                        ),
                      ),
                    ),
                    MouseRegion(
                      child: GestureDetector(
                        onTap:
                            () => setState(() {
                              page = "shop";
                            }),
                        child: Text(
                          "Shop",
                          style: page == "shop" ? textStyle : untitleStyle,
                        ),
                      ),
                    ),
                  ],
                ),
                if (shopData != null)
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.all(30),
                      child: SingleChildScrollView(
                        child: Column(
                          spacing: 10,
                          children:
                              page == "inventory"
                                  ? inventoryData!
                                      .map((item) => itemCard(item))
                                      .toList()
                                  : shopData!
                                      .map((item) => itemCard(item))
                                      .toList(),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Row(
              spacing: 10,
              children: [
                Image.asset("assets/images/coin.png", width: 30),
                Text(
                  widget.data["character"]["coin"].toString(),
                  style: textStyle.copyWith(fontSize: 20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget itemCard(Map data) {
    bool canBuy =
        data.keys.contains("price") &&
        widget.data["character"]["coin"] >= data["price"];
    return Container(
      width: double.infinity,
      height: 110,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(100),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          spacing: 15,
          children: [
            Image.asset("assets/images/item_no_img.png"),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "[${data["type"]}] ${data["name"]}",
                  style: textStyle.copyWith(
                    color: Colors.black.withAlpha(170),
                    fontSize: 20,
                  ),
                ),
                Text(
                  data["description"],
                  style: textStyle.copyWith(
                    color: Colors.black.withAlpha(170),
                    fontSize: 16,
                  ),
                ),
                Spacer(),
                data.keys.contains("price")
                    ? Row(
                      spacing: 5,
                      children: [
                        Text(
                          "${data["price"]}",
                          style: textStyle.copyWith(
                            color: Colors.black.withAlpha(170),
                            fontSize: 16,
                          ),
                        ),
                        Image.asset("assets/images/coin.png", width: 10),
                      ],
                    )
                    : Text(
                      "Count: ${data["count"]}",
                      style: textStyle.copyWith(
                        color: Colors.black.withAlpha(170),
                        fontSize: 16,
                      ),
                    ),
              ],
            ),
            Spacer(),
            if (page == "shop")
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: canBuy ? Color(0xff8f643c) : Colors.grey[500],
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap:
                            canBuy
                                ? () async {
                                  if (await buyItem(
                                    context,
                                    widget.data["character"]["char_id"],
                                    data["item_id"],
                                    1,
                                  )) {
                                    widget.data["character"]["coin"] -=
                                        data["price"];
                                    loadData();
                                  }
                                }
                                : null,
                        borderRadius: BorderRadius.circular(5),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 30,
                            horizontal: 10,
                          ),
                          child: Text(
                            "Buy",
                            style: TextStyle(
                              color: Colors.white.withAlpha(150),
                              fontFamily: "pixel",
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
