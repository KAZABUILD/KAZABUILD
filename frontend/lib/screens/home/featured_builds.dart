import 'package:flutter/material.dart';
import '../../core/constants/app_color.dart';
import 'package:carousel_slider/carousel_slider.dart'
    show CarouselSlider, CarouselOptions, CarouselSliderController;

class FeaturedBuilds extends StatefulWidget {
  const FeaturedBuilds({super.key});

  @override
  State<FeaturedBuilds> createState() => _FeaturedBuildsState();
}

class _FeaturedBuildsState extends State<FeaturedBuilds> {
  // we will get this datas in database for now i just created test list
  final List<Map<String, String>> buildItems = [
    {'title': 'Best', 'price': '\$2,499'},

    {'title': 'RGB', 'price': '\$1,899'},

    {'title': 'Work', 'price': '\$2,199'},
  ];

  int _current = 0;
  final CarouselSliderController _controller = CarouselSliderController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // if there is no build dont show the carousel effect im not sure about that we will see....

    if (buildItems.isEmpty) {
      return Container(
        height: 380,
        alignment: Alignment.center,
        child: Text(
          'Featured builds will be there!',
          style: theme.textTheme.titleLarge,
        ),
      );
    }

    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: buildItems.length,
          carouselController: _controller,
          itemBuilder: (context, index, realIndex) {
            final item = buildItems[index];
            return _BuildCard(
              title: item['title']!,
              price: item['price']!,
              theme: theme,
            );
          },
          options: CarouselOptions(
            // all carousel settings re there
            height: 380,
            autoPlay: true,
            enlargeCenterPage: true,
            viewportFraction: 0.75,
            aspectRatio: 2.0,
            onPageChanged: (index, reason) {
              setState(() {
                _current = index;
              });
            },
          ),
        ),
        const SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: buildItems.asMap().entries.map((entry) {
            return GestureDetector(
              onTap: () => _controller.animateToPage(entry.key),
              child: Container(
                width: 12.0,
                height: 12.0,
                margin: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 4.0,
                ),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      (Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black)
                          .withOpacity(_current == entry.key ? 0.9 : 0.4),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _BuildCard extends StatelessWidget {
  final String title;
  final String price;
  final ThemeData theme;

  const _BuildCard({
    required this.title,
    required this.price,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: MediaQuery.of(context).size.width,
      margin: const EdgeInsets.symmetric(horizontal: 5.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://placehold.co/600x400/222/fff?text=PC+Build',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Starts from $price',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode
                          ? AppColorsDark.textNeon
                          : AppColorsLight.textNeon,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 15,
                      ),
                    ),
                    child: const Text('View Details'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
