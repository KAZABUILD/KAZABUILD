// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localization.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get language => 'Polski';

  @override
  String get appTitle => 'Kaza Build';

  @override
  String get exploreBuilds => 'Przeglądaj Buildy';

  @override
  String get discoverAmazingBuilds =>
      'Odkrywaj niesamowite buildy PC ze społeczności';

  @override
  String get searchBuilds => 'Szukaj buildów...';

  @override
  String get myBuilds => 'Moje Buildy';

  @override
  String get takeQuiz => 'Rozpocznij Quiz';

  @override
  String get startBuild => 'Rozpocznij Build';

  @override
  String get close => 'Zamknij';

  @override
  String get addToBuild => 'Dodaj do Builda';

  @override
  String get save => 'Zapisz';

  @override
  String get cancel => 'Anuluj';

  @override
  String get newText => 'Nowy';

  @override
  String get filters => 'Filtry';

  @override
  String get sortBy => 'Sortuj';

  @override
  String get latest => 'Najnowsze';

  @override
  String get popular => 'Popularne';

  @override
  String get price => 'Cena';

  @override
  String get clearAllFilters => 'Wyczyść Wszystkie Filtry';

  @override
  String buildsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'buildy',
      one: 'build',
    );
    return '$count $_temp0';
  }

  @override
  String get home => 'Strona Główna';

  @override
  String get explore => 'Przeglądaj';

  @override
  String get parts => 'Części';

  @override
  String get profile => 'Profil';

  @override
  String get settings => 'Ustawienia';

  @override
  String get logout => 'Wyloguj';

  @override
  String get login => 'Zaloguj';

  @override
  String get signUp => 'Zarejestruj się';

  @override
  String get welcomeBack => 'Witaj Ponownie!';

  @override
  String get pcBuildingPlatform => 'Platforma Budowania PC';

  @override
  String get buildNow => 'Utwórz Build';

  @override
  String get guides => 'Przewodniki';

  @override
  String get forums => 'Fora';

  @override
  String get adminPanel => 'Panel Administratora';

  @override
  String get signIn => 'Zaloguj';

  @override
  String get welcome => 'Witaj';

  @override
  String get viewProfile => 'Zobacz Profil';

  @override
  String get cpu => 'Procesor';

  @override
  String get gpu => 'Karta Graficzna';

  @override
  String get motherboard => 'Płyta Główna';

  @override
  String get memoryRam => 'Pamięć (RAM)';

  @override
  String get storage => 'Dysk';

  @override
  String get powerSupply => 'Zasilacz';

  @override
  String get cooler => 'Chłodzenie';

  @override
  String get caseFan => 'Wentylator Obudowy';

  @override
  String get pcCase => 'Obudowa';

  @override
  String get monitor => 'Monitor';

  @override
  String get saveBuild => 'Zapisz Build';

  @override
  String get buildName => 'Nazwa Builda';

  @override
  String get description => 'Opis (Opcjonalnie)';

  @override
  String get tags => 'Tagi (Opcjonalnie)';

  @override
  String get noTagsAvailable => 'Brak dostępnych tagów';

  @override
  String get errorLoadingTags => 'Błąd ładowania tagów';

  @override
  String get buildSavedSuccessfully => 'Build zapisany pomyślnie!';

  @override
  String get failedToSaveBuild => 'Nie udało się zapisać builda';

  @override
  String get startNewBuild => 'Rozpocząć Nowy Build?';

  @override
  String get unsavedChanges =>
      'Masz niezapisane zmiany. Czy na pewno chcesz wyczyścić obecny build?';

  @override
  String get clearBuild => 'Wyczyść Build';

  @override
  String get postBuild => 'Opublikuj Build';

  @override
  String get enterBuildName => 'Wprowadź nazwę dla swojego builda';

  @override
  String get describeBuild => 'Opisz swój build...';

  @override
  String get pleaseEnterName => 'Proszę wprowadzić nazwę';

  @override
  String get all => 'Wszystkie';

  @override
  String get noGuidesFound => 'Nie znaleziono przewodników w tej kategorii';

  @override
  String get guidesTitle => 'Przewodniki Budowania PC';

  @override
  String get guidesDescription =>
      'Ucz się z przewodników i tutoriali ekspertów';

  @override
  String get newest => 'Najnowsze';

  @override
  String get oldest => 'Najstarsze';

  @override
  String get troubleshooting => 'Rozwiązywanie Problemów';

  @override
  String get buildAdvice => 'Porady Budowania';

  @override
  String get showOffBuild => 'Pochwal Się Buildem';

  @override
  String get startDiscussion => 'Rozpocznij Dyskusję';

  @override
  String get noPostsFound => 'Nie znaleziono postów';

  @override
  String get error => 'Błąd';

  @override
  String get searchPosts => 'Szukaj postów...';

  @override
  String get frequentlyAskedQuestions => 'Często Zadawane Pytania';

  @override
  String get findAnswersToCommonQuestions =>
      'Znajdź odpowiedzi na najczęstsze pytania dotyczące KAZABUILD';

  @override
  String get whatIsKazabuild => 'Czym jest KAZABUILD?';

  @override
  String get whatIsKazabuildAnswer =>
      'KAZABUILD to kompleksowa platforma do budowania PC, gdzie entuzjaści mogą tworzyć, udostępniać i odkrywać niestandardowe buildy PC. Niezależnie od tego, czy jesteś początkujący, czy ekspert, KAZABUILD pomaga zaprojektować idealną konfigurację PC, uzyskać fachowe porady i połączyć się ze społecznością budowania PC.';

  @override
  String get howDoICreateABuild => 'Jak utworzyć build PC?';

  @override
  String get howDoICreateABuildAnswer =>
      'Tworzenie builda PC jest łatwe! Kliknij \"Utwórz Build\" w menu nawigacyjnym, a zostaniesz poprowadzony przez naszego interaktywnego kreatora buildów. Możesz wybierać komponenty z różnych kategorii, takich jak CPU, GPU, RAM, pamięć i nie tylko. Nasz system pomoże sprawdzić kompatybilność i zasugeruje optymalne konfiguracje na podstawie Twoich potrzeb i budżetu.';

  @override
  String get arePricesUpToDate => 'Czy ceny komponentów są aktualne?';

  @override
  String get arePricesUpToDateAnswer =>
      'Dążymy do tego, aby nasza baza danych komponentów i ceny były jak najbardziej aktualne. Jednak ceny mogą często się zmieniać na rynku. Zalecamy sprawdzenie najnowszych cen u oficjalnych sprzedawców przed zakupem. Nasza platforma zapewnia dobre oszacowanie, aby pomóc w planowaniu budżetu.';

  @override
  String get canIShareMyBuilds => 'Czy mogę udostępniać swoje buildy innym?';

  @override
  String get canIShareMyBuildsAnswer =>
      'Absolutnie! KAZABUILD został zaprojektowany jako platforma społecznościowa. Możesz udostępniać swoje buildy społeczności, otrzymywać feedback i inspirować innych. Możesz również przeglądać buildy utworzone przez innych użytkowników, zapisywać ulubione i uczyć się z różnych konfiguracji.';

  @override
  String get howDoICheckCompatibility =>
      'Jak sprawdzić kompatybilność komponentów?';

  @override
  String get howDoICheckCompatibilityAnswer =>
      'Nasz kreator buildów automatycznie sprawdza kompatybilność komponentów podczas wybierania części. System sprawdza czynniki takie jak kompatybilność gniazd, wymagania zasilacza, rozmiar obudowy i więcej. Jeśli wystąpią jakiekolwiek problemy z kompatybilnością, zostaniesz powiadomiony z sugestiami kompatybilnych alternatyw.';

  @override
  String get isKazabuildFree => 'Czy KAZABUILD jest darmowy?';

  @override
  String get isKazabuildFreeAnswer =>
      'Tak! KAZABUILD jest całkowicie darmowy. Możesz tworzyć nieograniczoną liczbę buildów, przeglądać społeczność, uczestniczyć w forach i uzyskać dostęp do wszystkich naszych przewodników i zasobów bez żadnych kosztów. Po prostu utwórz konto, aby rozpocząć i odblokować dodatkowe funkcje, takie jak zapisywanie buildów i udział w dyskusjach.';

  @override
  String get howCanIGetHelp => 'Jak mogę uzyskać pomoc z moim buildem?';

  @override
  String get howCanIGetHelpAnswer =>
      'Istnieje kilka sposobów na uzyskanie pomocy w KAZABUILD. Możesz publikować pytania na naszych forach, gdzie doświadczeni budowniczowie i entuzjaści chętnie pomogą. Możesz również przeglądać naszą kompleksową sekcję przewodników, aby znaleźć samouczki i porady. Dodatkowo możesz komentować podobne buildy w społeczności, aby uzyskać konkretne porady.';

  @override
  String get canISaveMultipleBuilds => 'Czy mogę zapisywać wiele buildów?';

  @override
  String get canISaveMultipleBuildsAnswer =>
      'Tak! Po utworzeniu konta możesz zapisywać wiele buildów i uzyskiwać do nich dostęp w dowolnym momencie. To idealne do planowania różnych buildów do różnych celów, takich jak gry, tworzenie treści lub konfiguracje workstation. Możesz również edytować, duplikować i udostępniać swoje zapisane buildy.';

  @override
  String get links => 'Linki';

  @override
  String get info => 'Informacje';

  @override
  String get aboutUs => 'O Nas';

  @override
  String get contactFeedback => 'Kontakt & Opinie';

  @override
  String get copyright => '© KAZA BUILD';

  @override
  String get builds => 'Buildy';

  @override
  String get pcPartsCategories => 'Kategorie Części PC';

  @override
  String get chooseCategoryToBrowse =>
      'Wybierz kategorię, aby przeglądać dostępne komponenty PC';

  @override
  String get errorLoadingParts => 'Błąd ładowania części';

  @override
  String itemsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'przedmiotów',
      one: 'przedmiot',
    );
    return '$count $_temp0';
  }

  @override
  String get priceNotAvailable => 'Cena Niedostępna';

  @override
  String get manageAccountSettings =>
      'Zarządzaj ustawieniami konta i preferencjami';

  @override
  String get profilePicture => 'Zdjęcie Profilowe';

  @override
  String get profileInformation => 'Informacje Profilowe';

  @override
  String get displayName => 'Nazwa Wyświetlana';

  @override
  String get username => 'Nazwa Użytkownika';

  @override
  String get usernameCannotBeChanged =>
      'Nazwa użytkownika nie może zostać zmieniona';

  @override
  String get bio => 'Biografia';

  @override
  String get notSet => 'Nie ustawiono';

  @override
  String get phoneNumber => 'Numer Telefonu';

  @override
  String get address => 'Adres';

  @override
  String get privacySecurity => 'Prywatność & Bezpieczeństwo';

  @override
  String get profilePrivacy => 'Prywatność Profilu';

  @override
  String get private => 'Prywatny';

  @override
  String get public => 'Publiczny';

  @override
  String get changePassword => 'Zmień Hasło';

  @override
  String get updateAccountPassword => 'Zaktualizuj hasło do konta';

  @override
  String get preferences => 'Preferencje';

  @override
  String get theme => 'Motyw';

  @override
  String get light => 'Jasny';

  @override
  String get dark => 'Ciemny';

  @override
  String get system => 'Systemowy';

  @override
  String get chooseFromGallery => 'Wybierz z Galerii';

  @override
  String get takePhoto => 'Zrób Zdjęcie';

  @override
  String get supportedFormats =>
      'Obsługiwane formaty: JPG, JPEG, PNG, GIF, WEBP, AVIF, BMP, TIFF, HEIC, ICO. Maksymalny rozmiar: 25MB.';

  @override
  String get profilePictureUpdated =>
      'Zdjęcie profilowe zostało pomyślnie zaktualizowane!';

  @override
  String get profileUpdated => 'Profil został pomyślnie zaktualizowany!';

  @override
  String get updateFailed => 'Aktualizacja nie powiodła się';

  @override
  String get failedToUpload => 'Przesłanie nie powiodło się';

  @override
  String get editAddress => 'Edytuj Adres';

  @override
  String get country => 'Kraj';

  @override
  String get provinceState => 'Województwo / Stan';

  @override
  String get city => 'Miasto';

  @override
  String get street => 'Ulica';

  @override
  String get number => 'Numer';

  @override
  String get postalCode => 'Kod Pocztowy';

  @override
  String get apartmentOptional => 'Mieszkanie (Opcjonalnie)';

  @override
  String get displayNameMustBeAtLeast4 =>
      'Nazwa wyświetlana musi mieć co najmniej 4 znaki';

  @override
  String get enterDisplayName => 'Wprowadź Nazwę Wyświetlaną';

  @override
  String get enterBio => 'Wprowadź Biografię';

  @override
  String get enterPhoneNumber => 'Wprowadź Numer Telefonu';

  @override
  String get manufacturer => 'Producent';

  @override
  String get type => 'Typ';

  @override
  String get releaseDate => 'Data Wydania';

  @override
  String get email => 'Email';
}
