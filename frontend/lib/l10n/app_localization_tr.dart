// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localization.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get language => 'Türkçe';

  @override
  String get appTitle => 'KazaBuild';

  @override
  String get exploreBuilds => 'Build\'leri Keşfet';

  @override
  String get discoverAmazingBuilds =>
      'Topluluktan harika PC build\'lerini keşfedin';

  @override
  String get searchBuilds => 'Build ara...';

  @override
  String get myBuilds => 'Build\'lerim';

  @override
  String get takeQuiz => 'Quiz\'e Başla';

  @override
  String get startBuild => 'Build Başlat';

  @override
  String get close => 'Kapat';

  @override
  String get addToBuild => 'Build\'e Ekle';

  @override
  String get save => 'Kaydet';

  @override
  String get cancel => 'İptal';

  @override
  String get newText => 'Yeni';

  @override
  String get filters => 'Filtreler';

  @override
  String get sortBy => 'Sırala';

  @override
  String get latest => 'En Yeni';

  @override
  String get popular => 'Popüler';

  @override
  String get price => 'Fiyat';

  @override
  String get clearAllFilters => 'Tüm Filtreleri Temizle';

  @override
  String buildsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'build',
      one: 'build',
    );
    return '$count $_temp0';
  }

  @override
  String get home => 'Ana Sayfa';

  @override
  String get explore => 'Keşfet';

  @override
  String get parts => 'Parçalar';

  @override
  String get profile => 'Profil';

  @override
  String get settings => 'Ayarlar';

  @override
  String get logout => 'Çıkış Yap';

  @override
  String get login => 'Giriş Yap';

  @override
  String get signUp => 'Kayıt Ol';

  @override
  String get welcomeBack => 'Tekrar Hoş Geldiniz!';

  @override
  String get pcBuildingPlatform => 'PC Build Platformu';

  @override
  String get buildNow => 'Build Oluştur';

  @override
  String get openInBuilder => 'Builder`da Aç';

  @override
  String get guides => 'Kılavuzlar';

  @override
  String get forums => 'Forumlar';

  @override
  String get adminPanel => 'Yönetici Paneli';

  @override
  String get signIn => 'Giriş Yap';

  @override
  String get welcome => 'Hoş Geldiniz';

  @override
  String get viewProfile => 'Profili Görüntüle';

  @override
  String get cpu => 'İşlemci';

  @override
  String get gpu => 'Ekran Kartı';

  @override
  String get motherboard => 'Anakart';

  @override
  String get memoryRam => 'Bellek (RAM)';

  @override
  String get storage => 'Depolama';

  @override
  String get powerSupply => 'Güç Kaynağı';

  @override
  String get cooler => 'Soğutucu';

  @override
  String get caseFan => 'Kasa Fanı';

  @override
  String get pcCase => 'Kasa';

  @override
  String get monitor => 'Monitör';

  @override
  String get saveBuild => 'Build\'i Kaydet';

  @override
  String get buildName => 'Build Adı';

  @override
  String get description => 'Açıklama (Opsiyonel)';

  @override
  String get tags => 'Etiketler (Opsiyonel)';

  @override
  String get noTagsAvailable => 'Etiket mevcut değil';

  @override
  String get errorLoadingTags => 'Etiketler yüklenirken hata oluştu';

  @override
  String get buildSavedSuccessfully => 'Build başarıyla kaydedildi!';

  @override
  String get failedToSaveBuild => 'Build kaydedilemedi';

  @override
  String get startNewBuild => 'Yeni Build Başlat?';

  @override
  String get unsavedChanges =>
      'Kaydedilmemiş değişiklikleriniz var. Mevcut build\'i temizlemek istediğinize emin misiniz?';

  @override
  String get clearBuild => 'Build\'i Temizle';

  @override
  String get postBuild => 'Build\'i Yayınla';

  @override
  String get enterBuildName => 'Build\'iniz için bir ad girin';

  @override
  String get describeBuild => 'Build\'inizi için açıklama...';

  @override
  String get pleaseEnterName => 'Lütfen bir ad girin';

  @override
  String get all => 'Tümü';

  @override
  String get any => 'Herhangi';

  @override
  String get noGuidesFound => 'Bu kategoride kılavuz bulunamadı';

  @override
  String get guidesTitle => 'PC Build Kılavuzları';

  @override
  String get guidesDescription => 'Uzman kılavuzlardan ve eğitimlerden öğrenin';

  @override
  String get newest => 'En Yeni';

  @override
  String get oldest => 'En Eski';

  @override
  String get troubleshooting => 'Sorun Giderme';

  @override
  String get buildAdvice => 'Build Tavsiyesi';

  @override
  String get showOffBuild => 'Build\'ini Göster';

  @override
  String get startDiscussion => 'Tartışma Başlat';

  @override
  String get noPostsFound => 'Gönderi bulunamadı';

  @override
  String get error => 'Hata';

  @override
  String get searchPosts => 'Gönderi ara...';

  @override
  String get frequentlyAskedQuestions => 'Sık Sorulan Sorular';

  @override
  String get findAnswersToCommonQuestions =>
      'KAZABUILD hakkında sık sorulan sorulara cevaplar bulun';

  @override
  String get whatIsKazabuild => 'KAZABUILD nedir?';

  @override
  String get whatIsKazabuildAnswer =>
      'KAZABUILD, meraklıların özel PC build\'leri oluşturabileceği, paylaşabileceği ve keşfedebileceği kapsamlı bir PC build platformudur. İster yeni başlayan ister uzman olun, KAZABUILD mükemmel PC konfigürasyonunu tasarlamanıza, uzman tavsiyeleri almanıza ve PC build topluluğuyla bağlantı kurmanıza yardımcı olur.';

  @override
  String get howDoICreateABuild => 'PC build\'i nasıl oluştururum?';

  @override
  String get howDoICreateABuildAnswer =>
      'PC build\'i oluşturmak çok kolay! Navigasyon menüsünden \"Build Oluştur\"a tıklayın ve interaktif build sihirbazımızla yönlendirileceksiniz. CPU, GPU, RAM, depolama ve daha fazlası gibi çeşitli kategorilerden bileşenler seçebilirsiniz. Sistemimiz uyumluluğu kontrol etmenize ve ihtiyaçlarınıza ve bütçenize göre optimal konfigürasyonlar önermenize yardımcı olur.';

  @override
  String get arePricesUpToDate => 'Bileşen fiyatları güncel mi?';

  @override
  String get arePricesUpToDateAnswer =>
      'Bileşen veritabanımızı ve fiyatlandırmamızı mümkün olduğunca güncel tutmaya çalışıyoruz. Ancak, fiyatlar pazarda sık sık dalgalanabilir. Satın almadan önce resmi perakendecilerden en son fiyatları kontrol etmenizi öneririz. Platformumuz bütçenizi planlamanıza yardımcı olmak için iyi bir tahmin sağlar.';

  @override
  String get canIShareMyBuilds =>
      'Build\'lerimi başkalarıyla paylaşabilir miyim?';

  @override
  String get canIShareMyBuildsAnswer =>
      'Kesinlikle! KAZABUILD sosyal bir platform olarak tasarlanmıştır. Build\'lerinizi toplulukla paylaşabilir, geri bildirim alabilir ve başkalarına ilham verebilirsiniz. Ayrıca diğer kullanıcılar tarafından oluşturulan build\'leri keşfedebilir, favorilerinizi kaydedebilir ve farklı konfigürasyonlardan öğrenebilirsiniz.';

  @override
  String get howDoICheckCompatibility =>
      'Bileşen uyumluluğunu nasıl kontrol ederim?';

  @override
  String get howDoICheckCompatibilityAnswer =>
      'Build sihirbazımız, parça seçerken bileşen uyumluluğunu otomatik olarak kontrol eder. Sistem, soket uyumluluğu, güç kaynağı gereksinimleri, kasa boyutu ve daha fazlası gibi faktörleri doğrular. Herhangi bir uyumluluk sorunu varsa, uyumlu alternatifler için önerilerle bilgilendirilirsiniz.';

  @override
  String get isKazabuildFree => 'KAZABUILD ücretsiz mi?';

  @override
  String get isKazabuildFreeAnswer =>
      'Evet! KAZABUILD tamamen ücretsizdir. Sınırsız build oluşturabilir, topluluğu gezinebilir, forumlara katılabilir ve tüm kılavuzlarımıza ve kaynaklarımıza hiçbir ücret ödemeden erişebilirsiniz. Başlamak için sadece bir hesap oluşturun ve build\'lerinizi kaydetme ve tartışmalara katılma gibi ek özelliklerin kilidini açın.';

  @override
  String get howCanIGetHelp => 'Build\'im için nasıl yardım alabilirim?';

  @override
  String get howCanIGetHelpAnswer =>
      'KAZABUILD\'de yardım almanın birkaç yolu vardır. Deneyimli build\'cilerin ve meraklıların yardımcı olmaktan mutluluk duyacağı forumlarımızda sorular sorabilirsiniz. Ayrıca öğreticiler ve ipuçları için kapsamlı kılavuzlar bölümümüze göz atabilirsiniz. Ek olarak, toplulukta benzer build\'lerde yorum yaparak spesifik tavsiyeler alabilirsiniz.';

  @override
  String get canISaveMultipleBuilds => 'Birden fazla build kaydedebilir miyim?';

  @override
  String get canISaveMultipleBuildsAnswer =>
      'Evet! Bir hesap oluşturduktan sonra, birden fazla build kaydedebilir ve istediğiniz zaman erişebilirsiniz. Bu, oyun, içerik oluşturma veya workstation kurulumları gibi çeşitli amaçlar için farklı build\'ler planlamak için mükemmeldir. Ayrıca kaydedilmiş build\'lerinizi düzenleyebilir, çoğaltabilir ve paylaşabilirsiniz.';

  @override
  String get links => 'Bağlantılar';

  @override
  String get info => 'Bilgi';

  @override
  String get aboutUs => 'Hakkımızda';

  @override
  String get contactFeedback => 'İletişim & Geri Bildirim';

  @override
  String get copyright => '© KAZA BUILD';

  @override
  String get builds => 'Build\'ler';

  @override
  String get pcPartsCategories => 'PC Parçaları Kategorileri';

  @override
  String get chooseCategoryToBrowse =>
      'Mevcut PC bileşenlerini görmek için bir kategori seçin';

  @override
  String get errorLoadingParts => 'Parçalar yüklenirken hata oluştu';

  @override
  String itemsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ürün',
      one: 'ürün',
    );
    return '$count $_temp0';
  }

  @override
  String get priceNotAvailable => 'Fiyat Mevcut Değil';

  @override
  String get manageAccountSettings =>
      'Hesap ayarlarınızı ve tercihlerinizi yönetin';

  @override
  String get profilePicture => 'Profil Resmi';

  @override
  String get profileInformation => 'Profil Bilgileri';

  @override
  String get displayName => 'Görünen Adınız';

  @override
  String get username => 'Kullanıcı Adınız';

  @override
  String get usernameCannotBeChanged => 'Kullanıcı adı değiştirilemez';

  @override
  String get bio => 'Biyografi';

  @override
  String get notSet => 'Ayarlanmadı';

  @override
  String get phoneNumber => 'Telefon Numarası';

  @override
  String get address => 'Adres';

  @override
  String get privacySecurity => 'Gizlilik & Güvenlik';

  @override
  String get profilePrivacy => 'Profil Gizliliği';

  @override
  String get private => 'Özel';

  @override
  String get public => 'Herkese Açık';

  @override
  String get changePassword => 'Şifre Değiştir';

  @override
  String get updateAccountPassword => 'Hesap şifrenizi güncelleyin';

  @override
  String get preferences => 'Tercihler';

  @override
  String get theme => 'Tema';

  @override
  String get light => 'Açık';

  @override
  String get dark => 'Koyu';

  @override
  String get system => 'Sistem';

  @override
  String get chooseFromGallery => 'Galeriden Seç';

  @override
  String get takePhoto => 'Fotoğraf Çek';

  @override
  String get supportedFormats =>
      'Desteklenen formatlar: JPG, JPEG, PNG, GIF, WEBP, AVIF, BMP, TIFF, HEIC, ICO. Maksimum boyut: 25MB.';

  @override
  String get profilePictureUpdated => 'Profil resmi başarıyla güncellendi!';

  @override
  String get profileUpdated => 'Profil başarıyla güncellendi!';

  @override
  String get updateFailed => 'Güncelleme başarısız';

  @override
  String get failedToUpload => 'Yükleme başarısız';

  @override
  String get editAddress => 'Adresi Düzenle';

  @override
  String get country => 'Ülke';

  @override
  String get provinceState => 'İl / Eyalet';

  @override
  String get city => 'Şehir';

  @override
  String get street => 'Sokak';

  @override
  String get number => 'Numara';

  @override
  String get postalCode => 'Posta Kodu';

  @override
  String get apartmentOptional => 'Daire (Opsiyonel)';

  @override
  String get displayNameMustBeAtLeast4 =>
      'Görünen ad en az 4 karakter olmalıdır';

  @override
  String get enterDisplayName => 'Görünen Ad Girin';

  @override
  String get enterBio => 'Biyografi Girin';

  @override
  String get enterPhoneNumber => 'Telefon Numarası Girin';

  @override
  String get manufacturer => 'Üretici';

  @override
  String get type => 'Tür';

  @override
  String get releaseDate => 'Çıkış Tarihi';

  @override
  String get email => 'E-posta';

  @override
  String get noBuildsFound => 'Build bulunamadı';

  @override
  String get tryAdjustingFilters =>
      'Filtrelerinizi ayarlamayı deneyin veya daha sonra tekrar kontrol edin';

  @override
  String get errorLoadingBuilds => 'Build\'ler yüklenirken hata';

  @override
  String get retry => 'Tekrar Dene';

  @override
  String get status => 'Durum';

  @override
  String get noImage => 'Resim Yok';

  @override
  String get clickToViewComponents => 'Bileşenleri görmek için tıklayın';

  @override
  String get components => 'Bileşenler';

  @override
  String get comments => 'Yorumlar';

  @override
  String get noImageAvailable => 'Resim Mevcut Değil';

  @override
  String get postedOn => 'Yayınlandı';

  @override
  String get wishlistBuild => 'Build\'i İstek Listesine Ekle';

  @override
  String get noComponentsListed => 'Listelenen bileşen yok';

  @override
  String fromVendors(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'satıcıdan',
      one: 'satıcıdan',
    );
    return '$count $_temp0';
  }

  @override
  String get signInToComment => 'Bu build\'e yorum yapmak için giriş yapın';

  @override
  String get pleaseSignInToComment =>
      'Lütfen yorum yapmak için giriş yapın. Giriş yapmak için navigasyon barını kullanın.';

  @override
  String get writeComment => 'Yorum yazın...';

  @override
  String get post => 'Gönder';

  @override
  String get pleaseSignInToCommentShort =>
      'Lütfen yorum yapmak için giriş yapın';

  @override
  String get failedToLoadComments => 'Yorumlar yüklenemedi';

  @override
  String get noCommentsYet => 'Henüz yorum yok. İlk yorumu siz yapın!';

  @override
  String get pleaseSignInToRate =>
      'Lütfen bu build\'i değerlendirmek için giriş yapın.';

  @override
  String get pleaseSignInToRateBuilds =>
      'Lütfen build\'leri değerlendirmek için giriş yapın';

  @override
  String get failedToSubmitRating => 'Değerlendirme gönderilemedi';

  @override
  String get removeRating => 'Değerlendirmeyi kaldır';

  @override
  String get rate => 'Değerlendir';

  @override
  String get yes => 'Evet';

  @override
  String get no => 'Hayır';

  @override
  String get vendors => 'Satıcılar';

  @override
  String get similarBuilds => 'Benzer Build\'ler';

  @override
  String get series => 'Seri';

  @override
  String get socket => 'Soket';

  @override
  String get chipset => 'Yonga Seti';

  @override
  String get formFactor => 'Form Faktörü';

  @override
  String get memoryType => 'Bellek Türü';

  @override
  String get ramType => 'RAM Türü';

  @override
  String get capacity => 'Kapasite';

  @override
  String get speed => 'Hız';

  @override
  String get tdp => 'TDP';

  @override
  String get length => 'Uzunluk';

  @override
  String get height => 'Yükseklik';

  @override
  String get baseClock => 'Temel Saat Hızı';

  @override
  String get boostClock => 'Boost Saat Hızı';

  @override
  String get coreCount => 'Çekirdek Sayısı';

  @override
  String get threads => 'İş Parçacığı';

  @override
  String get vram => 'VRAM';

  @override
  String get microarchitecture => 'Mikromimari';

  @override
  String get coreFamily => 'Çekirdek Ailesi';

  @override
  String get totalCores => 'Toplam Çekirdek';

  @override
  String get pCores => 'P-Çekirdek';

  @override
  String get eCores => 'E-Çekirdek';

  @override
  String get l1Cache => 'L1 Önbellek';

  @override
  String get l2Cache => 'L2 Önbellek';

  @override
  String get l3Cache => 'L3 Önbellek';

  @override
  String get l4Cache => 'L4 Önbellek';

  @override
  String get lithography => 'Litografi';

  @override
  String get packaging => 'Paketleme';

  @override
  String get includesCooler => 'Soğutucu Dahil';

  @override
  String get smtSupport => 'SMT Desteği';

  @override
  String get eccSupport => 'ECC Desteği';

  @override
  String get integratedGraphics => 'Entegre Grafik';

  @override
  String get memoryClock => 'Bellek Saat Hızı';

  @override
  String get memoryBusWidth => 'Bellek Veri Yolu Genişliği';

  @override
  String get slotWidth => 'Yuva Genişliği';

  @override
  String get totalSlots => 'Toplam Yuva';

  @override
  String get coolingType => 'Soğutma Türü';

  @override
  String get frameSync => 'Kare Senkronizasyonu';

  @override
  String get ramSlots => 'RAM Yuvaları';

  @override
  String get maxRam => 'Maksimum RAM';

  @override
  String get cpuFanHeaders => 'CPU Fan Başlıkları';

  @override
  String get caseFanHeaders => 'Kasa Fan Başlıkları';

  @override
  String get pumpHeaders => 'Pompa Başlıkları';

  @override
  String get audioChipset => 'Ses Yonga Seti';

  @override
  String get maxAudioChannels => 'Maksimum Ses Kanalları';

  @override
  String get raidSupport => 'RAID Desteği';

  @override
  String get biosFlashback => 'BIOS Flashback';

  @override
  String get clearCmos => 'CMOS Temizle';

  @override
  String get casLatency => 'CAS Gecikmesi';

  @override
  String get timings => 'Zamanlamalar';

  @override
  String get modules => 'Modüller';

  @override
  String get moduleCapacity => 'Modül Kapasitesi';

  @override
  String get ecc => 'ECC';

  @override
  String get registered => 'Kayıtlı';

  @override
  String get heatSpreader => 'Isı Yayıcı';

  @override
  String get rgb => 'RGB';

  @override
  String get voltage => 'Voltaj';

  @override
  String get interface => 'Arayüz';

  @override
  String get nvme => 'NVMe';

  @override
  String get wattage => 'Güç';

  @override
  String get efficiency => 'Verimlilik';

  @override
  String get modularity => 'Modülerlik';

  @override
  String get fanless => 'Fansız';

  @override
  String get radiatorSize => 'Radyatör Boyutu';

  @override
  String get fanSize => 'Fan Boyutu';

  @override
  String get fanQuantity => 'Fan Miktarı';

  @override
  String get minFanSpeed => 'Min Fan Hızı';

  @override
  String get maxFanSpeed => 'Max Fan Hızı';

  @override
  String get minNoise => 'Min Gürültü';

  @override
  String get maxNoise => 'Max Gürültü';

  @override
  String get fanlessOperation => 'Fansız Çalışma';

  @override
  String get size => 'Boyut';

  @override
  String get quantity => 'Miktar';

  @override
  String get minAirflow => 'Min Hava Akışı';

  @override
  String get maxAirflow => 'Max Hava Akışı';

  @override
  String get pwm => 'PWM';

  @override
  String get ledType => 'LED Türü';

  @override
  String get connector => 'Konnektör';

  @override
  String get controller => 'Kontrolcü';

  @override
  String get staticPressure => 'Statik Basınç';

  @override
  String get flowDirection => 'Akış Yönü';

  @override
  String get powerSupplyShrouded => 'Güç Kaynağı Korumalı';

  @override
  String get includedPsu => 'Dahil PSU';

  @override
  String get transparentSidePanel => 'Şeffaf Yan Panel';

  @override
  String get sidePanelType => 'Yan Panel Türü';

  @override
  String get maxGpuLength => 'Maksimum GPU Uzunluğu';

  @override
  String get maxCpuCoolerHeight => 'Maksimum CPU Soğutucu Yüksekliği';

  @override
  String get screenSize => 'Ekran Boyutu';

  @override
  String get resolution => 'Çözünürlük';

  @override
  String get refreshRate => 'Yenileme Hızı';

  @override
  String get panelType => 'Panel Türü';

  @override
  String get responseTime => 'Yanıt Süresi';

  @override
  String get viewingAngle => 'Görüş Açısı';

  @override
  String get aspectRatio => 'En-Boy Oranı';

  @override
  String get maxBrightness => 'Maksimum Parlaklık';

  @override
  String get hdr => 'HDR';

  @override
  String get adaptiveSync => 'Adaptif Senkronizasyon';

  @override
  String get sata6Gbs => 'SATA 6 Gb/s';

  @override
  String get sata3Gbs => 'SATA 3 Gb/s';

  @override
  String get u2Ports => 'U.2 Portları';

  @override
  String get wifi => 'Wi-Fi';

  @override
  String get argb5vHeaders => 'ARGB 5V Başlıkları';

  @override
  String get rgb12vHeaders => 'RGB 12V Başlıkları';

  @override
  String get internal35BayAmount => '3.5\" Bölmeler';

  @override
  String get internal25BayAmount => '2.5\" Bölmeler';

  @override
  String get external525BayAmount => '5.25\" Harici Bölmeler';

  @override
  String get external35BayAmount => '3.5\" Harici Bölmeler';

  @override
  String get waterCooled => 'Su Soğutmalı';

  @override
  String get airCooled => 'Hava Soğutmalı';

  @override
  String get heroTitle =>
      'Nereden başlayacağınızdan emin değil misiniz?\nbaşlamak için bu kısa quizi yapın';

  @override
  String get heroDescription =>
      'Build nesilleri, uyumluluk, fiyat dönüşümü, topluluk build\'leri ve forum tartışmaları özelliklerini sunuyoruz';

  @override
  String get buildGenerations => 'build nesilleri';

  @override
  String get compatibility => 'uyumluluk';

  @override
  String get priceConversion => 'fiyat dönüşümü';

  @override
  String get communityBuilds => 'topluluk build\'leri';

  @override
  String get forumDiscussions => 'forum tartışmaları';

  @override
  String get appName => 'KAZABUILD';

  @override
  String get unread => 'Okunmamış';

  @override
  String get notifications => 'Bildirimler';

  @override
  String get messages => 'Mesajlar';

  @override
  String get messagesDescription =>
      'Diğer kullanıcılarla bağlantı kurun ve iletişime geçin.';

  @override
  String get searchNotifications => 'Bildirimleri ara...';

  @override
  String get searchMessages => 'Mesajları ara...';

  @override
  String get noFeaturedBuilds => 'Henüz öne çıkan build seçilmedi';

  @override
  String get featuredBuilds => 'Öne Çıkan Build\'ler';

  @override
  String get couldNotLoadFeaturedBuilds => 'Öne çıkan build\'ler yüklenemedi';

  @override
  String get pcBuilder => 'PC Oluşturucu';

  @override
  String get configurePcBuild =>
      'Uyumluluk kontrolü ile özel PC build\'inizi yapılandırın.';

  @override
  String get buildSuccessfullySaved => 'Build profilinize başarıyla kaydedildi';

  @override
  String get replies => 'Yanıtlar';

  @override
  String get noRepliesYet => 'Henüz yanıt yok. İlk siz olun!';

  @override
  String get signInToContinue => 'Yolculuğunuza devam etmek için giriş yapın';

  @override
  String get compatibleProducts => 'Uyumlu Ürünler';

  @override
  String compatibleProductsCount(Object count) {
    return 'Uyumlu Ürünler ($count)';
  }

  @override
  String compatibleProductsCountPage(Object count, Object page) {
    return 'Uyumlu Ürünler ($count) • Sayfa $page';
  }

  @override
  String get page => 'Sayfa';

  @override
  String get compare => 'Karşılaştır';

  @override
  String compareCount(Object max, Object selected) {
    return 'Karşılaştır ($selected/$max)';
  }

  @override
  String get clear => 'Temizle';

  @override
  String get clearFilters => 'Filtreleri Temizle';

  @override
  String get compatibilityFilter => 'Uyumluluk Filtresi';

  @override
  String get componentComparison => 'Bileşen Karşılaştırması';

  @override
  String get spec => 'Özellik';

  @override
  String get previous => 'Önceki';

  @override
  String get next => 'Sonraki';

  @override
  String get searchProcessors => 'İşlemci ara...';

  @override
  String maxComparisonLimit(Object max) {
    return 'Aynı anda en fazla $max bileşeni karşılaştırabilirsiniz.';
  }

  @override
  String get clearSelection => 'Seçimi Temizle';
}
