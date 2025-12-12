import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localization_en.dart';
import 'app_localization_pl.dart';
import 'app_localization_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localization.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pl'),
    Locale('tr'),
  ];

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get language;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Kaza Build'**
  String get appTitle;

  /// No description provided for @exploreBuilds.
  ///
  /// In en, this message translates to:
  /// **'Explore Builds'**
  String get exploreBuilds;

  /// No description provided for @discoverAmazingBuilds.
  ///
  /// In en, this message translates to:
  /// **'Discover amazing PC builds from the community'**
  String get discoverAmazingBuilds;

  /// No description provided for @searchBuilds.
  ///
  /// In en, this message translates to:
  /// **'Search builds...'**
  String get searchBuilds;

  /// No description provided for @myBuilds.
  ///
  /// In en, this message translates to:
  /// **'My Builds'**
  String get myBuilds;

  /// No description provided for @takeQuiz.
  ///
  /// In en, this message translates to:
  /// **'Take Quiz'**
  String get takeQuiz;

  /// No description provided for @startBuild.
  ///
  /// In en, this message translates to:
  /// **'Start Build'**
  String get startBuild;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @addToBuild.
  ///
  /// In en, this message translates to:
  /// **'Add to Build'**
  String get addToBuild;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @newText.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newText;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort By'**
  String get sortBy;

  /// No description provided for @latest.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get latest;

  /// No description provided for @popular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get popular;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @clearAllFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear All Filters'**
  String get clearAllFilters;

  /// No description provided for @buildsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{build} other{builds}}'**
  String buildsCount(num count);

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @explore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get explore;

  /// No description provided for @parts.
  ///
  /// In en, this message translates to:
  /// **'Parts'**
  String get parts;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back!'**
  String get welcomeBack;

  /// No description provided for @pcBuildingPlatform.
  ///
  /// In en, this message translates to:
  /// **'PC Building Platform'**
  String get pcBuildingPlatform;

  /// No description provided for @buildNow.
  ///
  /// In en, this message translates to:
  /// **'Build Now'**
  String get buildNow;

  /// No description provided for @openInBuilder.
  ///
  /// In en, this message translates to:
  /// **'Open in Builder'**
  String get openInBuilder;

  /// No description provided for @guides.
  ///
  /// In en, this message translates to:
  /// **'Guides'**
  String get guides;

  /// No description provided for @forums.
  ///
  /// In en, this message translates to:
  /// **'Forums'**
  String get forums;

  /// No description provided for @adminPanel.
  ///
  /// In en, this message translates to:
  /// **'Admin Panel'**
  String get adminPanel;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @viewProfile.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get viewProfile;

  /// No description provided for @cpu.
  ///
  /// In en, this message translates to:
  /// **'CPU'**
  String get cpu;

  /// No description provided for @gpu.
  ///
  /// In en, this message translates to:
  /// **'GPU'**
  String get gpu;

  /// No description provided for @motherboard.
  ///
  /// In en, this message translates to:
  /// **'Motherboard'**
  String get motherboard;

  /// No description provided for @memoryRam.
  ///
  /// In en, this message translates to:
  /// **'Memory (RAM)'**
  String get memoryRam;

  /// No description provided for @storage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storage;

  /// No description provided for @powerSupply.
  ///
  /// In en, this message translates to:
  /// **'Power Supply'**
  String get powerSupply;

  /// No description provided for @cooler.
  ///
  /// In en, this message translates to:
  /// **'Cooler'**
  String get cooler;

  /// No description provided for @caseFan.
  ///
  /// In en, this message translates to:
  /// **'Case Fan'**
  String get caseFan;

  /// No description provided for @pcCase.
  ///
  /// In en, this message translates to:
  /// **'Case'**
  String get pcCase;

  /// No description provided for @monitor.
  ///
  /// In en, this message translates to:
  /// **'Monitor'**
  String get monitor;

  /// No description provided for @saveBuild.
  ///
  /// In en, this message translates to:
  /// **'Save Build'**
  String get saveBuild;

  /// No description provided for @buildName.
  ///
  /// In en, this message translates to:
  /// **'Build Name'**
  String get buildName;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description (Optional)'**
  String get description;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags (Optional)'**
  String get tags;

  /// No description provided for @noTagsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No tags available'**
  String get noTagsAvailable;

  /// No description provided for @errorLoadingTags.
  ///
  /// In en, this message translates to:
  /// **'Error loading tags'**
  String get errorLoadingTags;

  /// No description provided for @buildSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Build saved successfully!'**
  String get buildSavedSuccessfully;

  /// No description provided for @failedToSaveBuild.
  ///
  /// In en, this message translates to:
  /// **'Failed to save build'**
  String get failedToSaveBuild;

  /// No description provided for @startNewBuild.
  ///
  /// In en, this message translates to:
  /// **'Start New Build?'**
  String get startNewBuild;

  /// No description provided for @unsavedChanges.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Are you sure you want to clear the current build?'**
  String get unsavedChanges;

  /// No description provided for @clearBuild.
  ///
  /// In en, this message translates to:
  /// **'Clear Build'**
  String get clearBuild;

  /// No description provided for @postBuild.
  ///
  /// In en, this message translates to:
  /// **'Post Build'**
  String get postBuild;

  /// No description provided for @enterBuildName.
  ///
  /// In en, this message translates to:
  /// **'Enter a name for your build'**
  String get enterBuildName;

  /// No description provided for @describeBuild.
  ///
  /// In en, this message translates to:
  /// **'Describe your build...'**
  String get describeBuild;

  /// No description provided for @pleaseEnterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name'**
  String get pleaseEnterName;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @any.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get any;

  /// No description provided for @noGuidesFound.
  ///
  /// In en, this message translates to:
  /// **'No guides found in this category'**
  String get noGuidesFound;

  /// No description provided for @guidesTitle.
  ///
  /// In en, this message translates to:
  /// **'PC Building Guides'**
  String get guidesTitle;

  /// No description provided for @guidesDescription.
  ///
  /// In en, this message translates to:
  /// **'Learn from expert guides and tutorials'**
  String get guidesDescription;

  /// No description provided for @newest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get newest;

  /// No description provided for @oldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get oldest;

  /// No description provided for @troubleshooting.
  ///
  /// In en, this message translates to:
  /// **'Troubleshooting'**
  String get troubleshooting;

  /// No description provided for @buildAdvice.
  ///
  /// In en, this message translates to:
  /// **'Build Advice'**
  String get buildAdvice;

  /// No description provided for @showOffBuild.
  ///
  /// In en, this message translates to:
  /// **'Show Off Your Build'**
  String get showOffBuild;

  /// No description provided for @startDiscussion.
  ///
  /// In en, this message translates to:
  /// **'Start Discussion'**
  String get startDiscussion;

  /// No description provided for @noPostsFound.
  ///
  /// In en, this message translates to:
  /// **'No posts found'**
  String get noPostsFound;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @searchPosts.
  ///
  /// In en, this message translates to:
  /// **'Search posts...'**
  String get searchPosts;

  /// No description provided for @frequentlyAskedQuestions.
  ///
  /// In en, this message translates to:
  /// **'Frequently Asked Questions'**
  String get frequentlyAskedQuestions;

  /// No description provided for @findAnswersToCommonQuestions.
  ///
  /// In en, this message translates to:
  /// **'Find answers to common questions about KAZABUILD'**
  String get findAnswersToCommonQuestions;

  /// No description provided for @whatIsKazabuild.
  ///
  /// In en, this message translates to:
  /// **'What is KAZABUILD?'**
  String get whatIsKazabuild;

  /// No description provided for @whatIsKazabuildAnswer.
  ///
  /// In en, this message translates to:
  /// **'KAZABUILD is a comprehensive PC building platform where enthusiasts can create, share, and explore custom PC builds. Whether you\'re a beginner or an expert, KAZABUILD helps you design the perfect PC configuration, get expert advice, and connect with the PC building community.'**
  String get whatIsKazabuildAnswer;

  /// No description provided for @howDoICreateABuild.
  ///
  /// In en, this message translates to:
  /// **'How do I create a PC build?'**
  String get howDoICreateABuild;

  /// No description provided for @howDoICreateABuildAnswer.
  ///
  /// In en, this message translates to:
  /// **'Creating a PC build is easy! Click on \"Build Now\" from the navigation menu, and you\'ll be guided through our interactive build wizard. You can select components from various categories like CPU, GPU, RAM, storage, and more. Our system will help you check compatibility and suggest optimal configurations based on your needs and budget.'**
  String get howDoICreateABuildAnswer;

  /// No description provided for @arePricesUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Are the component prices up to date?'**
  String get arePricesUpToDate;

  /// No description provided for @arePricesUpToDateAnswer.
  ///
  /// In en, this message translates to:
  /// **'We strive to keep our component database and pricing as up-to-date as possible. However, prices can fluctuate frequently in the market. We recommend checking the latest prices from official retailers before making a purchase. Our platform provides a good estimate to help you plan your budget.'**
  String get arePricesUpToDateAnswer;

  /// No description provided for @canIShareMyBuilds.
  ///
  /// In en, this message translates to:
  /// **'Can I share my builds with others?'**
  String get canIShareMyBuilds;

  /// No description provided for @canIShareMyBuildsAnswer.
  ///
  /// In en, this message translates to:
  /// **'Absolutely! KAZABUILD is designed to be a social platform. You can share your builds with the community, get feedback, and inspire others. You can also explore builds created by other users, save your favorites, and learn from different configurations.'**
  String get canIShareMyBuildsAnswer;

  /// No description provided for @howDoICheckCompatibility.
  ///
  /// In en, this message translates to:
  /// **'How do I check component compatibility?'**
  String get howDoICheckCompatibility;

  /// No description provided for @howDoICheckCompatibilityAnswer.
  ///
  /// In en, this message translates to:
  /// **'Our build wizard automatically checks component compatibility as you select parts. The system validates factors like socket compatibility, power supply requirements, case size, and more. If there are any compatibility issues, you\'ll be notified with suggestions for compatible alternatives.'**
  String get howDoICheckCompatibilityAnswer;

  /// No description provided for @isKazabuildFree.
  ///
  /// In en, this message translates to:
  /// **'Is KAZABUILD free to use?'**
  String get isKazabuildFree;

  /// No description provided for @isKazabuildFreeAnswer.
  ///
  /// In en, this message translates to:
  /// **'Yes! KAZABUILD is completely free to use. You can create unlimited builds, browse the community, participate in forums, and access all our guides and resources without any cost. Simply create an account to get started and unlock additional features like saving your builds and joining discussions.'**
  String get isKazabuildFreeAnswer;

  /// No description provided for @howCanIGetHelp.
  ///
  /// In en, this message translates to:
  /// **'How can I get help with my build?'**
  String get howCanIGetHelp;

  /// No description provided for @howCanIGetHelpAnswer.
  ///
  /// In en, this message translates to:
  /// **'There are several ways to get help on KAZABUILD. You can post questions in our forums, where experienced builders and enthusiasts will be happy to help. You can also browse our comprehensive guides section for tutorials and tips. Additionally, you can comment on similar builds in the community to get specific advice.'**
  String get howCanIGetHelpAnswer;

  /// No description provided for @canISaveMultipleBuilds.
  ///
  /// In en, this message translates to:
  /// **'Can I save multiple builds?'**
  String get canISaveMultipleBuilds;

  /// No description provided for @canISaveMultipleBuildsAnswer.
  ///
  /// In en, this message translates to:
  /// **'Yes! Once you create an account, you can save multiple builds and access them anytime. This is perfect for planning different builds for various purposes like gaming, content creation, or workstation setups. You can also edit, duplicate, and share your saved builds.'**
  String get canISaveMultipleBuildsAnswer;

  /// No description provided for @links.
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get links;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @aboutUs.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get aboutUs;

  /// No description provided for @contactFeedback.
  ///
  /// In en, this message translates to:
  /// **'Contact & Feedback'**
  String get contactFeedback;

  /// No description provided for @copyright.
  ///
  /// In en, this message translates to:
  /// **'© KAZA BUILD'**
  String get copyright;

  /// No description provided for @builds.
  ///
  /// In en, this message translates to:
  /// **'Builds'**
  String get builds;

  /// No description provided for @pcPartsCategories.
  ///
  /// In en, this message translates to:
  /// **'PC Parts Categories'**
  String get pcPartsCategories;

  /// No description provided for @chooseCategoryToBrowse.
  ///
  /// In en, this message translates to:
  /// **'Choose a category to browse available PC components'**
  String get chooseCategoryToBrowse;

  /// No description provided for @errorLoadingParts.
  ///
  /// In en, this message translates to:
  /// **'Error loading parts'**
  String get errorLoadingParts;

  /// No description provided for @itemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{item} other{items}}'**
  String itemsCount(num count);

  /// No description provided for @priceNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Price N/A'**
  String get priceNotAvailable;

  /// No description provided for @manageAccountSettings.
  ///
  /// In en, this message translates to:
  /// **'Manage your account settings and preferences'**
  String get manageAccountSettings;

  /// No description provided for @profilePicture.
  ///
  /// In en, this message translates to:
  /// **'Profile Picture'**
  String get profilePicture;

  /// No description provided for @profileInformation.
  ///
  /// In en, this message translates to:
  /// **'Profile Information'**
  String get profileInformation;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get displayName;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @usernameCannotBeChanged.
  ///
  /// In en, this message translates to:
  /// **'Username cannot be changed'**
  String get usernameCannotBeChanged;

  /// No description provided for @bio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @privacySecurity.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Security'**
  String get privacySecurity;

  /// No description provided for @profilePrivacy.
  ///
  /// In en, this message translates to:
  /// **'Profile Privacy'**
  String get profilePrivacy;

  /// No description provided for @private.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get private;

  /// No description provided for @public.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get public;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @updateAccountPassword.
  ///
  /// In en, this message translates to:
  /// **'Update your account password'**
  String get updateAccountPassword;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @supportedFormats.
  ///
  /// In en, this message translates to:
  /// **'Supported formats: JPG, JPEG, PNG, GIF, WEBP, AVIF, BMP, TIFF, HEIC, ICO. Max size: 25MB.'**
  String get supportedFormats;

  /// No description provided for @profilePictureUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile picture updated successfully!'**
  String get profilePictureUpdated;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully!'**
  String get profileUpdated;

  /// No description provided for @updateFailed.
  ///
  /// In en, this message translates to:
  /// **'Update failed'**
  String get updateFailed;

  /// No description provided for @failedToUpload.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload'**
  String get failedToUpload;

  /// No description provided for @editAddress.
  ///
  /// In en, this message translates to:
  /// **'Edit Address'**
  String get editAddress;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @provinceState.
  ///
  /// In en, this message translates to:
  /// **'Province / State'**
  String get provinceState;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @street.
  ///
  /// In en, this message translates to:
  /// **'Street'**
  String get street;

  /// No description provided for @number.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get number;

  /// No description provided for @postalCode.
  ///
  /// In en, this message translates to:
  /// **'Postal Code'**
  String get postalCode;

  /// No description provided for @apartmentOptional.
  ///
  /// In en, this message translates to:
  /// **'Apartment (Optional)'**
  String get apartmentOptional;

  /// No description provided for @displayNameMustBeAtLeast4.
  ///
  /// In en, this message translates to:
  /// **'Display name must be at least 4 characters'**
  String get displayNameMustBeAtLeast4;

  /// No description provided for @enterDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Enter Display Name'**
  String get enterDisplayName;

  /// No description provided for @enterBio.
  ///
  /// In en, this message translates to:
  /// **'Enter Bio'**
  String get enterBio;

  /// No description provided for @enterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter Phone Number'**
  String get enterPhoneNumber;

  /// No description provided for @manufacturer.
  ///
  /// In en, this message translates to:
  /// **'Manufacturer'**
  String get manufacturer;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @releaseDate.
  ///
  /// In en, this message translates to:
  /// **'Release Date'**
  String get releaseDate;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @noBuildsFound.
  ///
  /// In en, this message translates to:
  /// **'No builds found'**
  String get noBuildsFound;

  /// No description provided for @tryAdjustingFilters.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your filters or check back later'**
  String get tryAdjustingFilters;

  /// No description provided for @errorLoadingBuilds.
  ///
  /// In en, this message translates to:
  /// **'Error loading builds'**
  String get errorLoadingBuilds;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @noImage.
  ///
  /// In en, this message translates to:
  /// **'No Image'**
  String get noImage;

  /// No description provided for @clickToViewComponents.
  ///
  /// In en, this message translates to:
  /// **'Click to view components'**
  String get clickToViewComponents;

  /// No description provided for @components.
  ///
  /// In en, this message translates to:
  /// **'Components'**
  String get components;

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @noImageAvailable.
  ///
  /// In en, this message translates to:
  /// **'No Image Available'**
  String get noImageAvailable;

  /// No description provided for @postedOn.
  ///
  /// In en, this message translates to:
  /// **'Posted on'**
  String get postedOn;

  /// No description provided for @wishlistBuild.
  ///
  /// In en, this message translates to:
  /// **'Wishlist Build'**
  String get wishlistBuild;

  /// No description provided for @noComponentsListed.
  ///
  /// In en, this message translates to:
  /// **'No components listed'**
  String get noComponentsListed;

  /// No description provided for @fromVendors.
  ///
  /// In en, this message translates to:
  /// **'from {count} {count, plural, =1{vendor} other{vendors}}'**
  String fromVendors(num count);

  /// No description provided for @signInToComment.
  ///
  /// In en, this message translates to:
  /// **'Sign in to comment on this build'**
  String get signInToComment;

  /// No description provided for @pleaseSignInToComment.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to comment. Use the navigation to go to login.'**
  String get pleaseSignInToComment;

  /// No description provided for @writeComment.
  ///
  /// In en, this message translates to:
  /// **'Write a comment...'**
  String get writeComment;

  /// No description provided for @post.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get post;

  /// No description provided for @pleaseSignInToCommentShort.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to comment'**
  String get pleaseSignInToCommentShort;

  /// No description provided for @failedToLoadComments.
  ///
  /// In en, this message translates to:
  /// **'Failed to load comments'**
  String get failedToLoadComments;

  /// No description provided for @noCommentsYet.
  ///
  /// In en, this message translates to:
  /// **'No comments yet. Be the first to comment!'**
  String get noCommentsYet;

  /// No description provided for @pleaseSignInToRate.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to rate this build.'**
  String get pleaseSignInToRate;

  /// No description provided for @pleaseSignInToRateBuilds.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to rate builds'**
  String get pleaseSignInToRateBuilds;

  /// No description provided for @failedToSubmitRating.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit rating'**
  String get failedToSubmitRating;

  /// No description provided for @removeRating.
  ///
  /// In en, this message translates to:
  /// **'Remove rating'**
  String get removeRating;

  /// No description provided for @rate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get rate;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @vendors.
  ///
  /// In en, this message translates to:
  /// **'Vendors'**
  String get vendors;

  /// No description provided for @similarBuilds.
  ///
  /// In en, this message translates to:
  /// **'Similar Builds'**
  String get similarBuilds;

  /// No description provided for @series.
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get series;

  /// No description provided for @socket.
  ///
  /// In en, this message translates to:
  /// **'Socket'**
  String get socket;

  /// No description provided for @chipset.
  ///
  /// In en, this message translates to:
  /// **'Chipset'**
  String get chipset;

  /// No description provided for @formFactor.
  ///
  /// In en, this message translates to:
  /// **'Form Factor'**
  String get formFactor;

  /// No description provided for @memoryType.
  ///
  /// In en, this message translates to:
  /// **'Memory Type'**
  String get memoryType;

  /// No description provided for @ramType.
  ///
  /// In en, this message translates to:
  /// **'RAM Type'**
  String get ramType;

  /// No description provided for @capacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get capacity;

  /// No description provided for @speed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get speed;

  /// No description provided for @tdp.
  ///
  /// In en, this message translates to:
  /// **'TDP'**
  String get tdp;

  /// No description provided for @length.
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get length;

  /// No description provided for @height.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get height;

  /// No description provided for @baseClock.
  ///
  /// In en, this message translates to:
  /// **'Base Clock'**
  String get baseClock;

  /// No description provided for @boostClock.
  ///
  /// In en, this message translates to:
  /// **'Boost Clock'**
  String get boostClock;

  /// No description provided for @coreCount.
  ///
  /// In en, this message translates to:
  /// **'Core Count'**
  String get coreCount;

  /// No description provided for @threads.
  ///
  /// In en, this message translates to:
  /// **'Threads'**
  String get threads;

  /// No description provided for @vram.
  ///
  /// In en, this message translates to:
  /// **'VRAM'**
  String get vram;

  /// No description provided for @microarchitecture.
  ///
  /// In en, this message translates to:
  /// **'Microarchitecture'**
  String get microarchitecture;

  /// No description provided for @coreFamily.
  ///
  /// In en, this message translates to:
  /// **'Core Family'**
  String get coreFamily;

  /// No description provided for @totalCores.
  ///
  /// In en, this message translates to:
  /// **'Total Cores'**
  String get totalCores;

  /// No description provided for @pCores.
  ///
  /// In en, this message translates to:
  /// **'P-Cores'**
  String get pCores;

  /// No description provided for @eCores.
  ///
  /// In en, this message translates to:
  /// **'E-Cores'**
  String get eCores;

  /// No description provided for @l1Cache.
  ///
  /// In en, this message translates to:
  /// **'L1 Cache'**
  String get l1Cache;

  /// No description provided for @l2Cache.
  ///
  /// In en, this message translates to:
  /// **'L2 Cache'**
  String get l2Cache;

  /// No description provided for @l3Cache.
  ///
  /// In en, this message translates to:
  /// **'L3 Cache'**
  String get l3Cache;

  /// No description provided for @l4Cache.
  ///
  /// In en, this message translates to:
  /// **'L4 Cache'**
  String get l4Cache;

  /// No description provided for @lithography.
  ///
  /// In en, this message translates to:
  /// **'Lithography'**
  String get lithography;

  /// No description provided for @packaging.
  ///
  /// In en, this message translates to:
  /// **'Packaging'**
  String get packaging;

  /// No description provided for @includesCooler.
  ///
  /// In en, this message translates to:
  /// **'Includes Cooler'**
  String get includesCooler;

  /// No description provided for @smtSupport.
  ///
  /// In en, this message translates to:
  /// **'SMT Support'**
  String get smtSupport;

  /// No description provided for @eccSupport.
  ///
  /// In en, this message translates to:
  /// **'ECC Support'**
  String get eccSupport;

  /// No description provided for @integratedGraphics.
  ///
  /// In en, this message translates to:
  /// **'Integrated Graphics'**
  String get integratedGraphics;

  /// No description provided for @memoryClock.
  ///
  /// In en, this message translates to:
  /// **'Memory Clock'**
  String get memoryClock;

  /// No description provided for @memoryBusWidth.
  ///
  /// In en, this message translates to:
  /// **'Memory Bus Width'**
  String get memoryBusWidth;

  /// No description provided for @slotWidth.
  ///
  /// In en, this message translates to:
  /// **'Slot Width'**
  String get slotWidth;

  /// No description provided for @totalSlots.
  ///
  /// In en, this message translates to:
  /// **'Total Slots'**
  String get totalSlots;

  /// No description provided for @coolingType.
  ///
  /// In en, this message translates to:
  /// **'Cooling Type'**
  String get coolingType;

  /// No description provided for @frameSync.
  ///
  /// In en, this message translates to:
  /// **'Frame Sync'**
  String get frameSync;

  /// No description provided for @ramSlots.
  ///
  /// In en, this message translates to:
  /// **'RAM Slots'**
  String get ramSlots;

  /// No description provided for @maxRam.
  ///
  /// In en, this message translates to:
  /// **'Max RAM'**
  String get maxRam;

  /// No description provided for @cpuFanHeaders.
  ///
  /// In en, this message translates to:
  /// **'CPU Fan Headers'**
  String get cpuFanHeaders;

  /// No description provided for @caseFanHeaders.
  ///
  /// In en, this message translates to:
  /// **'Case Fan Headers'**
  String get caseFanHeaders;

  /// No description provided for @pumpHeaders.
  ///
  /// In en, this message translates to:
  /// **'Pump Headers'**
  String get pumpHeaders;

  /// No description provided for @audioChipset.
  ///
  /// In en, this message translates to:
  /// **'Audio Chipset'**
  String get audioChipset;

  /// No description provided for @maxAudioChannels.
  ///
  /// In en, this message translates to:
  /// **'Max Audio Channels'**
  String get maxAudioChannels;

  /// No description provided for @raidSupport.
  ///
  /// In en, this message translates to:
  /// **'RAID Support'**
  String get raidSupport;

  /// No description provided for @biosFlashback.
  ///
  /// In en, this message translates to:
  /// **'BIOS Flashback'**
  String get biosFlashback;

  /// No description provided for @clearCmos.
  ///
  /// In en, this message translates to:
  /// **'Clear CMOS'**
  String get clearCmos;

  /// No description provided for @casLatency.
  ///
  /// In en, this message translates to:
  /// **'CAS Latency'**
  String get casLatency;

  /// No description provided for @timings.
  ///
  /// In en, this message translates to:
  /// **'Timings'**
  String get timings;

  /// No description provided for @modules.
  ///
  /// In en, this message translates to:
  /// **'Modules'**
  String get modules;

  /// No description provided for @moduleCapacity.
  ///
  /// In en, this message translates to:
  /// **'Module Capacity'**
  String get moduleCapacity;

  /// No description provided for @ecc.
  ///
  /// In en, this message translates to:
  /// **'ECC'**
  String get ecc;

  /// No description provided for @registered.
  ///
  /// In en, this message translates to:
  /// **'Registered'**
  String get registered;

  /// No description provided for @heatSpreader.
  ///
  /// In en, this message translates to:
  /// **'Heat Spreader'**
  String get heatSpreader;

  /// No description provided for @rgb.
  ///
  /// In en, this message translates to:
  /// **'RGB'**
  String get rgb;

  /// No description provided for @voltage.
  ///
  /// In en, this message translates to:
  /// **'Voltage'**
  String get voltage;

  /// No description provided for @interface.
  ///
  /// In en, this message translates to:
  /// **'Interface'**
  String get interface;

  /// No description provided for @nvme.
  ///
  /// In en, this message translates to:
  /// **'NVMe'**
  String get nvme;

  /// No description provided for @wattage.
  ///
  /// In en, this message translates to:
  /// **'Wattage'**
  String get wattage;

  /// No description provided for @efficiency.
  ///
  /// In en, this message translates to:
  /// **'Efficiency'**
  String get efficiency;

  /// No description provided for @modularity.
  ///
  /// In en, this message translates to:
  /// **'Modularity'**
  String get modularity;

  /// No description provided for @fanless.
  ///
  /// In en, this message translates to:
  /// **'Fanless'**
  String get fanless;

  /// No description provided for @radiatorSize.
  ///
  /// In en, this message translates to:
  /// **'Radiator Size'**
  String get radiatorSize;

  /// No description provided for @fanSize.
  ///
  /// In en, this message translates to:
  /// **'Fan Size'**
  String get fanSize;

  /// No description provided for @fanQuantity.
  ///
  /// In en, this message translates to:
  /// **'Fan Quantity'**
  String get fanQuantity;

  /// No description provided for @minFanSpeed.
  ///
  /// In en, this message translates to:
  /// **'Min Fan Speed'**
  String get minFanSpeed;

  /// No description provided for @maxFanSpeed.
  ///
  /// In en, this message translates to:
  /// **'Max Fan Speed'**
  String get maxFanSpeed;

  /// No description provided for @minNoise.
  ///
  /// In en, this message translates to:
  /// **'Min Noise'**
  String get minNoise;

  /// No description provided for @maxNoise.
  ///
  /// In en, this message translates to:
  /// **'Max Noise'**
  String get maxNoise;

  /// No description provided for @fanlessOperation.
  ///
  /// In en, this message translates to:
  /// **'Fanless Operation'**
  String get fanlessOperation;

  /// No description provided for @size.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get size;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @minAirflow.
  ///
  /// In en, this message translates to:
  /// **'Min Airflow'**
  String get minAirflow;

  /// No description provided for @maxAirflow.
  ///
  /// In en, this message translates to:
  /// **'Max Airflow'**
  String get maxAirflow;

  /// No description provided for @pwm.
  ///
  /// In en, this message translates to:
  /// **'PWM'**
  String get pwm;

  /// No description provided for @ledType.
  ///
  /// In en, this message translates to:
  /// **'LED Type'**
  String get ledType;

  /// No description provided for @connector.
  ///
  /// In en, this message translates to:
  /// **'Connector'**
  String get connector;

  /// No description provided for @controller.
  ///
  /// In en, this message translates to:
  /// **'Controller'**
  String get controller;

  /// No description provided for @staticPressure.
  ///
  /// In en, this message translates to:
  /// **'Static Pressure'**
  String get staticPressure;

  /// No description provided for @flowDirection.
  ///
  /// In en, this message translates to:
  /// **'Flow Direction'**
  String get flowDirection;

  /// No description provided for @powerSupplyShrouded.
  ///
  /// In en, this message translates to:
  /// **'Power Supply Shrouded'**
  String get powerSupplyShrouded;

  /// No description provided for @includedPsu.
  ///
  /// In en, this message translates to:
  /// **'Included PSU'**
  String get includedPsu;

  /// No description provided for @transparentSidePanel.
  ///
  /// In en, this message translates to:
  /// **'Transparent Side Panel'**
  String get transparentSidePanel;

  /// No description provided for @sidePanelType.
  ///
  /// In en, this message translates to:
  /// **'Side Panel Type'**
  String get sidePanelType;

  /// No description provided for @maxGpuLength.
  ///
  /// In en, this message translates to:
  /// **'Max GPU Length'**
  String get maxGpuLength;

  /// No description provided for @maxCpuCoolerHeight.
  ///
  /// In en, this message translates to:
  /// **'Max CPU Cooler Height'**
  String get maxCpuCoolerHeight;

  /// No description provided for @screenSize.
  ///
  /// In en, this message translates to:
  /// **'Screen Size'**
  String get screenSize;

  /// No description provided for @resolution.
  ///
  /// In en, this message translates to:
  /// **'Resolution'**
  String get resolution;

  /// No description provided for @refreshRate.
  ///
  /// In en, this message translates to:
  /// **'Refresh Rate'**
  String get refreshRate;

  /// No description provided for @panelType.
  ///
  /// In en, this message translates to:
  /// **'Panel Type'**
  String get panelType;

  /// No description provided for @responseTime.
  ///
  /// In en, this message translates to:
  /// **'Response Time'**
  String get responseTime;

  /// No description provided for @viewingAngle.
  ///
  /// In en, this message translates to:
  /// **'Viewing Angle'**
  String get viewingAngle;

  /// No description provided for @aspectRatio.
  ///
  /// In en, this message translates to:
  /// **'Aspect Ratio'**
  String get aspectRatio;

  /// No description provided for @maxBrightness.
  ///
  /// In en, this message translates to:
  /// **'Max Brightness'**
  String get maxBrightness;

  /// No description provided for @hdr.
  ///
  /// In en, this message translates to:
  /// **'HDR'**
  String get hdr;

  /// No description provided for @adaptiveSync.
  ///
  /// In en, this message translates to:
  /// **'Adaptive Sync'**
  String get adaptiveSync;

  /// No description provided for @sata6Gbs.
  ///
  /// In en, this message translates to:
  /// **'SATA 6 Gb/s'**
  String get sata6Gbs;

  /// No description provided for @sata3Gbs.
  ///
  /// In en, this message translates to:
  /// **'SATA 3 Gb/s'**
  String get sata3Gbs;

  /// No description provided for @u2Ports.
  ///
  /// In en, this message translates to:
  /// **'U.2 Ports'**
  String get u2Ports;

  /// No description provided for @wifi.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi'**
  String get wifi;

  /// No description provided for @argb5vHeaders.
  ///
  /// In en, this message translates to:
  /// **'ARGB 5V Headers'**
  String get argb5vHeaders;

  /// No description provided for @rgb12vHeaders.
  ///
  /// In en, this message translates to:
  /// **'RGB 12V Headers'**
  String get rgb12vHeaders;

  /// No description provided for @internal35BayAmount.
  ///
  /// In en, this message translates to:
  /// **'3.5\" Bays'**
  String get internal35BayAmount;

  /// No description provided for @internal25BayAmount.
  ///
  /// In en, this message translates to:
  /// **'2.5\" Bays'**
  String get internal25BayAmount;

  /// No description provided for @external525BayAmount.
  ///
  /// In en, this message translates to:
  /// **'5.25\" Bays'**
  String get external525BayAmount;

  /// No description provided for @external35BayAmount.
  ///
  /// In en, this message translates to:
  /// **'3.5\" External Bays'**
  String get external35BayAmount;

  /// No description provided for @waterCooled.
  ///
  /// In en, this message translates to:
  /// **'Water Cooled'**
  String get waterCooled;

  /// No description provided for @airCooled.
  ///
  /// In en, this message translates to:
  /// **'Air Cooled'**
  String get airCooled;

  /// No description provided for @heroTitle.
  ///
  /// In en, this message translates to:
  /// **'Not sure where to start?\njust take this short quiz to get started'**
  String get heroTitle;

  /// No description provided for @heroDescription.
  ///
  /// In en, this message translates to:
  /// **'We feature build generations, compatibility, price conversion, community builds, and forum discussions'**
  String get heroDescription;

  /// No description provided for @buildGenerations.
  ///
  /// In en, this message translates to:
  /// **'build generations'**
  String get buildGenerations;

  /// No description provided for @compatibility.
  ///
  /// In en, this message translates to:
  /// **'compatibility'**
  String get compatibility;

  /// No description provided for @priceConversion.
  ///
  /// In en, this message translates to:
  /// **'price conversion'**
  String get priceConversion;

  /// No description provided for @communityBuilds.
  ///
  /// In en, this message translates to:
  /// **'community builds'**
  String get communityBuilds;

  /// No description provided for @forumDiscussions.
  ///
  /// In en, this message translates to:
  /// **'forum discussions'**
  String get forumDiscussions;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'KAZABUILD'**
  String get appName;

  /// No description provided for @unread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get unread;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @messagesDescription.
  ///
  /// In en, this message translates to:
  /// **'Connect and communicate with other users.'**
  String get messagesDescription;

  /// No description provided for @searchNotifications.
  ///
  /// In en, this message translates to:
  /// **'Search notifications...'**
  String get searchNotifications;

  /// No description provided for @searchMessages.
  ///
  /// In en, this message translates to:
  /// **'Search messages...'**
  String get searchMessages;

  /// No description provided for @noFeaturedBuilds.
  ///
  /// In en, this message translates to:
  /// **'No featured builds selected yet'**
  String get noFeaturedBuilds;

  /// No description provided for @featuredBuilds.
  ///
  /// In en, this message translates to:
  /// **'Featured Builds'**
  String get featuredBuilds;

  /// No description provided for @couldNotLoadFeaturedBuilds.
  ///
  /// In en, this message translates to:
  /// **'Could not load featured builds'**
  String get couldNotLoadFeaturedBuilds;

  /// No description provided for @pcBuilder.
  ///
  /// In en, this message translates to:
  /// **'PC Builder'**
  String get pcBuilder;

  /// No description provided for @configurePcBuild.
  ///
  /// In en, this message translates to:
  /// **'Configure your custom PC build with compatibility checking.'**
  String get configurePcBuild;

  /// No description provided for @buildSuccessfullySaved.
  ///
  /// In en, this message translates to:
  /// **'Build successfully saved to your profile'**
  String get buildSuccessfullySaved;

  /// No description provided for @replies.
  ///
  /// In en, this message translates to:
  /// **'Replies'**
  String get replies;

  /// No description provided for @noRepliesYet.
  ///
  /// In en, this message translates to:
  /// **'No replies yet. Be the first!'**
  String get noRepliesYet;

  /// No description provided for @signInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue your journey'**
  String get signInToContinue;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pl', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pl':
      return AppLocalizationsPl();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
