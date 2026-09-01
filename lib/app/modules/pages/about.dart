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
                  "GRAND PUBLIC BENIN",
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
                  "Bienvenue dans l'univers de GRAND PUBLIC BENIN : Media, Social, Club.",
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
                  "Envie de sortir, de découvrir des personnalités ou même de t'informer ?",
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                SizedBox(height: 12),
                Text(
                  "› PEOPLE : Des personnalités et des anonymes qui inspirent ;",
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                SizedBox(height: 10),
                Text(
                  "› EVENTS : Des événements mémorables à vivre ou à revivre ;",
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                SizedBox(height: 10),
                Text(
                  "› NEWS : L'actualité expliquée simplement et sans parti pris.",
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
                  "Envie de t'exprimer, de faire des rencontres ou même de faire des affaires ?",
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                SizedBox(height: 12),
                Text(
                  "› TCHAT : Ton point de vue sur les sujets qui comptent ;",
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                SizedBox(height: 10),
                Text(
                  "› CRUSH : Ton âme sœur à découvrir et à rencontrer ;",
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                SizedBox(height: 10),
                Text(
                  "› BIZZ : Des annonces de recherches et d'offres entre particuliers.",
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
                  "Les Meilleurs Plans !",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  "Tu es dans GRAND PUBLIC BENIN, tu bénéficies de tous les meilleurs plans !",
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                SizedBox(height: 12),
                Text(
                  "› OFFRES : Les meilleurs plans de nos partenaires ;",
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                SizedBox(height: 10),
                Text(
                  "› PARTENAIRES : Les commerces et services classés par activité ;",
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                SizedBox(height: 10),
                Text(
                  "› NOTIFICATIONS : Les opportunités selon tes centres d'intérêt.",
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                SizedBox(height: 30),

                Text(
                  "Contacte-nous pour partager tes suggestions et expériences.",
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