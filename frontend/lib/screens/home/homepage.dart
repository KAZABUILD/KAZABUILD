import 'package:flutter/material.dart';
import 'package:frontend/screens/home/faq_section.dart';
import 'package:frontend/screens/home/featured_builds.dart';
import 'package:frontend/screens/home/home_body.dart';

import 'package:frontend/widgets/last_bar.dart';
import 'package:frontend/widgets/navigation_bar.dart';
import 'package:frontend/widgets/part_categories.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: CustomDrawer(showProfileArea: true),
      body: Column(
        children: [
          CustomNavigationBar(scaffoldKey: _scaffoldKey),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  HomeBody(),
                  SizedBox(height: 40),
                  FeaturedBuilds(),
                  SizedBox(height: 40),
                  PartCategoriesSection(),
                  SizedBox(height: 60),
                  FaqSection(),
                  LastBar(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
