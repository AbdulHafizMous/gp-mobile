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
                SizedBox(height: 30),

                // ── GRAND PUBLIC BÉNIN ──────────────────────────────────
                Text(
                  "GRAND PUBLIC BÉNIN",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "100% Vidéo, 100% Bénin !",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  "Vous recherchez du contenu 100% Vidéo, 100% Bénin ! Bienvenue dans l'univers de GRAND PUBLIC BÉNIN : Media, Social, Club.",
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                SizedBox(height: 30),

                // ── GRAND PUBLIC MEDIA ───────────────────────────────────
                Text(
                  "GRAND PUBLIC MEDIA",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "100% Emotion !",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  "Envie de sortir, de découvrir des personnalités ou même de vous informer ? Bienvenue dans l'univers de GRAND PUBLIC MEDIA : People, Events, News.",
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                SizedBox(height: 12),
                Text(
                  "› PEOPLE est dédiée aux personnes, anonymes ou non, considérées comme des modèles à suivre ;",
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                SizedBox(height: 10),
                Text(
                  "› EVENTS est consacrée aux événements passés ou à venir. Vous aurez envie d'y aller et même ratés, vous les revivrez ;",
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                SizedBox(height: 10),
                Text(
                  "› NEWS, c'est l'information expliquée de façon simple, directe et sans parti pris. Ici, le grand public s'exprime.",
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                SizedBox(height: 30),

                // ── GRAND PUBLIC SOCIAL ──────────────────────────────────
                Text(
                  "GRAND PUBLIC SOCIAL",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "On est Ensemble !",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  "Envie de t'exprimer, de faire des rencontres ou même de faire des affaires ? Bienvenue dans l'univers de GRAND PUBLIC SOCIAL : Tchat, Crush, Bizz.",
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                SizedBox(height: 12),
                Text(
                  "› TCHAT vous permet de donner votre point de vue sur les sujets qui vous préoccupent ;",
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                SizedBox(height: 10),
                Text(
                  "› CRUSH vous fait mieux connaitre et rencontrer l'âme sœur ;",
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                SizedBox(height: 10),
                Text(
                  "› BIZZ est consacrée aux annonces de particulier à particulier pour rechercher, offrir un produit ou un service.",
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                SizedBox(height: 30),

                // ── GRAND PUBLIC CLUB ────────────────────────────────────
                Text(
                  "GRAND PUBLIC CLUB",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Les meilleurs plans !",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  "Vous faites partie de la communauté de GRAND PUBLIC BÉNIN, vous bénéficiez de tous les meilleurs plans ! Bienvenue dans l'univers de GRAND PUBLIC CLUB : Offres, Partenaires, Notifications.",
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                SizedBox(height: 12),
                Text(
                  "› OFFRES vous permet d'être informés des meilleurs plans de nos partenaires en temps réel ;",
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                SizedBox(height: 10),
                Text(
                  "› PARTENAIRES vous permet de découvrir les commerces et services classés par activité avec le détail de tous les avantages qu'ils offrent ;",
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                SizedBox(height: 10),
                Text(
                  "› NOTIFICATIONS vous rappelle les opportunités selon vos centres d'intérêt.",
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                SizedBox(height: 30),

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
