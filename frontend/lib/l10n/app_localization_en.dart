// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localization.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get language => 'English';

  @override
  String get appTitle => 'Kaza Build';

  @override
  String get exploreBuilds => 'Explore Builds';

  @override
  String get discoverAmazingBuilds =>
      'Discover amazing PC builds from the community';

  @override
  String get searchBuilds => 'Search builds...';

  @override
  String get myBuilds => 'My Builds';

  @override
  String get takeQuiz => 'Take Quiz';

  @override
  String get startBuild => 'Start Build';

  @override
  String get close => 'Close';

  @override
  String get addToBuild => 'Add to Build';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get newText => 'New';

  @override
  String get filters => 'Filters';

  @override
  String get sortBy => 'Sort By';

  @override
  String get latest => 'Latest';

  @override
  String get popular => 'Popular';

  @override
  String get price => 'Price';

  @override
  String get clearAllFilters => 'Clear All Filters';

  @override
  String buildsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'builds',
      one: 'build',
    );
    return '$count $_temp0';
  }

  @override
  String get home => 'Home';

  @override
  String get explore => 'Explore';

  @override
  String get parts => 'Parts';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get logout => 'Logout';

  @override
  String get login => 'Login';

  @override
  String get signUp => 'Sign Up';

  @override
  String get welcomeBack => 'Welcome Back!';

  @override
  String get pcBuildingPlatform => 'PC Building Platform';

  @override
  String get buildNow => 'Build Now';

  @override
  String get guides => 'Guides';

  @override
  String get forums => 'Forums';

  @override
  String get adminPanel => 'Admin Panel';

  @override
  String get signIn => 'Sign In';

  @override
  String get welcome => 'Welcome';

  @override
  String get viewProfile => 'View Profile';

  @override
  String get cpu => 'CPU';

  @override
  String get gpu => 'GPU';

  @override
  String get motherboard => 'Motherboard';

  @override
  String get memoryRam => 'Memory (RAM)';

  @override
  String get storage => 'Storage';

  @override
  String get powerSupply => 'Power Supply';

  @override
  String get cooler => 'Cooler';

  @override
  String get caseFan => 'Case Fan';

  @override
  String get pcCase => 'Case';

  @override
  String get monitor => 'Monitor';

  @override
  String get saveBuild => 'Save Build';

  @override
  String get buildName => 'Build Name';

  @override
  String get description => 'Description (Optional)';

  @override
  String get tags => 'Tags (Optional)';

  @override
  String get noTagsAvailable => 'No tags available';

  @override
  String get errorLoadingTags => 'Error loading tags';

  @override
  String get buildSavedSuccessfully => 'Build saved successfully!';

  @override
  String get failedToSaveBuild => 'Failed to save build';

  @override
  String get startNewBuild => 'Start New Build?';

  @override
  String get unsavedChanges =>
      'You have unsaved changes. Are you sure you want to clear the current build?';

  @override
  String get clearBuild => 'Clear Build';

  @override
  String get postBuild => 'Post Build';

  @override
  String get enterBuildName => 'Enter a name for your build';

  @override
  String get describeBuild => 'Describe your build...';

  @override
  String get pleaseEnterName => 'Please enter a name';

  @override
  String get all => 'All';

  @override
  String get noGuidesFound => 'No guides found in this category';

  @override
  String get guidesTitle => 'PC Building Guides';

  @override
  String get guidesDescription => 'Learn from expert guides and tutorials';

  @override
  String get newest => 'Newest';

  @override
  String get oldest => 'Oldest';

  @override
  String get troubleshooting => 'Troubleshooting';

  @override
  String get buildAdvice => 'Build Advice';

  @override
  String get showOffBuild => 'Show Off Your Build';

  @override
  String get startDiscussion => 'Start Discussion';

  @override
  String get noPostsFound => 'No posts found';

  @override
  String get error => 'Error';

  @override
  String get searchPosts => 'Search posts...';

  @override
  String get frequentlyAskedQuestions => 'Frequently Asked Questions';

  @override
  String get findAnswersToCommonQuestions =>
      'Find answers to common questions about KAZABUILD';

  @override
  String get whatIsKazabuild => 'What is KAZABUILD?';

  @override
  String get whatIsKazabuildAnswer =>
      'KAZABUILD is a comprehensive PC building platform where enthusiasts can create, share, and explore custom PC builds. Whether you\'re a beginner or an expert, KAZABUILD helps you design the perfect PC configuration, get expert advice, and connect with the PC building community.';

  @override
  String get howDoICreateABuild => 'How do I create a PC build?';

  @override
  String get howDoICreateABuildAnswer =>
      'Creating a PC build is easy! Click on \"Build Now\" from the navigation menu, and you\'ll be guided through our interactive build wizard. You can select components from various categories like CPU, GPU, RAM, storage, and more. Our system will help you check compatibility and suggest optimal configurations based on your needs and budget.';

  @override
  String get arePricesUpToDate => 'Are the component prices up to date?';

  @override
  String get arePricesUpToDateAnswer =>
      'We strive to keep our component database and pricing as up-to-date as possible. However, prices can fluctuate frequently in the market. We recommend checking the latest prices from official retailers before making a purchase. Our platform provides a good estimate to help you plan your budget.';

  @override
  String get canIShareMyBuilds => 'Can I share my builds with others?';

  @override
  String get canIShareMyBuildsAnswer =>
      'Absolutely! KAZABUILD is designed to be a social platform. You can share your builds with the community, get feedback, and inspire others. You can also explore builds created by other users, save your favorites, and learn from different configurations.';

  @override
  String get howDoICheckCompatibility =>
      'How do I check component compatibility?';

  @override
  String get howDoICheckCompatibilityAnswer =>
      'Our build wizard automatically checks component compatibility as you select parts. The system validates factors like socket compatibility, power supply requirements, case size, and more. If there are any compatibility issues, you\'ll be notified with suggestions for compatible alternatives.';

  @override
  String get isKazabuildFree => 'Is KAZABUILD free to use?';

  @override
  String get isKazabuildFreeAnswer =>
      'Yes! KAZABUILD is completely free to use. You can create unlimited builds, browse the community, participate in forums, and access all our guides and resources without any cost. Simply create an account to get started and unlock additional features like saving your builds and joining discussions.';

  @override
  String get howCanIGetHelp => 'How can I get help with my build?';

  @override
  String get howCanIGetHelpAnswer =>
      'There are several ways to get help on KAZABUILD. You can post questions in our forums, where experienced builders and enthusiasts will be happy to help. You can also browse our comprehensive guides section for tutorials and tips. Additionally, you can comment on similar builds in the community to get specific advice.';

  @override
  String get canISaveMultipleBuilds => 'Can I save multiple builds?';

  @override
  String get canISaveMultipleBuildsAnswer =>
      'Yes! Once you create an account, you can save multiple builds and access them anytime. This is perfect for planning different builds for various purposes like gaming, content creation, or workstation setups. You can also edit, duplicate, and share your saved builds.';

  @override
  String get links => 'Links';

  @override
  String get info => 'Info';

  @override
  String get aboutUs => 'About Us';

  @override
  String get contactFeedback => 'Contact & Feedback';

  @override
  String get copyright => '© KAZA BUILD';

  @override
  String get builds => 'Builds';

  @override
  String get pcPartsCategories => 'PC Parts Categories';

  @override
  String get chooseCategoryToBrowse =>
      'Choose a category to browse available PC components';

  @override
  String get errorLoadingParts => 'Error loading parts';

  @override
  String itemsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'items',
      one: 'item',
    );
    return '$count $_temp0';
  }

  @override
  String get priceNotAvailable => 'Price N/A';

  @override
  String get manageAccountSettings =>
      'Manage your account settings and preferences';

  @override
  String get profilePicture => 'Profile Picture';

  @override
  String get profileInformation => 'Profile Information';

  @override
  String get displayName => 'Display Name';

  @override
  String get username => 'Username';

  @override
  String get usernameCannotBeChanged => 'Username cannot be changed';

  @override
  String get bio => 'Bio';

  @override
  String get notSet => 'Not set';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get address => 'Address';

  @override
  String get privacySecurity => 'Privacy & Security';

  @override
  String get profilePrivacy => 'Profile Privacy';

  @override
  String get private => 'Private';

  @override
  String get public => 'Public';

  @override
  String get changePassword => 'Change Password';

  @override
  String get updateAccountPassword => 'Update your account password';

  @override
  String get preferences => 'Preferences';

  @override
  String get theme => 'Theme';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get system => 'System';

  @override
  String get chooseFromGallery => 'Choose from Gallery';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get supportedFormats =>
      'Supported formats: JPG, JPEG, PNG, GIF, WEBP, AVIF, BMP, TIFF, HEIC, ICO. Max size: 25MB.';

  @override
  String get profilePictureUpdated => 'Profile picture updated successfully!';

  @override
  String get profileUpdated => 'Profile updated successfully!';

  @override
  String get updateFailed => 'Update failed';

  @override
  String get failedToUpload => 'Failed to upload';

  @override
  String get editAddress => 'Edit Address';

  @override
  String get country => 'Country';

  @override
  String get provinceState => 'Province / State';

  @override
  String get city => 'City';

  @override
  String get street => 'Street';

  @override
  String get number => 'Number';

  @override
  String get postalCode => 'Postal Code';

  @override
  String get apartmentOptional => 'Apartment (Optional)';

  @override
  String get displayNameMustBeAtLeast4 =>
      'Display name must be at least 4 characters';

  @override
  String get enterDisplayName => 'Enter Display Name';

  @override
  String get enterBio => 'Enter Bio';

  @override
  String get enterPhoneNumber => 'Enter Phone Number';

  @override
  String get manufacturer => 'Manufacturer';

  @override
  String get type => 'Type';

  @override
  String get releaseDate => 'Release Date';

  @override
  String get email => 'Email';

  @override
  String get noBuildsFound => 'No builds found';

  @override
  String get tryAdjustingFilters =>
      'Try adjusting your filters or check back later';

  @override
  String get errorLoadingBuilds => 'Error loading builds';

  @override
  String get retry => 'Retry';

  @override
  String get status => 'Status';

  @override
  String get noImage => 'No Image';

  @override
  String get clickToViewComponents => 'Click to view components';

  @override
  String get components => 'Components';

  @override
  String get comments => 'Comments';

  @override
  String get noImageAvailable => 'No Image Available';

  @override
  String get postedOn => 'Posted on';

  @override
  String get wishlistBuild => 'Wishlist Build';

  @override
  String get noComponentsListed => 'No components listed';

  @override
  String fromVendors(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vendors',
      one: 'vendor',
    );
    return 'from $count $_temp0';
  }

  @override
  String get signInToComment => 'Sign in to comment on this build';

  @override
  String get pleaseSignInToComment =>
      'Please sign in to comment. Use the navigation to go to login.';

  @override
  String get writeComment => 'Write a comment...';

  @override
  String get post => 'Post';

  @override
  String get pleaseSignInToCommentShort => 'Please sign in to comment';

  @override
  String get failedToLoadComments => 'Failed to load comments';

  @override
  String get noCommentsYet => 'No comments yet. Be the first to comment!';

  @override
  String get pleaseSignInToRate => 'Please sign in to rate this build.';

  @override
  String get pleaseSignInToRateBuilds => 'Please sign in to rate builds';

  @override
  String get failedToSubmitRating => 'Failed to submit rating';

  @override
  String get removeRating => 'Remove rating';

  @override
  String get rate => 'Rate';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get vendors => 'Vendors';

  @override
  String get similarBuilds => 'Similar Builds';

  @override
  String get series => 'Series';

  @override
  String get socket => 'Socket';

  @override
  String get chipset => 'Chipset';

  @override
  String get formFactor => 'Form Factor';

  @override
  String get memoryType => 'Memory Type';

  @override
  String get ramType => 'RAM Type';

  @override
  String get capacity => 'Capacity';

  @override
  String get speed => 'Speed';

  @override
  String get tdp => 'TDP';

  @override
  String get length => 'Length';

  @override
  String get height => 'Height';

  @override
  String get baseClock => 'Base Clock';

  @override
  String get boostClock => 'Boost Clock';

  @override
  String get coreCount => 'Core Count';

  @override
  String get threads => 'Threads';

  @override
  String get vram => 'VRAM';

  @override
  String get microarchitecture => 'Microarchitecture';

  @override
  String get coreFamily => 'Core Family';

  @override
  String get totalCores => 'Total Cores';

  @override
  String get pCores => 'P-Cores';

  @override
  String get eCores => 'E-Cores';

  @override
  String get l1Cache => 'L1 Cache';

  @override
  String get l2Cache => 'L2 Cache';

  @override
  String get l3Cache => 'L3 Cache';

  @override
  String get l4Cache => 'L4 Cache';

  @override
  String get lithography => 'Lithography';

  @override
  String get packaging => 'Packaging';

  @override
  String get includesCooler => 'Includes Cooler';

  @override
  String get smtSupport => 'SMT Support';

  @override
  String get eccSupport => 'ECC Support';

  @override
  String get integratedGraphics => 'Integrated Graphics';

  @override
  String get memoryClock => 'Memory Clock';

  @override
  String get memoryBusWidth => 'Memory Bus Width';

  @override
  String get slotWidth => 'Slot Width';

  @override
  String get totalSlots => 'Total Slots';

  @override
  String get coolingType => 'Cooling Type';

  @override
  String get frameSync => 'Frame Sync';

  @override
  String get ramSlots => 'RAM Slots';

  @override
  String get maxRam => 'Max RAM';

  @override
  String get cpuFanHeaders => 'CPU Fan Headers';

  @override
  String get caseFanHeaders => 'Case Fan Headers';

  @override
  String get pumpHeaders => 'Pump Headers';

  @override
  String get audioChipset => 'Audio Chipset';

  @override
  String get maxAudioChannels => 'Max Audio Channels';

  @override
  String get raidSupport => 'RAID Support';

  @override
  String get biosFlashback => 'BIOS Flashback';

  @override
  String get clearCmos => 'Clear CMOS';

  @override
  String get casLatency => 'CAS Latency';

  @override
  String get timings => 'Timings';

  @override
  String get modules => 'Modules';

  @override
  String get moduleCapacity => 'Module Capacity';

  @override
  String get ecc => 'ECC';

  @override
  String get registered => 'Registered';

  @override
  String get heatSpreader => 'Heat Spreader';

  @override
  String get rgb => 'RGB';

  @override
  String get voltage => 'Voltage';

  @override
  String get interface => 'Interface';

  @override
  String get nvme => 'NVMe';

  @override
  String get wattage => 'Wattage';

  @override
  String get efficiency => 'Efficiency';

  @override
  String get modularity => 'Modularity';

  @override
  String get fanless => 'Fanless';

  @override
  String get radiatorSize => 'Radiator Size';

  @override
  String get fanSize => 'Fan Size';

  @override
  String get fanQuantity => 'Fan Quantity';

  @override
  String get minFanSpeed => 'Min Fan Speed';

  @override
  String get maxFanSpeed => 'Max Fan Speed';

  @override
  String get minNoise => 'Min Noise';

  @override
  String get maxNoise => 'Max Noise';

  @override
  String get fanlessOperation => 'Fanless Operation';

  @override
  String get size => 'Size';

  @override
  String get quantity => 'Quantity';

  @override
  String get minAirflow => 'Min Airflow';

  @override
  String get maxAirflow => 'Max Airflow';

  @override
  String get pwm => 'PWM';

  @override
  String get ledType => 'LED Type';

  @override
  String get connector => 'Connector';

  @override
  String get controller => 'Controller';

  @override
  String get staticPressure => 'Static Pressure';

  @override
  String get flowDirection => 'Flow Direction';

  @override
  String get powerSupplyShrouded => 'Power Supply Shrouded';

  @override
  String get includedPsu => 'Included PSU';

  @override
  String get transparentSidePanel => 'Transparent Side Panel';

  @override
  String get sidePanelType => 'Side Panel Type';

  @override
  String get maxGpuLength => 'Max GPU Length';

  @override
  String get maxCpuCoolerHeight => 'Max CPU Cooler Height';

  @override
  String get screenSize => 'Screen Size';

  @override
  String get resolution => 'Resolution';

  @override
  String get refreshRate => 'Refresh Rate';

  @override
  String get panelType => 'Panel Type';

  @override
  String get responseTime => 'Response Time';

  @override
  String get viewingAngle => 'Viewing Angle';

  @override
  String get aspectRatio => 'Aspect Ratio';

  @override
  String get maxBrightness => 'Max Brightness';

  @override
  String get hdr => 'HDR';

  @override
  String get adaptiveSync => 'Adaptive Sync';

  @override
  String get sata6Gbs => 'SATA 6 Gb/s';

  @override
  String get sata3Gbs => 'SATA 3 Gb/s';

  @override
  String get u2Ports => 'U.2 Ports';

  @override
  String get wifi => 'Wi-Fi';

  @override
  String get argb5vHeaders => 'ARGB 5V Headers';

  @override
  String get rgb12vHeaders => 'RGB 12V Headers';

  @override
  String get internal35BayAmount => '3.5\" Bays';

  @override
  String get internal25BayAmount => '2.5\" Bays';

  @override
  String get external525BayAmount => '5.25\" Bays';

  @override
  String get external35BayAmount => '3.5\" External Bays';

  @override
  String get waterCooled => 'Water Cooled';

  @override
  String get airCooled => 'Air Cooled';
}
