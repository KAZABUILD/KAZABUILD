/// This file defines the main "Guides" page, which displays a collection
/// of articles and tutorials related to PC building.
///
/// It features a responsive layout that automatically switches between a grid
/// view on wider screens (desktop) and a list view on narrower screens (mobile).
/// Each guide is presented as an interactive card with a hover effect and a
/// hero animation that provides a smooth transition to the `GuideDetailPage`.
library;

import 'package:flutter/material.dart';
import 'package:frontend/models/guide_model.dart';
import 'package:frontend/screens/guides/guide_detail_page.dart';
import 'package:frontend/widgets/navigation_bar.dart';
import 'package:frontend/l10n/app_localization.dart';

/// The main widget for the guides page.
class GuidesPage extends StatefulWidget {
  const GuidesPage({super.key});

  @override
  State<GuidesPage> createState() => _GuidesPageState();
}

/// The state for the [GuidesPage].
/// This class manages the layout and data for the page.
class _GuidesPageState extends State<GuidesPage> {
  /// A key to manage the Scaffold, particularly for opening the drawer on mobile.
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    /// Determine if the layout should be for mobile based on screen width.
    final isMobile = MediaQuery.of(context).size.width < 700;

    // Professional PC building guides with comprehensive content
    final List<Guide> allGuides = _getGuides();
    
    // Filter guides by category
    final allText = AppLocalizations.of(context)!.all;
    final selectedCat = _selectedCategory ?? allText;
    final List<Guide> guides = selectedCat == allText
        ? allGuides
        : allGuides.where((g) => g.category == selectedCat).toList();
    
    // Get unique categories
    final categories = [allText, ...allGuides.map((g) => g.category).toSet().toList()..sort()];

