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
  String get appTitle => 'Kaza Build';

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
  String get errorLoadingTags => 'Etiketler yüklenirken hata';

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
  String get describeBuild => 'Build\'inizi açıklayın...';

  @override
  String get pleaseEnterName => 'Lütfen bir ad girin';

  @override
  String get all => 'Tümü';

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
  String get pcPartsCategories => 'PC Parça Kategorileri';

  @override
  String get chooseCategoryToBrowse =>
      'Mevcut PC bileşenlerini görmek için bir kategori seçin';

  @override
  String get errorLoadingParts => 'Parçalar yüklenirken hata';

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
  String get displayName => 'Görünen Ad';

  @override
  String get username => 'Kullanıcı Adı';

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
}
