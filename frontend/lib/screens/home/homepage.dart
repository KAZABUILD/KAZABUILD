import 'package:flutter/material.dart';
import 'package:frontend/screens/home/faq_section.dart';
import 'package:frontend/screens/home/featured_builds.dart';
import 'package:frontend/screens/home/home_body.dart';
import 'package:frontend/widgets/icon_bar.dart';
import 'package:frontend/widgets/last_bar.dart';
import 'package:frontend/widgets/navigation_bar.dart';
import 'package:frontend/widgets/part_categories.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // dont make any changes in here
          IconBar(),
          CustomNavigationBar(),

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
