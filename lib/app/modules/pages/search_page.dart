import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/components/main_card.dart';
import 'package:grand_public_v2/app/data/models/video.dart';
import 'package:grand_public_v2/app/modules/home/controllers/home_controller.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

class SerachPage extends StatefulWidget {
  const SerachPage({super.key});

  @override
  State<SerachPage> createState() => _SerachPageState();
}

class _SerachPageState extends State<SerachPage> {
  bool isSearching = false;

  final TextEditingController inputcontroller = TextEditingController();
  List<Video> _listResult = [];
  final controller = Get.put(HomeController());

  void searchVid() {
    controller
        .searchVideo(inputcontroller.text)
        .then((value) => {_listResult = value});
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 20),
        Text(
          !isSearching ? 'RECHERCHER' : 'RÉSULTATS',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: GPTheme.primaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            controller: inputcontroller,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              prefixIconColor: Colors.white,
              suffixIconColor: Colors.white,
              hintText: 'Rechercher...',
              hintStyle: const TextStyle(color: Colors.white),
              fillColor: GPTheme.primaryColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              prefixIcon: isSearching
                  ? const Icon(Icons.search, color: Colors.white)
                  : null,
              suffixIcon: isSearching
                  ? IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      color: Colors.white,
                      onPressed: () {
                        setState(() {
                          isSearching = false;
                        });
                      },
                    )
                  : const Icon(Icons.search, color: Colors.white),
            ),
            style: const TextStyle(color: Colors.white),
            onChanged: (value) {
              setState(() {
                isSearching = value.isNotEmpty;
              });

              Future.delayed(
                const Duration(milliseconds: 300),
                () => {searchVid()},
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        Divider(color: GPTheme.primaryColor, thickness: 2),
        const SizedBox(height: 20),
        SizedBox(
          height: MediaQuery.of(context).size.height - 200,
          child: ListView.builder(
            itemCount: _listResult.length,
            itemBuilder: (context, index) {
              return BaseVCard(element: _listResult[index]);
            },
          ),
        ),
      ],
    );
  }
}