    return Scaffold(
      key: _scaffoldKey,
      drawer: CustomDrawer(showProfileArea: true),
      backgroundColor: theme.colorScheme.background,

      /// The main layout is a column with the navigation bar at the top
      /// and the scrollable content below.
      body: Column(
        children: [
          CustomNavigationBar(scaffoldKey: _scaffoldKey),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  /// The header section with the page title and description.
                  _buildHeader(theme, categories),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1400),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// Dynamically switch between a list and a grid based on screen size.
                          guides.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(48.0),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.article_outlined,
                                          size: 64,
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          AppLocalizations.of(context)!.noGuidesFound,
                                          style: theme.textTheme.titleLarge?.copyWith(
                                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : isMobile
                                  ? _buildGuidesList(guides)
                                  : _buildGuidesGrid(guides),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the header widget for the page with category filters.
  Widget _buildHeader(ThemeData theme, List<String> categories) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.1),
            theme.colorScheme.surface.withValues(alpha: 0.5),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.book_outlined,
                      size: 32,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.guidesTitle,
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context)!.guidesDescription,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Category filter chips
              Builder(
                builder: (context) {
                  final allText = AppLocalizations.of(context)!.all;
                  final selectedCat = _selectedCategory ?? allText;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: categories.map((category) {
                      final isSelected = selectedCat == category;
                      return FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                        selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                        checkmarkColor: theme.colorScheme.primary,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Returns a list of professional PC building guides.
  List<Guide> _getGuides() {
    return [
      Guide(
        id: '1',
        title: 'Complete Beginner\'s Guide to Building Your First PC',
        author: 'KazaBuild Team',
        imageUrl: 'https://images.unsplash.com/photo-1527864550417-7fd91fc51a46?w=800',
        category: 'Beginner',
        readTime: '15 min read',
        publishedDate: DateTime(2024, 1, 15),
        content: [
          {'type': 'h2', 'text': 'Introduction'},
          {'type': 'p', 'text': 'Building your first PC can seem intimidating, but with the right guidance, it\'s an incredibly rewarding experience. This comprehensive guide will walk you through every step of assembling your first custom computer, from selecting components to booting up your new system.'},
          {'type': 'h2', 'text': 'Why Build Your Own PC?'},
          {'type': 'p', 'text': 'Building your own PC offers several advantages over buying a pre-built system. You have complete control over component selection, ensuring you get exactly what you need for your budget and use case. You\'ll also save money, learn valuable skills, and have the satisfaction of creating something with your own hands.'},
          {'type': 'h2', 'text': 'Essential Components'},
          {'type': 'p', 'text': 'Before you start, familiarize yourself with the core components you\'ll need: CPU (Central Processing Unit), Motherboard, RAM (Random Access Memory), Storage (SSD or HDD), GPU (Graphics Processing Unit), PSU (Power Supply Unit), PC Case, and Cooling solutions.'},
          {'type': 'h2', 'text': 'Step-by-Step Assembly'},
          {'type': 'p', 'text': '1. Prepare your workspace with good lighting and an anti-static mat. 2. Install the CPU and cooler onto the motherboard. 3. Install RAM modules. 4. Mount the motherboard in the case. 5. Install storage drives. 6. Install the graphics card. 7. Connect all power cables. 8. Cable management. 9. Connect peripherals and boot up!'},
        ],
      ),
      Guide(
        id: '2',
        title: 'Choosing the Right CPU: Intel vs AMD Guide 2024',
        author: 'KazaBuild Team',
        imageUrl: 'https://images.unsplash.com/photo-1587825140708-dfaf72ae4b04?w=800',
        category: 'Components',
        readTime: '12 min read',
        publishedDate: DateTime(2024, 2, 10),
        content: [
          {'type': 'h2', 'text': 'CPU Selection Overview'},
          {'type': 'p', 'text': 'The CPU is the brain of your computer, and choosing the right one is crucial for your build\'s performance. This guide will help you navigate the Intel vs AMD landscape and find the perfect processor for your needs.'},
          {'type': 'h2', 'text': 'Intel Processors'},
          {'type': 'p', 'text': 'Intel\'s current lineup includes the Core i3, i5, i7, and i9 series, with the latest generation offering excellent single-core performance, strong gaming capabilities, and integrated graphics options. Intel processors typically excel in gaming scenarios and offer great overclocking potential.'},
          {'type': 'h2', 'text': 'AMD Processors'},
          {'type': 'p', 'text': 'AMD\'s Ryzen series has revolutionized the CPU market with exceptional multi-core performance and competitive pricing. Ryzen processors are excellent for content creation, multitasking, and productivity workloads, often offering better value per dollar.'},
          {'type': 'h2', 'text': 'Making Your Choice'},
          {'type': 'p', 'text': 'Consider your primary use case: Gaming-focused builds often benefit from Intel\'s high clock speeds, while content creators and multitaskers may prefer AMD\'s additional cores. Budget is also a key factor - AMD typically offers better value, while Intel commands a premium for top-tier gaming performance.'},
        ],
      ),
      Guide(
        id: '3',
        title: 'GPU Selection: Finding the Perfect Graphics Card',
        author: 'KazaBuild Team',
        imageUrl: 'https://images.unsplash.com/photo-1587202372634-32705e3bf49c?w=800',
        category: 'Components',
        readTime: '10 min read',
        publishedDate: DateTime(2024, 2, 25),
        content: [
          {'type': 'h2', 'text': 'Understanding GPU Specifications'},
          {'type': 'p', 'text': 'Graphics cards are one of the most important components for gaming and creative work. Understanding VRAM, CUDA cores, clock speeds, and power consumption will help you make an informed decision.'},
          {'type': 'h2', 'text': 'NVIDIA vs AMD'},
          {'type': 'p', 'text': 'NVIDIA typically leads in ray tracing and AI features, while AMD offers competitive performance at lower price points. Both manufacturers produce excellent GPUs, so your choice often comes down to specific features, pricing, and availability.'},
          {'type': 'h2', 'text': 'VRAM Considerations'},
          {'type': 'p', 'text': 'VRAM (Video Random Access Memory) is crucial for high-resolution gaming and content creation. For 1080p gaming, 6-8GB is sufficient. For 1440p, aim for 8-12GB. 4K gaming and professional work may require 16GB or more.'},
          {'type': 'h2', 'text': 'Power Requirements'},
          {'type': 'p', 'text': 'Modern GPUs can be power-hungry. Always check the recommended PSU wattage for your chosen GPU and ensure your power supply can handle the load, with some headroom for future upgrades.'},
        ],
      ),
      Guide(
        id: '4',
        title: 'Mastering PC Cable Management: A Clean Build Guide',
        author: 'KazaBuild Team',
        imageUrl: 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=800',
        category: 'Building',
        readTime: '8 min read',
        publishedDate: DateTime(2024, 3, 5),
        content: [
          {'type': 'h2', 'text': 'Why Cable Management Matters'},
          {'type': 'p', 'text': 'Proper cable management isn\'t just about aesthetics - it improves airflow, makes maintenance easier, and extends the life of your components by preventing overheating and cable damage.'},
          {'type': 'h2', 'text': 'Planning Your Routes'},
          {'type': 'p', 'text': 'Before connecting everything, plan your cable routes. Most modern cases have routing channels behind the motherboard tray. Route cables through these channels and use cable ties to secure them in place.'},
          {'type': 'h2', 'text': 'Essential Tools'},
          {'type': 'p', 'text': 'Invest in quality cable ties (both reusable and zip ties), velcro straps, and cable combs for organizing GPU power cables. A magnetic screwdriver and patience are also essential tools for clean cable management.'},
          {'type': 'h2', 'text': 'Best Practices'},
          {'type': 'p', 'text': 'Keep cables away from fans, use the shortest possible routes, bundle similar cables together, and leave some slack for maintenance. Always test your build before finalizing cable management to avoid having to redo everything.'},
        ],
      ),
      Guide(
        id: '5',
        title: 'RAM Selection: Understanding Speed, Capacity, and Timings',
        author: 'KazaBuild Team',
        imageUrl: 'https://images.unsplash.com/photo-1591488320449-011701bb6704?w=800',
        category: 'Components',
        readTime: '9 min read',
        publishedDate: DateTime(2024, 3, 15),
        content: [
          {'type': 'h2', 'text': 'RAM Fundamentals'},
          {'type': 'p', 'text': 'RAM (Random Access Memory) is your system\'s short-term memory, storing data that your CPU needs quick access to. Understanding capacity, speed, and timings is key to optimal performance.'},
          {'type': 'h2', 'text': 'Capacity: How Much Do You Need?'},
          {'type': 'p', 'text': 'For modern systems, 16GB is the sweet spot for most users. 8GB works for basic tasks, but can be limiting. 32GB is ideal for content creators, heavy multitaskers, and future-proofing. 64GB+ is reserved for professional workstations.'},
          {'type': 'h2', 'text': 'Speed and Timings'},
          {'type': 'p', 'text': 'DDR4 speeds range from 2133MHz to 4800MHz+, while DDR5 starts at 4800MHz and goes much higher. Timings (CL latency) matter too - lower is better. Balance speed, timings, and price for your specific use case.'},
          {'type': 'h2', 'text': 'Dual Channel and XMP'},
          {'type': 'p', 'text': 'Always install RAM in pairs for dual-channel performance. Enable XMP (Extreme Memory Profile) in your BIOS to run RAM at advertised speeds - most motherboards default to slower JEDEC speeds without XMP enabled.'},
        ],
      ),
      Guide(
        id: '6',
        title: 'Storage Solutions: SSD vs HDD and NVMe Explained',
        author: 'KazaBuild Team',
        imageUrl: 'https://images.unsplash.com/photo-1597872200969-2b65d56bd16b?w=800',
        category: 'Components',
        readTime: '11 min read',
        publishedDate: DateTime(2024, 3, 20),
        content: [
          {'type': 'h2', 'text': 'Storage Types Overview'},
          {'type': 'p', 'text': 'Modern PCs use various storage technologies. Understanding the differences between SATA SSDs, NVMe SSDs, and HDDs will help you build a storage solution that balances speed, capacity, and cost.'},
          {'type': 'h2', 'text': 'NVMe SSDs: The Speed Champions'},
          {'type': 'p', 'text': 'NVMe (Non-Volatile Memory Express) SSDs connect directly to PCIe lanes, offering speeds up to 7000MB/s. They\'re ideal for your operating system, applications, and frequently accessed files. The performance difference is dramatic compared to traditional drives.'},
          {'type': 'h2', 'text': 'SATA SSDs: The Balanced Choice'},
          {'type': 'p', 'text': 'SATA SSDs offer excellent performance at a lower cost than NVMe drives. With speeds around 500-550MB/s, they\'re perfect for secondary storage, game libraries, and budget builds where NVMe might be overkill.'},
          {'type': 'h2', 'text': 'HDDs: Cost-Effective Bulk Storage'},
          {'type': 'p', 'text': 'Traditional hard drives offer massive storage capacity at low cost, perfect for media libraries, backups, and archives. While slow compared to SSDs, they remain valuable for bulk storage needs where speed isn\'t critical.'},
          {'type': 'h2', 'text': 'Recommended Setup'},
          {'type': 'p', 'text': 'A modern PC should have at least one NVMe SSD for the OS and key applications, with additional SATA SSDs for games and HDDs for bulk storage. This hybrid approach maximizes performance while keeping costs reasonable.'},
        ],
      ),
      Guide(
        id: '7',
        title: 'Power Supply Units: Wattage, Efficiency, and Reliability',
        author: 'KazaBuild Team',
        imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800',
        category: 'Components',
        readTime: '10 min read',
        publishedDate: DateTime(2024, 4, 1),
        content: [
          {'type': 'h2', 'text': 'PSU: The Unsung Hero'},
          {'type': 'p', 'text': 'Your power supply unit is one of the most important components, yet often overlooked. A quality PSU protects your entire system and ensures stable operation, while a poor one can damage components and cause instability.'},
          {'type': 'h2', 'text': 'Calculating Wattage'},
          {'type': 'p', 'text': 'Use online PSU calculators to estimate your system\'s power needs. As a general rule: budget builds need 450-550W, mid-range systems need 650-750W, high-end gaming PCs need 750-850W, and enthusiast builds may need 1000W+. Always add 20% headroom for efficiency and future upgrades.'},
          {'type': 'h2', 'text': '80 Plus Efficiency Ratings'},
          {'type': 'p', 'text': '80 Plus ratings (Bronze, Silver, Gold, Platinum, Titanium) indicate efficiency at different load levels. Gold is the sweet spot for most builds, offering excellent efficiency without premium pricing. Higher ratings reduce power consumption and heat output.'},
          {'type': 'h2', 'text': 'Modular vs Non-Modular'},
          {'type': 'p', 'text': 'Modular PSUs allow you to connect only the cables you need, improving airflow and cable management. Semi-modular units have essential cables fixed (like 24-pin ATX) but allow customization of others. Non-modular PSUs are cheaper but create cable clutter.'},
          {'type': 'h2', 'text': 'Brand and Quality Matters'},
          {'type': 'p', 'text': 'Don\'t skimp on your PSU. Stick to reputable brands known for quality and reliability. A quality PSU can last through multiple builds and protect your investment in expensive components.'},
        ],
      ),
      Guide(
        id: '8',
        title: 'Cooling Solutions: Air vs Liquid Cooling Guide',
        author: 'KazaBuild Team',
        imageUrl: 'https://images.unsplash.com/photo-1558494949-ef010cbdcc31?w=800',
        category: 'Cooling',
        readTime: '13 min read',
        publishedDate: DateTime(2024, 4, 10),
        content: [
          {'type': 'h2', 'text': 'Cooling Basics'},
          {'type': 'p', 'text': 'Proper cooling is essential for performance and longevity. Excess heat causes throttling, reduces component lifespan, and can lead to system instability. Understanding cooling options helps you make the right choice for your build.'},
          {'type': 'h2', 'text': 'Air Cooling'},
          {'type': 'p', 'text': 'Air coolers use heat pipes and fins to dissipate heat. They\'re reliable, maintenance-free, and cost-effective. High-end air coolers can match or even exceed AIO liquid coolers in performance. They\'re also quieter and have no risk of leaks.'},
          {'type': 'h2', 'text': 'AIO Liquid Cooling'},
          {'type': 'p', 'text': 'All-In-One liquid coolers offer excellent cooling performance and aesthetic appeal. They\'re easier to install than custom loops and take up less space around the CPU socket. However, they\'re more expensive, have moving parts that can fail, and may produce pump noise.'},
          {'type': 'h2', 'text': 'Case Airflow'},
          {'type': 'p', 'text': 'Regardless of CPU cooling, case airflow is crucial. Use positive pressure (more intake than exhaust) to reduce dust. Position intake fans at the front/bottom and exhaust fans at the top/rear. Mesh-front cases provide the best airflow.'},
          {'type': 'h2', 'text': 'Thermal Paste Application'},
          {'type': 'p', 'text': 'Proper thermal paste application improves heat transfer. A pea-sized dot in the center works for most CPUs. Avoid spreading it manually - the cooler\'s pressure will distribute it evenly when installed correctly.'},
        ],
      ),
      Guide(
        id: '9',
        title: 'PC Case Selection: Form Factor and Airflow Guide',
        author: 'KazaBuild Team',
        imageUrl: 'https://images.unsplash.com/photo-1531297484001-80022131f5a1?w=800',
        category: 'Components',
        readTime: '9 min read',
        publishedDate: DateTime(2024, 4, 15),
        content: [
          {'type': 'h2', 'text': 'Case Form Factors'},
          {'type': 'p', 'text': 'PC cases come in various sizes: Full Tower (largest), Mid Tower (most popular), Mini Tower, and Small Form Factor (SFF). Your motherboard form factor (ATX, mATX, ITX) determines which cases are compatible.'},
          {'type': 'h2', 'text': 'Airflow Considerations'},
          {'type': 'p', 'text': 'Mesh-front cases provide the best airflow, while solid-front panels with side vents offer a compromise between aesthetics and cooling. Glass panels are beautiful but can restrict airflow if not designed with ventilation in mind.'},
          {'type': 'h2', 'text': 'Cable Management Features'},
          {'type': 'p', 'text': 'Look for cases with routing channels, tie-down points, and adequate space behind the motherboard tray. PSU shrouds hide cables and improve aesthetics. Removable drive cages provide flexibility for larger GPUs and better airflow.'},
          {'type': 'h2', 'text': 'Build Quality and Features'},
          {'type': 'p', 'text': 'Check for tool-less drive installation, dust filters on intakes, adequate fan mounting points, and good build materials. Tempered glass panels are safer than acrylic and resist scratching better. USB-C front panel connectors are becoming essential.'},
        ],
      ),
      Guide(
        id: '10',
        title: 'BIOS Setup and Optimization for New Builds',
        author: 'KazaBuild Team',
        imageUrl: 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=800',
        category: 'Optimization',
        readTime: '14 min read',
        publishedDate: DateTime(2024, 4, 25),
        content: [
          {'type': 'h2', 'text': 'Entering BIOS'},
          {'type': 'p', 'text': 'When you first boot your new PC, press Delete, F2, or F12 (varies by manufacturer) to enter BIOS. The key is usually displayed during boot. Modern UEFI BIOS interfaces are much more user-friendly than legacy BIOS.'},
          {'type': 'h2', 'text': 'Essential BIOS Settings'},
          {'type': 'p', 'text': 'Enable XMP/DOCP for RAM to run at advertised speeds. Set boot priority to your OS drive. Enable Secure Boot for security. Disable unnecessary features like unused SATA ports or onboard audio if using a sound card.'},
          {'type': 'h2', 'text': 'Fan Curves and Cooling'},
          {'type': 'p', 'text': 'Configure fan curves to balance noise and cooling. Most motherboards offer preset curves (Silent, Standard, Performance) or custom curve creation. Adjust based on your cooling setup and noise tolerance.'},
          {'type': 'h2', 'text': 'Overclocking Basics'},
          {'type': 'p', 'text': 'For beginners, enable auto-overclocking features if available. Manual overclocking requires understanding voltages, multipliers, and stability testing. Start conservative and test thoroughly with tools like Prime95 and AIDA64.'},
          {'type': 'h2', 'text': 'Security Settings'},
          {'type': 'p', 'text': 'Set a BIOS password to prevent unauthorized changes. Enable TPM (Trusted Platform Module) if you plan to use Windows 11. Keep your BIOS updated for security patches and compatibility improvements.'},
        ],
      ),
      Guide(
        id: '11',
        title: 'Budget Gaming PC Build Guide: Best Value for Money',
        author: 'KazaBuild Team',
        imageUrl: 'https://images.unsplash.com/photo-1527864550417-7fd91fc51a46?w=800',
        category: 'Builds',
        readTime: '16 min read',
        publishedDate: DateTime(2024, 5, 5),
        content: [
          {'type': 'h2', 'text': 'Budget Building Philosophy'},
          {'type': 'p', 'text': 'Building a budget gaming PC doesn\'t mean compromising on quality. Smart component selection and knowing where to allocate your budget can deliver excellent gaming performance without breaking the bank.'},
          {'type': 'h2', 'text': 'Component Prioritization'},
          {'type': 'p', 'text': 'For gaming, allocate your budget: GPU (40-50%), CPU (20-25%), Motherboard (10-15%), RAM (8-10%), Storage (8-10%), PSU (8-10%), Case (5-8%). Don\'t skimp on the PSU - a quality unit protects your entire investment.'},
          {'type': 'h2', 'text': 'Recommended Budget Build'},
          {'type': 'p', 'text': 'A solid budget build (\$600-800) might include: Ryzen 5 5600 or Intel i3-12100F CPU, B550 or B660 motherboard, 16GB DDR4-3200 RAM, 500GB NVMe SSD, RTX 3060 or RX 6600 XT GPU, 650W 80+ Gold PSU, and a budget mid-tower case.'},
          {'type': 'h2', 'text': 'Cost-Saving Tips'},
          {'type': 'p', 'text': 'Buy during sales, consider previous-generation components, use stock CPU coolers, skip RGB initially (add later), buy a case with included fans, and consider used GPUs from reputable sellers. Wait for bundle deals on CPU/motherboard combos.'},
          {'type': 'h2', 'text': 'Future Upgrade Path'},
          {'type': 'p', 'text': 'Choose a platform with upgrade potential. AM4/AM5 motherboards offer long upgrade paths. Invest in a quality PSU and case - these last through multiple builds. Buy RAM as a kit (not single sticks) for dual-channel performance.'},
        ],
      ),
      Guide(
        id: '12',
        title: 'High-End Gaming PC: Building the Ultimate Rig',
        author: 'KazaBuild Team',
        imageUrl: 'https://images.unsplash.com/photo-1587202372634-32705e3bf49c?w=800',
        category: 'Builds',
        readTime: '18 min read',
        publishedDate: DateTime(2024, 5, 15),
        content: [
          {'type': 'h2', 'text': 'Premium Build Overview'},
          {'type': 'p', 'text': 'Building a high-end gaming PC means no compromises. Every component is selected for maximum performance, aesthetics, and future-proofing. This guide covers building a system that will handle any game at maximum settings.'},
          {'type': 'h2', 'text': 'Top-Tier Components'},
          {'type': 'p', 'text': 'For an ultimate build, consider: Intel i9-13900K or AMD Ryzen 9 7950X CPU, Z790 or X670E motherboard, 32GB DDR5-6000+ RAM, 2TB Gen4 NVMe SSD, RTX 4090 or RX 7900 XTX GPU, 1000W+ 80+ Platinum PSU, and premium case with excellent airflow.'},
          {'type': 'h2', 'text': 'Cooling Considerations'},
          {'type': 'p', 'text': 'High-end builds generate significant heat. Consider 360mm AIO or custom liquid cooling for the CPU. Ensure excellent case airflow with multiple high-quality fans. GPU liquid cooling or aftermarket air coolers may be necessary for maximum overclocking.'},
          {'type': 'h2', 'text': 'Aesthetics and RGB'},
          {'type': 'p', 'text': 'Premium builds often feature extensive RGB lighting, custom cables, and themed aesthetics. Software like iCUE, Aura Sync, or Razer Synapse can sync lighting across components. Plan your color scheme and component selection for cohesive theming.'},
          {'type': 'h2', 'text': 'Performance Optimization'},
          {'type': 'p', 'text': 'Enable XMP/DOCP, overclock CPU and GPU, optimize Windows settings, install latest drivers, and use monitoring software. High-end components benefit from fine-tuning - spend time optimizing for maximum performance.'},
        ],
      ),
    ];
  }

  /// Builds a responsive grid of guide cards for desktop layouts.
  Widget _buildGuidesGrid(List<Guide> guides) {
    /// Uses [GridView.builder] for efficient rendering of a potentially large number of items.
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        childAspectRatio: 0.8,
      ),
      itemCount: guides.length,
      itemBuilder: (context, index) {
        return _GuideCard(guide: guides[index]);
      },
    );
  }

  /// Builds a vertical list of guide cards for mobile layouts.
  Widget _buildGuidesList(List<Guide> guides) {
    /// Uses [ListView.separated] to automatically add spacing between the cards.
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: guides.length,
      separatorBuilder: (context, index) => const SizedBox(height: 24),
      itemBuilder: (context, index) {
        return _GuideCard(guide: guides[index]);
      },
    );
  }
}

/// A card widget that displays a summary of a single [Guide].
///
/// It includes a hero animation for the image for a smooth page transition
/// and a hover effect that scales the card up slightly on desktop.
class _GuideCard extends StatefulWidget {
  final Guide guide;
  const _GuideCard({required this.guide});

  @override
  State<_GuideCard> createState() => _GuideCardState();
}

/// The state for [_GuideCard], which manages the hover state.
class _GuideCardState extends State<_GuideCard> {
  /// A flag to track whether the mouse cursor is currently over the card.
  bool _isHovered = false;

  Widget _buildGuideImage(String imageUrl, ThemeData theme) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.3),
            theme.colorScheme.secondary.withValues(alpha: 0.2),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
                child: Icon(
                  Icons.article_outlined,
                  size: 64,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.3),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    /// Determine the scale factor based on the hover state to create an animation.
    final scale = _isHovered ? 1.03 : 1.0;

    /// [MouseRegion] detects when the cursor enters or leaves the widget's area to trigger the hover effect.
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),

      /// [AnimatedScale] provides a smooth scaling animation when the `scale` value changes.
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 200),
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GuideDetailPage(guide: widget.guide),
              ),
            );
          },
          child: Card(
            elevation: _isHovered ? 8 : 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// The [Hero] widget enables a smooth shared element transition for the image
                /// when navigating to the detail page.
                Hero(
                  /// The tag must be unique for each guide to identify the correct image for the animation.
                  tag: 'guide_image_${widget.guide.id}',
                  child: _buildGuideImage(widget.guide.imageUrl, theme),
                ),

                /// The content section of the card containing text details.
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.guide.category,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.guide.title,
                        // Guide title with a larger font size.
                        style: theme.textTheme.titleLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        // A row for metadata like author and read time.
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              widget.guide.author,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.guide.readTime,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
