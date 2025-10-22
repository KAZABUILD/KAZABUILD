# KazaBuild Frontend

A comprehensive Flutter application for PC building, component selection, and community interaction. This frontend provides an intuitive interface for users to build custom PCs, explore components, participate in forums, and access educational content.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## How to run
 - `cd frontend` in the terminal to access the project
 - `flutter pub get` to get packages
 - `flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:5000` to run chrome website
 - `flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:5000` to run android emulator app
 - `flutter build web --release --dart-define=API_BASE_URL=https://api.yourdomain.com` to run production version

## Flutter Packages:
- `dio` - HTTP client for API communication
- `flutter_riverpod` - State management solution
- `flutter_dotenv` - Environment variable management
- `json_annotation` - JSON serialization annotations
- `build_runner` - Code generation
- `json_serializable` - JSON serialization code generation

## Features

### Core Features
- **PC Builder**: Interactive component selection and compatibility checking
- **Component Explorer**: Browse and filter PC components by category
- **Community Forums**: Discussion platform for PC building topics
- **Educational Guides**: Comprehensive guides for PC building
- **Interactive Quiz**: Personalized PC recommendations based on user needs
- **User Authentication**: Secure login/signup with social media integration
- **Multi-language Support**: English, Polish, and Turkish localization
- **Responsive Design**: Optimized for desktop and mobile devices
- **Dark/Light Theme**: Dynamic theme switching

## Pages

### Authentication Pages
- **LoginPage** (`screens/auth/login_page.dart`): User authentication with email/password and social login options (Google, GitHub, Discord)
- **SignUpPage** (`screens/auth/signup_page.dart`): New user registration with form validation
- **ForgotPasswordPage** (`screens/auth/forgot_password_page.dart`): Password recovery functionality
- **PrivacyPolicyDialog** (`screens/auth/privacy_policy_dialog.dart`): Privacy policy acceptance dialog

### Main Application Pages
- **HomePage** (`screens/home/homepage.dart`): Landing page with featured builds, part categories, and FAQ section
- **BuildNowPage** (`screens/builder/build_now_page.dart`): Interactive PC builder with component selection
- **PartPickerPage** (`screens/parts/part_picker_page.dart`): Component selection interface with filtering and search
- **ExploreBuildsPage** (`screens/explore_build/explore_builds_page.dart`): Browse community builds and featured configurations
- **BuildDetailPage** (`screens/explore_build/build_detail_page.dart`): Detailed view of specific PC builds

### Community Pages
- **ForumsPage** (`screens/forum/forums_page.dart`): Community discussion forum with post filtering and search
- **NewPostPage** (`screens/forum/new_post_page.dart`): Create new forum posts
- **PostDetailPage** (`screens/forum/post_detail_page.dart`): View and interact with individual forum posts

### Informative Pages
- **GuidesPage** (`screens/guides/guides_page.dart`): Browse educational guides and tutorials
- **GuideDetailPage** (`screens/guides/guide_detail_page.dart`): Detailed guide content with step-by-step instructions
- **QuizPage** (`screens/quiz/quiz_page.dart`): Interactive quiz for personalized PC recommendations

### User Profile Pages
- **ProfilePage** (`screens/profile/profile_page.dart`): User profile management and build history
- **SettingsPage** (`screens/profile/settings_page.dart`): User preferences and account settings

### General Pages
- **AboutUsPage** (`screens/info/aboutus_page.dart`): Company information and team details
- **FeedbackPage** (`screens/info/feedback_page.dart`): User feedback submission form

### Admin Pages
- **AdminDashboard** (`screens/admin/admin_dashboard.dart`): Administrative interface for content management

### Utility Pages
- **SplashScreen** (`screens/extra/spalsh_page.dart`): Application startup screen

## Widgets

### Navigation Widgets
- **CustomNavigationBar** (`widgets/navigation_bar.dart`): Responsive navigation bar with desktop/mobile layouts
- **CustomDrawer** (`widgets/navigation_bar.dart`): Mobile navigation drawer with user profile integration
- **AppBarActions** (`widgets/app_bar_actions.dart`): App bar action buttons and controls

