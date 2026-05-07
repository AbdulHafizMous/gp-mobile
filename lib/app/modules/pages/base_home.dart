import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/components/latest_slider.dart';
import 'package:grand_public_v2/app/data/models/video.dart';
import 'package:grand_public_v2/app/modules/home/controllers/home_controller_old.dart';
import 'package:grand_public_v2/app/routes/app_pages.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

class BaseHome extends StatefulWidget {
  const BaseHome({super.key});

  @override
  State<BaseHome> createState() => _BaseHomeState();
}

class _BaseHomeState extends State<BaseHome> {
  final Map mainBanner = {
    "image":
        "https://s3-alpha-sig.figma.com/img/5149/1439/3fab0facf9f29530e89ef7287ca5595e?Expires=1736121600&Key-Pair-Id=APKAQ4GOSFWCVNEHN3O4&Signature=af3c4pvvhL7UOEgTIF4MAb0UMv7cIaVLbuGH7CGBMJvdm23yzjKWNVa~MrE11oJsGRzPsz~YtetwOz2VclA6CJNhdcDm318z1-S16pZylrTBXccFxAzyTZCaEK1v6Up5N8TVkqX7VYQClkCS5qQcFFe7lSHQ8lv~6BqDoK1orzvy-rHfaAt-hzZ6xorPklrFEyyfBh-mc8hFo4a--6ohC5huI4FHPEEXXfHQfy0LvVrHz7GrnMSBonZ~t~vozO2MGNYhWw2rtH~RIw4Dg~wF-zpFD~C4tTARqs532uRdfe~I225dsV5qzGLigA9f9xyLzTXB8~wnJTRwYSAslB4AUw__",
  };

