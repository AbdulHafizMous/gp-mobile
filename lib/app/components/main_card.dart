import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/data/models/video.dart';
import 'package:grand_public_v2/app/data/utils/utils.dart';
import 'package:grand_public_v2/app/modules/home/controllers/home_controller_old.dart';
import 'package:grand_public_v2/app/routes/app_pages.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

class BaseVCard extends StatefulWidget {
  const BaseVCard({super.key, required this.element});

  final Video element;
  @override
  State<BaseVCard> createState() => _BaseVCardState();
}

class _BaseVCardState extends State<BaseVCard> {
  String limitTextTo(int limit) {
    if (widget.element.description != null &&
        widget.element.description!.length > limit) {
      return '${widget.element.description!.substring(0, limit)}...';
    }

    return widget.element.description ?? 'Aucune description';
  }

  final controller = Get.put(HomeController());

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        controller.currentVidId.value = widget.element.youtubeId;
        controller.currentId.value = widget.element.id;
        Get.toNamed('${Routes.VIDEOS}/${widget.element.id}');
      },
      child: SizedBox(
        width: 340,
        child: Card(
          elevation: 10,
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 150,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: Image(
                      image: NetworkImage(widget.element.videoThumbnail),
                    ).image,
                    fit: BoxFit.cover,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Center(
                  child: IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.play_arrow, color: GPTheme.primaryColor),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 5,
                  horizontal: 10,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        limitTextTo(40),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${widget.element.views.toString()} vues",
                            style: TextStyle(color: GPTheme.primaryColor),
                          ),
                          Text(
                            convertToDate(
                              DateTime.parse(widget.element.publicationDate),
                            ),
                            style: TextStyle(color: GPTheme.primaryColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
