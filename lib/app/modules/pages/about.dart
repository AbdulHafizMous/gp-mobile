import 'package:flutter/material.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  ScrollController controller = ScrollController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint("scrolling to top");
      controller.animateTo(
        controller.position.maxScrollExtent,
        duration: const Duration(seconds: 20),
        curve: Curves.linear,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/images/wall_start.png"),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.65,
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              children: const [
                SizedBox(height: 400),
                Text(
                  "Bienvenue à tous,",
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
                SizedBox(height: 20),
                Text(
                  "Grandpublic, votre plateforme internet 100% video, fait son retour avec une refonte totale de son contenu, entièrement orienté vers VOUS.",
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                SizedBox(height: 20),
                Text(
                  "Au menu, 5 grandes rubriques :",
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                SizedBox(height: 20),
                Text(
                  "MEDIA : Explorez des univers riches avec des contenus variés : médias, lives et expériences immersives.",
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                SizedBox(height: 20),
                Text(
                  "MUSIC : Découvrez les tendances musicales, artistes et contenus exclusifs.",
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                SizedBox(height: 20),
                Text(
                  "SOCIAL : Discutez, échangez et connectez-vous avec la communauté.",
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                SizedBox(height: 20),
                Text(
                  "CLUB : Profitez d'offres exclusives, promotions et avantages uniques.",
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                SizedBox(height: 20),
                Text(
                  "SHOP : Achetez en live et explorez les produits tendance.",
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                SizedBox(height: 20),
                Text(
                  "Grand Public, c'est aussi une application mobile innovante, qui allie des contenus vidéo captivants et des interactions sociales uniques.",
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                SizedBox(height: 20),
                Text(
                  "Dans SOCIAL, votre réseau social sur GRAND PUBLIC, retrouvez :",
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                SizedBox(height: 20),
                Text(
                  "CHAT : pour discuter en communauté sur des sujets d'intérêts",
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                SizedBox(height: 20),
                Text(
                  "DATING : pour rencontrer votre âme sœur et vivre de grands moments de bonheur.",
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                SizedBox(height: 20),
                Text(
                  "Contactez-nous pour partager vos expériences.",
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                SizedBox(height: 20),
                Text(
                  "GRAND PUBLIC, PARTAGEONS LES GRANDS MOMENTS !",
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
              ],
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.1,
            child: const Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "grandpublic.bj",
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    Text(
                      "contact@grandpublic.bj",
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
