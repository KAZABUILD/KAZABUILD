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
  String get appTitle => 'KazaBuild';

  @override
  String get exploreBuilds => 'Przeglądaj Buildy';

  @override
  String get discoverAmazingBuilds =>
      'Odkrywaj niesamowite buildy PC od społeczności';

  @override
  String get searchBuilds => 'Szukaj buildów...';

  @override
  String get myBuilds => 'Moje Buildy';

  @override
  String get takeQuiz => 'Podejmij Quiz';

  @override
  String get startBuild => 'Skompunuj Build';

  @override
  String get close => 'Zamknij';

  @override
  String get addToBuild => 'Dodaj do Buildu';

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
  String get logout => 'Wyloguj Się';

  @override
  String get login => 'Zaloguj Się';

  @override
  String get signUp => 'Zarejestruj Się';

  @override
  String get welcomeBack => 'Witaj Ponownie!';

  @override
  String get pcBuildingPlatform => 'Platforma Do Budowania PC';

  @override
  String get buildNow => 'Utwórz Konfigurację';

  @override
  String get openInBuilder => 'Otwórz w Kreatorze';

  @override
  String get guides => 'Przewodniki';

  @override
  String get forums => 'Forum';

  @override
  String get adminPanel => 'Panel Administratora';

  @override
  String get signIn => 'Zaloguj Się';

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
  String get saveBuild => 'Zapisz Konfigurację';

  @override
  String get buildName => 'Nazwa Konfiguracji';

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
  String get failedToSaveBuild => 'Nie udało się zapisać konfiguracji';

  @override
  String get startNewBuild => 'Stworzyć Nowy Konfigurację?';

  @override
  String get unsavedChanges =>
      'Masz niezapisane zmiany. Czy na pewno chcesz wyczyścić obecną konfiguracją?';

  @override
  String get clearBuild => 'Wyczyść Konfigurację';

  @override
  String get postBuild => 'Opublikuj Konfigurację';

  @override
  String get enterBuildName => 'Wprowadź nazwę dla swojej konfiguracji';

  @override
  String get describeBuild => 'Opisz swoją konfigurację...';

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
  String get buildAdvice => 'Porady Do Budowania';

  @override
  String get showOffBuild => 'Pochwal Się Konfiguracją';

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
      'Znajdź odpowiedzi na częste pytania dotyczące KAZABUILD';

  @override
  String get whatIsKazabuild => 'Czym jest KAZABUILD?';

  @override
  String get whatIsKazabuildAnswer =>
      'KAZABUILD to kompleksowa platforma do budowania PC, gdzie entuzjaści mogą tworzyć, udostępniać i odkrywać niestandardowe buildy PC. Niezależnie od tego, czy dopiero zaczynasz, czy jesteś ekspertem, KAZABUILD pomoże Ci zaprojektować idealną konfigurację PC, uzyskać fachowe porady i połączyć się ze społecznością budowania PC.';

  @override
  String get howDoICreateABuild => 'Jak utworzyć build PC?';

  @override
  String get howDoICreateABuildAnswer =>
      'Tworzenie konfiguracji PC jest łatwe! Kliknij \"Utwórz Build\" w menu nawigacyjnym, żeby zostać poprowadzonym przez naszego interaktywnego kreatora konfiguracji. Możesz wybierać komponenty z różnych kategorii, takich jak CPU, GPU, RAM, pamięć i nie tylko. Nasz system pomoże Ci sprawdzić kompatybilność i zasugeruje optymalne konfiguracje na podstawie Twoich potrzeb i budżetu.';

  @override
  String get arePricesUpToDate => 'Czy ceny komponentów są aktualne?';

  @override
  String get arePricesUpToDateAnswer =>
      'Dążymy do tego, aby nasza baza komponentów i cen była jak najbardziej aktualna. Mimo to, ceny na rynku często ulegają zmianą. Zalecamy sprawdzenie najnowszych cen u oficjalnych sprzedawców przed zakupem. Nasza platforma daja pomocne oszacowanie, aby pomóc w planowaniu budżetu.';

  @override
  String get canIShareMyBuilds =>
      'Czy mogę udostępniać swoje konfiguracje innym?';

  @override
  String get canIShareMyBuildsAnswer =>
      'Oczywiście! KAZABUILD został zaprojektowany z myślą o społeczności. Możliwe jest udostępnianie swoich konfiguracji społeczności, otrzymywanie kompozycji i inspirowanie innych. Możesz również przeglądać buildy utworzone przez innych użytkowników, zapisywać ulubione i uczyć się z różnych konfiguracji.';

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
      'Tak! KAZABUILD jest całkowicie darmowy. Możesz tworzyć nieograniczoną liczbę konfiguracji, przeglądać społeczność, uczestniczyć w forach i uzyskać dostęp do wszystkich naszych przewodników i zasobów bez żadnych kosztów. Po prostu utwórz konto, aby rozpocząć i odblokować dodatkowe funkcje, takie jak zapisywanie buildów i udział w dyskusjach.';

  @override
  String get howCanIGetHelp => 'Jak mogę uzyskać pomoc z moją konfiguracją?';

  @override
  String get howCanIGetHelpAnswer =>
      'Istnieje kilka sposobów na uzyskanie pomocy w KAZABUILD. Możesz publikować pytania na naszych forach, gdzie doświadczeni budowniczowie i entuzjaści z chęcią pomogą. Możesz również przeglądać naszą szczegółową sekcję przewodników, aby znaleźć samouczki i porady. Dodatkowo możesz zostawiać komentarze pod podobnymi bkonfiguracjami w społeczności, aby uzyskać konkretne porady.';

  @override
  String get canISaveMultipleBuilds => 'Czy mogę zapisywać wiele konfiguracji?';

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
  String get copyright => '© KAZABUILD';

  @override
  String get builds => 'Konfiguracje';

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
      one: 'przedmiot',
      few: 'przedmioty',
      other: 'przedmiotów',
    );
    return '$count $_temp0';
  }

  @override
  String get priceNotAvailable => 'Cena Niedostępna';

  @override
  String get manageAccountSettings =>
      'Zarządzaj swoimi ustawieniami konta i preferencjami';

  @override
  String get profilePicture => 'Zdjęcie Profilowe';

  @override
  String get profileInformation => 'Informacje O Profilu';

  @override
  String get displayName => 'Wyświetlana Nazwa';

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
  String get enterDisplayName => 'Wprowadź Wyświetlaną Nazwę';

  @override
  String get enterBio => 'Wprowadź Biografię';

  @override
  String get enterPhoneNumber => 'Wprowadź Numer Telefonu';

  @override
  String get manufacturer => 'Producent';

  @override
  String get type => 'Rodxaj';

  @override
  String get releaseDate => 'Data Wydania';

  @override
  String get email => 'Email';

  @override
  String get noBuildsFound => 'Nie znaleziono żadnych konfiguracji';

  @override
  String get tryAdjustingFilters =>
      'Spróbuj dostosować filtry lub sprawdź ponownie później';

  @override
  String get errorLoadingBuilds => 'Błąd ładowania buildów';

  @override
  String get retry => 'Spróbuj ponownie';

  @override
  String get status => 'Status';

  @override
  String get noImage => 'Brak Obrazu';

  @override
  String get clickToViewComponents => 'Kliknij, aby zobaczyć komponenty';

  @override
  String get components => 'Komponenty';

  @override
  String get comments => 'Komentarze';

  @override
  String get noImageAvailable => 'Brak Obrazu';

  @override
  String get postedOn => 'Opublikowano';

  @override
  String get wishlistBuild => 'Dodaj konfigurację do Listy Życzeń';

  @override
  String get noComponentsListed => 'Brak komponentów';

  @override
  String fromVendors(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'sprzedawców',
      one: 'sprzedawcy',
    );
    return 'od $count $_temp0';
  }

  @override
  String get signInToComment =>
      'Zaloguj się, aby zostawić komentarz pod tą konfiguracją';

  @override
  String get pleaseSignInToComment =>
      'Zaloguj się, aby komentować. Użyj nawigacji, aby przejść do logowania.';

  @override
  String get writeComment => 'Napisz komentarz...';

  @override
  String get post => 'Opublikuj';

  @override
  String get pleaseSignInToCommentShort => 'Zaloguj się, aby komentować';

  @override
  String get failedToLoadComments => 'Nie udało się załadować komentarzy';

  @override
  String get noCommentsYet => 'Brak komentarzy. Zostań pierwszym!';

  @override
  String get pleaseSignInToRate => 'Zaloguj się, aby ocenić tą konfigurację.';

  @override
  String get pleaseSignInToRateBuilds =>
      'Zaloguj się, aby oceniać konfiguracje';

  @override
  String get failedToSubmitRating => 'Nie udało się przesłać oceny';

  @override
  String get removeRating => 'Usuń ocenę';

  @override
  String get rate => 'Oceń';

  @override
  String get yes => 'Tak';

  @override
  String get no => 'Nie';

  @override
  String get vendors => 'Sprzedawcy';

  @override
  String get similarBuilds => 'Podobne Konfiguracje';

  @override
  String get series => 'Seria';

  @override
  String get socket => 'Gniazdo';

  @override
  String get chipset => 'Chipset';

  @override
  String get formFactor => 'Format';

  @override
  String get memoryType => 'Rodzaj Pamięci';

  @override
  String get ramType => 'Rodzaj RAM';

  @override
  String get capacity => 'Pojemność';

  @override
  String get speed => 'Prędkość';

  @override
  String get tdp => 'TDP';

  @override
  String get length => 'Długość';

  @override
  String get height => 'Wysokość';

  @override
  String get baseClock => 'Podstawowa Częstotliwość';

  @override
  String get boostClock => 'Podkręcona Częstotliwość';

  @override
  String get coreCount => 'Liczba Rdzeni';

  @override
  String get threads => 'Wątki';

  @override
  String get vram => 'VRAM';

  @override
  String get microarchitecture => 'Mikroarchitektura';

  @override
  String get coreFamily => 'Rodzina Rdzeni';

  @override
  String get totalCores => 'Całkowita Liczba Rdzeni';

  @override
  String get pCores => 'Rdzenie P';

  @override
  String get eCores => 'Rdzenie E';

  @override
  String get l1Cache => 'Pamięć Podręczna L1';

  @override
  String get l2Cache => 'Pamięć Podręczna L2';

  @override
  String get l3Cache => 'Pamięć Podręczna L3';

  @override
  String get l4Cache => 'Pamięć Podręczna L4';

  @override
  String get lithography => 'Litografia';

  @override
  String get packaging => 'Opakowanie';

  @override
  String get includesCooler => 'Zawiera Chłodzenie';

  @override
  String get smtSupport => 'Wsparcie SMT';

  @override
  String get eccSupport => 'Wsparcie ECC';

  @override
  String get integratedGraphics => 'Zintegrowana Grafika';

  @override
  String get memoryClock => 'Częstotliwość Pamięci';

  @override
  String get memoryBusWidth => 'Szerokość Szyny Pamięci';

  @override
  String get slotWidth => 'Szerokość Gniazda';

  @override
  String get totalSlots => 'Całkowita Liczba Gniazd';

  @override
  String get coolingType => 'Typ Chłodzenia';

  @override
  String get frameSync => 'Synchronizacja Klatek';

  @override
  String get ramSlots => 'Gniazda RAM';

  @override
  String get maxRam => 'Maksymalna Pamięć RAM';

  @override
  String get cpuFanHeaders => 'Złącza Wentylatora CPU';

  @override
  String get caseFanHeaders => 'Złącza Wentylatora Obudowy';

  @override
  String get pumpHeaders => 'Złącza Pompy';

  @override
  String get audioChipset => 'Chipset Audio';

  @override
  String get maxAudioChannels => 'Maksymalna Liczba Kanałów Audio';

  @override
  String get raidSupport => 'Wsparcie RAID';

  @override
  String get biosFlashback => 'BIOS Flashback';

  @override
  String get clearCmos => 'Wyczyść CMOS';

  @override
  String get casLatency => 'Opóźnienie CAS';

  @override
  String get timings => 'Czasy';

  @override
  String get modules => 'Moduły';

  @override
  String get moduleCapacity => 'Pojemność Modułu';

  @override
  String get ecc => 'ECC';

  @override
  String get registered => 'Zarejestrowany';

  @override
  String get heatSpreader => 'Rozpraszacz Ciepła';

  @override
  String get rgb => 'RGB';

  @override
  String get voltage => 'Napięcie';

  @override
  String get interface => 'Interfejs';

  @override
  String get nvme => 'NVMe';

  @override
  String get wattage => 'Moc';

  @override
  String get efficiency => 'Wydajność';

  @override
  String get modularity => 'Modularność';

  @override
  String get fanless => 'Bezwentylatorowy';

  @override
  String get radiatorSize => 'Rozmiar Radiatora';

  @override
  String get fanSize => 'Rozmiar Wentylatora';

  @override
  String get fanQuantity => 'Liczba Wentylatorów';

  @override
  String get minFanSpeed => 'Minimalna Prędkość Wentylatora';

  @override
  String get maxFanSpeed => 'Maksymalna Prędkość Wentylatora';

  @override
  String get minNoise => 'Minimalna Głośność';

  @override
  String get maxNoise => 'Maksymalna Głośność';

  @override
  String get fanlessOperation => 'Praca Bezwentylatorowa';

  @override
  String get size => 'Rozmiar';

  @override
  String get quantity => 'Ilość';

  @override
  String get minAirflow => 'Minimalny Przepływ Powietrza';

  @override
  String get maxAirflow => 'Maksymalny Przepływ Powietrza';

  @override
  String get pwm => 'PWM';

  @override
  String get ledType => 'Typ LED';

  @override
  String get connector => 'Złącze';

  @override
  String get controller => 'Kontroler';

  @override
  String get staticPressure => 'Ciśnienie Statyczne';

  @override
  String get flowDirection => 'Kierunek Przepływu';

  @override
  String get powerSupplyShrouded => 'Zasilacz Osłonięty';

  @override
  String get includedPsu => 'Zasilacz Wbudowany';

  @override
  String get transparentSidePanel => 'Przezroczysta Płyta Boczna';

  @override
  String get sidePanelType => 'Typ Płyty Bocznej';

  @override
  String get maxGpuLength => 'Maksymalna Długość GPU';

  @override
  String get maxCpuCoolerHeight => 'Maksymalna Wysokość Chłodzenia CPU';

  @override
  String get screenSize => 'Rozmiar Ekranu';

  @override
  String get resolution => 'Rozdzielczość';

  @override
  String get refreshRate => 'Częstotliwość Odświeżania';

  @override
  String get panelType => 'Rodzaj Panelu';

  @override
  String get responseTime => 'Czas Odpowiedzi';

  @override
  String get viewingAngle => 'Kąt Widzenia';

  @override
  String get aspectRatio => 'Proporcje';

  @override
  String get maxBrightness => 'Maksymalna Jasność';

  @override
  String get hdr => 'HDR';

  @override
  String get adaptiveSync => 'Adaptacyjna Synchronizacja';

  @override
  String get sata6Gbs => 'SATA 6 Gb/s';

  @override
  String get sata3Gbs => 'SATA 3 Gb/s';

  @override
  String get u2Ports => 'Porty U.2';

  @override
  String get wifi => 'Wi-Fi';

  @override
  String get argb5vHeaders => 'Złącza ARGB 5V';

  @override
  String get rgb12vHeaders => 'Złącza RGB 12V';

  @override
  String get internal35BayAmount => 'Zasobniki 3.5\"';

  @override
  String get internal25BayAmount => 'Zasobniki 2.5\"';

  @override
  String get external525BayAmount => 'Zasobniki Zewnętrzne 5.25\"';

  @override
  String get external35BayAmount => 'Zasobniki Zewnętrzne 3.5\"';

  @override
  String get waterCooled => 'Chłodzenie Wodne';

  @override
  String get airCooled => 'Chłodzenie Powietrzne';

  @override
  String get heroTitle =>
      'Nie wiesz od czego zacząć?\nPo prostu rozwiąż ten krótki quiz, aby rozpocząć';

  @override
  String get heroDescription =>
      'Oferujemy generacje konfiguracji, kompatybilność, konwersję cen, konfiguracje społeczności i dyskusje na forum';

  @override
  String get buildGenerations => 'generacje konfiguracji';

  @override
  String get compatibility => 'kompatybilność';

  @override
  String get priceConversion => 'konwersję cen';

  @override
  String get communityBuilds => 'konfiguracje społeczności';

  @override
  String get forumDiscussions => 'dyskusje na forum';

  @override
  String get appName => 'KAZABUILD';
}