### UI Component Widgets
- **CustomStartButton** (`widgets/custom_buttons.dart`): Styled call-to-action buttons
- **CustomInputs** (`widgets/custom_inputs.dart`): Custom form input components
- **Cards** (`widgets/cards.dart`): Reusable card components for content display
- **Alerts** (`widgets/alerts.dart`): Alert and notification components

### Specialized Widgets
- **FilterPanelWidget** (`widgets/filter_panel_widget.dart`): Advanced filtering interface for component selection
- **PartCategories** (`widgets/part_categories.dart`): PC component category display
- **PriceChart** (`widgets/price_chart.dart`): Price tracking and comparison charts
- **QuizResultPage** (`widgets/quiz_result_page.dart`): Quiz results display with recommendations
- **Accordion** (`widgets/acrodion.dart`): Expandable content sections
- **LastBar** (`widgets/last_bar.dart`): Footer component with links and information

### Theme and Localization
- **ThemeProvider** (`widgets/theme_provider.dart`): Theme management and switching
- **LanguageSelector** (`widgets/navigation_bar.dart`): Multi-language support interface

## Models

### Core Data Models
- **ComponentModels** (`models/component_models.dart`): Comprehensive PC component definitions including CPU, GPU, Motherboard, RAM, Storage, PSU, Cooler, Case, Monitor
- **UserModel** (`models/user_model.dart`): User account and profile data
- **BuildModel** (`models/build_model.dart`): PC build configurations and specifications
- **PostModel** (`models/post_model.dart`): Forum post and discussion data
- **GuideModel** (`models/guide_model.dart`): Educational content and tutorials

### State Management Models
- **AuthProvider** (`models/auth_provider.dart`): Authentication state management
- **CurrencyProvider** (`models/currency_provider.dart`): Currency conversion and pricing
- **QuizProvider** (`models/quiz_provider.dart`): Quiz state and recommendation logic
- **ExploreBuildModel** (`models/explore_build_model.dart`): Community build exploration
- **ForumModel** (`models/forum_model.dart`): Forum and discussion management

### Utility Models
- **Locale** (`models/locale.dart`): Internationalization and localization support

## Architecture

### State Management
- **Riverpod**: Primary state management solution for reactive programming
- **Provider Pattern**: Centralized state management for authentication, theme, and user preferences
- **FutureProvider**: Async data fetching for components and builds

### Responsive Design
- **Mobile Layout**: Optimized for mobile devices with drawer navigation
- **Desktop Layout**: Full navigation bar with dropdown menus
- **Breakpoint**: 1100px breakpoint for responsive behavior

### Internationalization
- **Multi-language Support**: English, Polish, and Turkish
- **Localization Files**: ARB files for translation management
- **Dynamic Language Switching**: Runtime language changes

### Theme System
- **Light/Dark Themes**: Complete theme switching capability
- **Custom Color Schemes**: Brand-specific color palettes
- **Dynamic Theme Switching**: Runtime theme changes with persistence

## Key Features

### PC Building System
- **Component Compatibility**: Real-time compatibility checking between components
- **Build Configuration**: Save and manage multiple PC builds
- **Price Tracking**: Monitor component prices across vendors
- **Specification Display**: Detailed technical specifications for all components

### Community Features
- **Forum System**: Discussion threads with post creation and interaction
- **Build Sharing**: Share and discover community builds
- **User Profiles**: Comprehensive user profile management
- **Social Integration**: Login with Google, GitHub, and Discord

### Educational Content
- **Interactive Quiz**: Personalized PC recommendations
- **Comprehensive Guides**: Step-by-step PC building tutorials
- **FAQ Section**: Common questions and answers

### User Experience
- **Responsive Design**: Seamless experience across all devices
- **Intuitive Navigation**: Easy-to-use interface with clear navigation
- **Search and Filter**: Advanced filtering for components and content
- **Performance Optimized**: Smooth animations and fast loading times