  final controller = Get.put(HomeController());
  final List element = [
    {
      "images":
          "https://s3-alpha-sig.figma.com/img/c551/461b/9fa2df1a46fdc4471cf166130d83ec37?Expires=1736121600&Key-Pair-Id=APKAQ4GOSFWCVNEHN3O4&Signature=CYby9ei7eocTqNn02l8LW6u8K9pHg4XCIjn6pOTF5SPammU7qK2nZMk3YXivt1X~h1NEe9K088RRCvZMHi37fzYm6gn329FX3M5UmPlNq2xVqnp4BdgciU4xm5rcwFWY7IFXvexO~7~K44GivbRqkTzXHzfxuaaXvF3pRODeDlB297FrcfRSRtBX~hS3hoFkHTtvtqm3CFf3VHvzSAoJ6iRofgsO~MvZHQtoiBXdxG5Mdii06KuuSVfo2yf~cGkaHr9NvPYGzYAI76gIXHoVkSGpsJ3KdSDjIuV~QoIgk0rEMDmrVX7AGit16O~A61NondtqkJpBkDFhn9vF37JJ3Q__",
      "description": "Description",
      "vues": 250,
      "since": "since 2021",
    },
    {
      "images":
          "https://s3-alpha-sig.figma.com/img/7f96/efb6/88db4a3c4a232d9728dc1f5bc7129d31?Expires=1736121600&Key-Pair-Id=APKAQ4GOSFWCVNEHN3O4&Signature=cem67tEUs3OuFBTLaD3YaTdZlHlim-fBF28XbSQ574Su85iCgySGnEIW2y8FZkPtfMx9-XxqqxNqISyJSt8DZhPi-f~cryZV7NTz746yKW5cEExub~6laP3wBn9obr9e6xxM-nUQcCRNzjjUr2veHRIGHQyq3kegnD~LF0sJS0WqOlBpqhgYM22-FGe5gP46gp85cnGVJOgHMBMJn7PvfYfTy~XBi9u584VxyGnqgEy9lp6p022ZBmZGMo~4xbp8BusXXASG2cyB8FSvsZN3HBwndXLO2sYAipKykSOoRjRFZCJiOcMQw4feWsN7vk9GH2a1egyts7lIQ2PvQmr1iA__",
      "description":
          "Michel D. a fondé sa marque éthique après 10 ans dans l’industrie de...",
      "vues": 250,
      "since": "since 2021",
    },
    {
      "images":
          "https://s3-alpha-sig.figma.com/img/c551/461b/9fa2df1a46fdc4471cf166130d83ec37?Expires=1736121600&Key-Pair-Id=APKAQ4GOSFWCVNEHN3O4&Signature=CYby9ei7eocTqNn02l8LW6u8K9pHg4XCIjn6pOTF5SPammU7qK2nZMk3YXivt1X~h1NEe9K088RRCvZMHi37fzYm6gn329FX3M5UmPlNq2xVqnp4BdgciU4xm5rcwFWY7IFXvexO~7~K44GivbRqkTzXHzfxuaaXvF3pRODeDlB297FrcfRSRtBX~hS3hoFkHTtvtqm3CFf3VHvzSAoJ6iRofgsO~MvZHQtoiBXdxG5Mdii06KuuSVfo2yf~cGkaHr9NvPYGzYAI76gIXHoVkSGpsJ3KdSDjIuV~QoIgk0rEMDmrVX7AGit16O~A61NondtqkJpBkDFhn9vF37JJ3Q__",
      "description":
          "Michel D. a fondé sa marque éthique après 10 ans dans l’industrie de...",
      "vues": 250,
      "since": "since 2021",
    },
    {
      "images":
          "https://s3-alpha-sig.figma.com/img/7f96/efb6/88db4a3c4a232d9728dc1f5bc7129d31?Expires=1736121600&Key-Pair-Id=APKAQ4GOSFWCVNEHN3O4&Signature=cem67tEUs3OuFBTLaD3YaTdZlHlim-fBF28XbSQ574Su85iCgySGnEIW2y8FZkPtfMx9-XxqqxNqISyJSt8DZhPi-f~cryZV7NTz746yKW5cEExub~6laP3wBn9obr9e6xxM-nUQcCRNzjjUr2veHRIGHQyq3kegnD~LF0sJS0WqOlBpqhgYM22-FGe5gP46gp85cnGVJOgHMBMJn7PvfYfTy~XBi9u584VxyGnqgEy9lp6p022ZBmZGMo~4xbp8BusXXASG2cyB8FSvsZN3HBwndXLO2sYAipKykSOoRjRFZCJiOcMQw4feWsN7vk9GH2a1egyts7lIQ2PvQmr1iA__",
      "description":
          "Michel D. a fondé sa marque éthique après 10 ans dans l’industrie de...",
      "vues": 250,
      "since": "since 2021",
    },
    {
      "images":
          "https://s3-alpha-sig.figma.com/img/c551/461b/9fa2df1a46fdc4471cf166130d83ec37?Expires=1736121600&Key-Pair-Id=APKAQ4GOSFWCVNEHN3O4&Signature=CYby9ei7eocTqNn02l8LW6u8K9pHg4XCIjn6pOTF5SPammU7qK2nZMk3YXivt1X~h1NEe9K088RRCvZMHi37fzYm6gn329FX3M5UmPlNq2xVqnp4BdgciU4xm5rcwFWY7IFXvexO~7~K44GivbRqkTzXHzfxuaaXvF3pRODeDlB297FrcfRSRtBX~hS3hoFkHTtvtqm3CFf3VHvzSAoJ6iRofgsO~MvZHQtoiBXdxG5Mdii06KuuSVfo2yf~cGkaHr9NvPYGzYAI76gIXHoVkSGpsJ3KdSDjIuV~QoIgk0rEMDmrVX7AGit16O~A61NondtqkJpBkDFhn9vF37JJ3Q__",
      "description":
          "Michel D. a fondé sa marque éthique après 10 ans dans l’industrie de...",
      "vues": 250,
      "since": "since 2021",
    },
    {
      "images":
          "https://s3-alpha-sig.figma.com/img/7f96/efb6/88db4a3c4a232d9728dc1f5bc7129d31?Expires=1736121600&Key-Pair-Id=APKAQ4GOSFWCVNEHN3O4&Signature=cem67tEUs3OuFBTLaD3YaTdZlHlim-fBF28XbSQ574Su85iCgySGnEIW2y8FZkPtfMx9-XxqqxNqISyJSt8DZhPi-f~cryZV7NTz746yKW5cEExub~6laP3wBn9obr9e6xxM-nUQcCRNzjjUr2veHRIGHQyq3kegnD~LF0sJS0WqOlBpqhgYM22-FGe5gP46gp85cnGVJOgHMBMJn7PvfYfTy~XBi9u584VxyGnqgEy9lp6p022ZBmZGMo~4xbp8BusXXASG2cyB8FSvsZN3HBwndXLO2sYAipKykSOoRjRFZCJiOcMQw4feWsN7vk9GH2a1egyts7lIQ2PvQmr1iA__",
      "description":
          "Michel D. a fondé sa marque éthique après 10 ans dans l’industrie de...",
      "vues": 250,
      "since": "since 2021",
    },
    {
      "images":
          "https://s3-alpha-sig.figma.com/img/c551/461b/9fa2df1a46fdc4471cf166130d83ec37?Expires=1736121600&Key-Pair-Id=APKAQ4GOSFWCVNEHN3O4&Signature=CYby9ei7eocTqNn02l8LW6u8K9pHg4XCIjn6pOTF5SPammU7qK2nZMk3YXivt1X~h1NEe9K088RRCvZMHi37fzYm6gn329FX3M5UmPlNq2xVqnp4BdgciU4xm5rcwFWY7IFXvexO~7~K44GivbRqkTzXHzfxuaaXvF3pRODeDlB297FrcfRSRtBX~hS3hoFkHTtvtqm3CFf3VHvzSAoJ6iRofgsO~MvZHQtoiBXdxG5Mdii06KuuSVfo2yf~cGkaHr9NvPYGzYAI76gIXHoVkSGpsJ3KdSDjIuV~QoIgk0rEMDmrVX7AGit16O~A61NondtqkJpBkDFhn9vF37JJ3Q__",
      "description":
          "Michel D. a fondé sa marque éthique après 10 ans dans l’industrie de...",
      "vues": 250,
      "since": "since 2021",
    },
    {
      "images":
          "https://s3-alpha-sig.figma.com/img/7f96/efb6/88db4a3c4a232d9728dc1f5bc7129d31?Expires=1736121600&Key-Pair-Id=APKAQ4GOSFWCVNEHN3O4&Signature=cem67tEUs3OuFBTLaD3YaTdZlHlim-fBF28XbSQ574Su85iCgySGnEIW2y8FZkPtfMx9-XxqqxNqISyJSt8DZhPi-f~cryZV7NTz746yKW5cEExub~6laP3wBn9obr9e6xxM-nUQcCRNzjjUr2veHRIGHQyq3kegnD~LF0sJS0WqOlBpqhgYM22-FGe5gP46gp85cnGVJOgHMBMJn7PvfYfTy~XBi9u584VxyGnqgEy9lp6p022ZBmZGMo~4xbp8BusXXASG2cyB8FSvsZN3HBwndXLO2sYAipKykSOoRjRFZCJiOcMQw4feWsN7vk9GH2a1egyts7lIQ2PvQmr1iA__",
      "description":
          "Michel D. a fondé sa marque éthique après 10 ans dans l’industrie de...",
      "vues": 250,
      "since": "since 2021",
    },
  ];
  List<Video> _latestVideos = [];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: ListView(
        children: [
          // const PubComponent(),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "NOUVEAUTÉS",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: GPTheme.primaryColor,
                ),
              ),
            ],
          ),
          FutureBuilder(
            future: controller.fetchLatestVideos(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Error'));
              }
              if (snapshot.hasData) {
                _latestVideos = snapshot.data as List<Video>;
                if (_latestVideos.isEmpty) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: Text("Aucune vidéos récente")),
                  );
                } else {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: CarouselSlider(
                      items: _latestVideos.map((el) {
                        return Builder(
                          builder: (BuildContext context) {
                            return SizedBox(
                              width: MediaQuery.of(context).size.width,
                              child: InkWell(
                                onTap: () {
                                  controller.currentVidId.value = el.youtubeId;
                                  controller.currentId.value = el.id;
                                  Get.toNamed('${Routes.VIDEOS}/${el.id}');
                                },
                                child: Card(
                                  clipBehavior: Clip.hardEdge,
                                  child: Image.network(
                                    el.videoThumbnail,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }).toList(),
                      options: CarouselOptions(
                        height: 250,
                        aspectRatio: 12 / 9,
                        viewportFraction: 1,
                        initialPage: 0,
                        enableInfiniteScroll: true,
                        reverse: false,
                        autoPlay: true,
                        autoPlayInterval: const Duration(seconds: 3),
                        autoPlayAnimationDuration: const Duration(
                          milliseconds: 800,
                        ),
                        clipBehavior: Clip.hardEdge,
                        autoPlayCurve: Curves.fastOutSlowIn,
                        enlargeCenterPage: true,
                        enlargeFactor: 0.6,
                        scrollDirection: Axis.horizontal,
                      ),
                    ),
                  );
                }
              }
              return const Center(child: Text('No data'));
            },
          ),
          const SizedBox(height: 20),
          // TODO: Portraits section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "PORTRAITS",
                style: TextStyle(
                  color: GPTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  controller.changeCurrentIndex(4);
                },
                child: Row(
                  children: [
                    Text(
                      "VOIR PLUS",
                      style: TextStyle(color: GPTheme.primaryColor),
                    ),
                    Icon(Icons.arrow_forward_ios, color: GPTheme.primaryColor),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          const LatestSlider(cat: "portrait"),

          const SizedBox(height: 20),
          // TODO: Event section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "EVENTS",
                style: TextStyle(
                  color: GPTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  controller.changeCurrentIndex(5);
                },
                child: Row(
                  children: [
                    Text(
                      "Voir tout",
                      style: TextStyle(color: GPTheme.primaryColor),
                    ),
                    Icon(Icons.arrow_forward_ios, color: GPTheme.primaryColor),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          const LatestSlider(cat: "events"),

          const SizedBox(height: 20),
          // TODO: Opininion section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "OPINION",
                style: TextStyle(
                  color: GPTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  controller.changeCurrentIndex(6);
                },
                child: Row(
                  children: [
                    Text(
                      "Voir tout",
                      style: TextStyle(color: GPTheme.primaryColor),
                    ),
                    Icon(Icons.arrow_forward_ios, color: GPTheme.primaryColor),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          const LatestSlider(cat: "opinion"),

          const SizedBox(height: 20),
          // TODO: INSOLITE section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "INSOLITE",
                style: TextStyle(
                  color: GPTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  controller.changeCurrentIndex(7);
                },
                child: Row(
                  children: [
                    Text(
                      "Voir tout",
                      style: TextStyle(color: GPTheme.primaryColor),
                    ),
                    Icon(Icons.arrow_forward_ios, color: GPTheme.primaryColor),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          const LatestSlider(cat: "insolite"),
        ],
      ),
    );
  }
}
