import 'package:flutter/material.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

class LivePage extends StatefulWidget {
  const LivePage({super.key});

  @override
  State<LivePage> createState() => _LivePageState();
}

class _LivePageState extends State<LivePage> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // const PubComponent(),
          const SizedBox(height: 20),
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const Image(
                  image: NetworkImage(
                    'https://s3-alpha-sig.figma.com/img/745b/9995/99bf03864e75e6c07b887455921f28cc?Expires=1739750400&Key-Pair-Id=APKAQ4GOSFWCW27IBOMQ&Signature=iZJ~UXwytx2OXI6BONEyB61qLb1WFxyU~MQebrX4v7VaBWQ2JHfVXLwS~CfsWFJ0YttNnhAPTXXuF3SMbZol9dm2EJ~6C~1uMks2FrctJ9CvgEe43HPGywCkvzOy~Qm9kDtABUdkh6o46bJncO8YazscCYoybF-yHa2pcpgKbC8d0ELZ11rPCB1uBgZx9C4FZMzabPNyYpTd6j-NEJspXgCvVPWJ0JynqPTHU9DgyGbbPJeRjDLQNT9BVNt-acKBVmkHh4st-~rOrCJQbELAZ8eIqFyB1eAhr-n-VIdfQvKX0trqLxwGYZAPalJFR0W-RmCbeCdDBSGHEWYAJV82zA__',
                  ),
                ).image,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const Text(
            "PROCHAIN LIVE",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Text(
                "Suivez nous sur nos ",
                style: TextStyle(fontSize: 17),
              ),
              Text(
                "réseaux sociaux ",
                style: TextStyle(
                  fontSize: 17,
                  backgroundColor: GPTheme.primaryColor,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                "pour ne pas rater nos prochains LIVES.",
                style: TextStyle(fontSize: 17),
                textAlign: TextAlign.start,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
