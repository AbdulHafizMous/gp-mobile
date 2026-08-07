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
                  "Grand Public fait son retour avec une plateforme entièrement repensée, conçue pour vous offrir une expérience plus simple, plus riche et plus connectée.",
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                SizedBox(height: 20),
                Text(
                  "Retrouvez désormais 3 grands espaces :",
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                SizedBox(height: 20),
                Text(
                  "MEDIA : Explorez une sélection de contenus, vidéos et espaces dédiés à l'information, au divertissement et à vos centres d'intérêt.",
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                SizedBox(height: 20),
                Text(
                  "SOCIAL : Échangez, rencontrez et développez votre réseau grâce à nos différents espaces communautaires.",
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                SizedBox(height: 20),
                Text(
                  "CLUB : Profitez des promotions, offres exclusives et avantages proposés par nos partenaires.",
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                SizedBox(height: 20),
                Text(
                  "Dans SOCIAL, retrouvez 3 rubriques :",
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                SizedBox(height: 20),
                Text(
                  "CHAT : des canaux de discussion thématiques pour échanger avec la communauté.",
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                SizedBox(height: 20),
                Text(
                  "DATING : faites de nouvelles rencontres et trouvez des personnes qui partagent vos affinités.",
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                SizedBox(height: 20),
                Text(
                  "BIZZ : publiez et consultez des annonces pour proposer ou découvrir des produits, services et opportunités.",
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                SizedBox(height: 20),
                Text(
                  "Contactez-nous pour partager vos suggestions et vos expériences.",
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
