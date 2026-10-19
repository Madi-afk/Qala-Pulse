// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kazakh (`kk`).
class AppLocalizationsKk extends AppLocalizations {
  AppLocalizationsKk([String locale = 'kk']) : super(locale);

  @override
  String get sessionExpired =>
      'Сессия аяқталды. Қайта кіріңіз; жобаңыз сақталды.';

  @override
  String get invalidCategory =>
      'Санат енді қолжетімсіз. Басқасын таңдаңыз; фото, орын және мәтін сақталды.';

  @override
  String get publicationConflict =>
      'Жіберу кілті басқа мазмұнмен байланысты. Түзетпес бұрын алдыңғы әрекеттің нәтижесін тексеріңіз.';

  @override
  String get uploadAlreadyUsed =>
      'Фото басқа өтінішке тіркелген. Алдыңғы жіберуді тексеріңіз; түзету кезінде жаңа фото таңдаңыз.';

  @override
  String get publicationCancelled =>
      'Алдыңғы әрекет тоқтатылды. Өңдеуді жалғастыру үшін нәтижесін тексеріңіз.';

  @override
  String get publicationUnknown =>
      'Жіберу нәтижесі әзірге белгісіз. Қайталау сол кілтті пайдаланады және екінші көшірме жасамайды.';

  @override
  String get recoverPublication => 'Нәтижені тексеріп, түзету';

  @override
  String get discardDraft => 'Жобаны жою';

  @override
  String get discardDraftPrompt =>
      'Жергілікті жобаны жою керек пе? Жіберу аяқталса, жасалған өтініш ашылады. Сервер қолжетімсіз болса, жоба сақталады.';

  @override
  String get searchHere => 'Осы жерден іздеу';

  @override
  String get refreshMap => 'Картаны жаңарту';

  @override
  String mapSearchArea(int radius) {
    return 'Іздеу нүктесінен $radius м радиустағы өтініштер. Картаны жылжытып, «Осы жерден іздеу» түймесін басыңыз.';
  }

  @override
  String get mapResultsLimited =>
      'Алғашқы 200 өтініш көрсетілді. Картаны жақындатыңыз немесе санатты нақтылаңыз.';

  @override
  String get appName => 'QalaPulse';

  @override
  String get home => 'Басты бет';

  @override
  String get map => 'Карта';

  @override
  String get create => 'Құру';

  @override
  String get notifications => 'Хабарламалар';

  @override
  String get profile => 'Профиль';

  @override
  String get welcome => 'Қала сіздің\nқатысуыңыздан басталады';

  @override
  String get heroSubtitle =>
      'Мәселені байқаңыз. Көршілерге көмектесіңіз. Өзгерістерді бақылаңыз.';

  @override
  String get reportProblem => 'Мәселе туралы хабарлау';

  @override
  String get nearby => 'Жақын мәселелер';

  @override
  String get latest => 'Соңғы өтініштер';

  @override
  String get highPriority => 'Жоғары басымдық';

  @override
  String get allIncidents => 'Барлық өтініштер';

  @override
  String get honestNotice =>
      'QalaPulse — азаматтық платформа. Жариялау өтініштің мемлекеттік органға жіберілгенін білдірмейді.';

  @override
  String get login => 'Кіру';

  @override
  String get register => 'Тіркелу';

  @override
  String get email => 'Электрондық пошта';

  @override
  String get password => 'Құпиясөз';

  @override
  String get displayName => 'Аты';

  @override
  String get noAccount => 'Тіркелгі жасау';

  @override
  String get haveAccount => 'Тіркелгі бар ма? Кіру';

  @override
  String get passwordHint => 'Кемінде 10 таңба';

  @override
  String get loginRequired => 'Жалғастыру үшін кіріңіз';

  @override
  String get logout => 'Шығу';

  @override
  String get language => 'Интерфейс тілі';

  @override
  String get russian => 'Орысша';

  @override
  String get kazakh => 'Қазақша';

  @override
  String get myIncidents => 'Менің өтініштерім';

  @override
  String get myConfirmations => 'Менің растауларым';

  @override
  String get settings => 'Баптаулар';

  @override
  String get retry => 'Қайталау';

  @override
  String get save => 'Сақтау';

  @override
  String get cancel => 'Бас тарту';

  @override
  String get next => 'Жалғастыру';

  @override
  String get back => 'Артқа';

  @override
  String get done => 'Дайын';

  @override
  String get close => 'Жабу';

  @override
  String get loading => 'Жүктелуде…';

  @override
  String get empty => 'Әзірге өтініштер жоқ';

  @override
  String get loadMore => 'Тағы көрсету';

  @override
  String get networkError =>
      'Сервермен байланыс жоқ. Нобай сақталды — кейін қайта жіберіңіз.';

  @override
  String get serverError => 'Қызмет уақытша қолжетімсіз. Қайта көріңіз.';

  @override
  String get actionError =>
      'Әрекет орындалмады. Рұқсаттарды тексеріп, қайталаңыз.';

  @override
  String get invalidCredentials => 'Пошта немесе құпиясөз қате';

  @override
  String get emailUnavailable => 'Бұл мекенжай қолданылуда';

  @override
  String get alreadyConfirmed => 'Бұл растауды жібердіңіз';

  @override
  String get reviewRequired => 'Деректерді тексеріп, жариялауды растаңыз';

  @override
  String get rateLimited => 'Сұрау тым көп. Бір минут күтіңіз.';

  @override
  String get checkFields => 'Толтырылған өрістерді тексеріңіз';

  @override
  String get fileTooLarge => 'Фото 10 МБ, аудио 15 МБ дейін';

  @override
  String get invalidStatus => 'Бұл әрекет қазіргі мәртебеде қолжетімсіз';

  @override
  String get photo => 'Фотосурет';

  @override
  String get camera => 'Фото түсіру';

  @override
  String get gallery => 'Галереядан таңдау';

  @override
  String get photoHint =>
      'Мәселені жақыннан түсіріңіз. Адам жүздерін, көлік нөмірлерін және жеке құжаттарды түсірмеңіз.';

  @override
  String get location => 'Мәселе орны';

  @override
  String get currentLocation => 'Менің орным';

  @override
  String get locationHint =>
      'Картаны басыңыз немесе координаттарды енгізіңіз. Нүктені тексеріңіз.';

  @override
  String get latitude => 'Ендік';

  @override
  String get longitude => 'Бойлық';

  @override
  String get address => 'Бағдар немесе мекенжай';

  @override
  String get gpsDenied =>
      'Геолокация қолжетімсіз. Нүктені қолмен таңдаңыз немесе баптауларды ашыңыз.';

  @override
  String get description => 'Сипаттама';

  @override
  String get descriptionHint => 'Не болды? Несі кедергі немесе қауіпті?';

  @override
  String get voice => 'Дауыстық сипаттама';

  @override
  String get record => 'Жазу';

  @override
  String get stopRecording => 'Жазуды тоқтату';

  @override
  String get play => 'Тыңдау';

  @override
  String get stopPlayback => 'Тоқтату';

  @override
  String get recordAgain => 'Қайта жазу';

  @override
  String get transcribe => 'Сөйлеуді тану';

  @override
  String get transcribing => 'Жазба танылуда…';

  @override
  String get transcriptHint =>
      'Жалғастырмас бұрын мәтінді тексеріп, қателерді түзетіңіз.';

  @override
  String get mockTranscript =>
      'Сынақ мәтіні көрсетілген. Бұл сіздің жазбаңыздың танылған мәтіні емес.';

  @override
  String get aiAnalysis => 'AI талдауы';

  @override
  String get analyze => 'Талдау';

  @override
  String get analyzing => 'Фото мен сипаттама талдануда…';

  @override
  String get manualEntry => 'Қолмен толтыру';

  @override
  String get aiReview => 'AI ұсынысын тексеріңіз';

  @override
  String get aiWarning =>
      'AI қателесуі мүмкін. Өтініштің соңғы мазмұнын сіз анықтайсыз.';

  @override
  String get mockAi =>
      'Сынақ режимі: мәтін талданады, сурет танылмайды. Сенімділік өлшенбеген.';

  @override
  String get notCivic =>
      'Суретте қала мәселесі болмауы мүмкін. Оны қолмен сипаттай аласыз.';

  @override
  String get cloudConsent =>
      'Фото, мәтін және дауысты талдау үшін бапталған сыртқы AI провайдеріне жіберуге рұқсат етемін.';

  @override
  String get title => 'Тақырып';

  @override
  String get category => 'Санат';

  @override
  String get severity => 'Қауіп';

  @override
  String get confidence => 'Модель сенімділігі';

  @override
  String get duplicates => 'Ұқсас өтініштер';

  @override
  String get searchDuplicates => 'Ұқсастарды іздеу';

  @override
  String get noDuplicates => 'Ықтимал қайталанулар табылмады';

  @override
  String get duplicatesHint => 'Бір мәселе болса, бар өтінішті растаңыз.';

  @override
  String get confirmExisting => 'Осы мәселені растау';

  @override
  String get createAnyway => 'Жаңа өтініш құру';

  @override
  String get publish => 'Жариялау';

  @override
  String get publishConfirm =>
      'Фото, координаттар, сипаттама және AI ұсынысын тексердім.';

  @override
  String get privacyPreview => 'Фотоның жария нұсқасы';

  @override
  String get privacyNotice =>
      'MVP-де бүкіл фотоға күшті мозаика қолданылады. Түпнұсқа жабық. Мәтінге жеке деректерді қоспаңыз.';

  @override
  String get success => 'Өтініш жарияланды';

  @override
  String get successSubtitle =>
      'Енді көршілер мәселені QalaPulse-та көріп, растай алады.';

  @override
  String get openIncident => 'Өтінішті ашу';

  @override
  String get draftSaved => 'Нобай құрылғыда сақталды';

  @override
  String get waitingToSend => 'Жіберуді күтуде';

  @override
  String get retryPublish => 'Қайта жіберу';

  @override
  String get pendingLocked => 'Қауіпсіз қайта жіберу үшін мазмұн бекітілген.';

  @override
  String get stillExists => 'Мәселе әлі бар';

  @override
  String get reportResolution => 'Шешім туралы хабарлау';

  @override
  String get resolvedConfirm => 'Шешім расталды';

  @override
  String get partiallyResolved => 'Ішінара шешілген / шешімге қарсы пікір';

  @override
  String get confirmationSent => 'Растау қабылданды';

  @override
  String get comments => 'Пікірлер';

  @override
  String get addComment => 'Пікір қосу';

  @override
  String get send => 'Жіберу';

  @override
  String get commentSent => 'Пікір жарияланды';

  @override
  String get reportContent => 'Мазмұнға шағымдану';

  @override
  String get reportReason => 'Шағым себебі';

  @override
  String get reportSent => 'Шағым модераторға жіберілді';

  @override
  String get timeline => 'Мәртебелер тарихы';

  @override
  String get priority => 'Басымдық';

  @override
  String get confirmations => 'Растаулар';

  @override
  String get published => 'QalaPulse-та жарияланды';

  @override
  String get underReview => 'Модератор тексеруде';

  @override
  String get accepted => 'Ұйым қабылдады';

  @override
  String get inProgress => 'Орындалуда';

  @override
  String get resolvedPending => 'Шешілген деп белгіленді';

  @override
  String get resolved => 'Шешім расталды';

  @override
  String get rejected => 'Қабылданбады';

  @override
  String get allCategories => 'Барлық санат';

  @override
  String get mapAttribution => '© OpenStreetMap contributors';

  @override
  String get notificationHint =>
      'Өтініштеріңіздің мәртебесі. Push хабарламалары әзірге қосылмаған.';

  @override
  String get noNotifications => 'Әзірге жаңа оқиғалар жоқ';

  @override
  String get permissionSettings => 'Рұқсат баптауларын ашу';

  @override
  String get dateFormat => 'dd.MM.yyyy HH:mm';

  @override
  String get requiredField => 'Міндетті өріс';

  @override
  String get offlineDraftHint =>
      'Фото, нүкте және сипаттама автоматты сақталады. Жариялау үшін интернет қажет.';

  @override
  String get citizenPlatform => 'Қазақстан тұрғындарының платформасы';

  @override
  String greeting(String name) {
    return 'Сәлеметсіз бе, $name';
  }

  @override
  String get mapExploreHint => 'Ауданыңызда не болып жатқанын көріңіз';

  @override
  String get prioritySectionHint => 'Басымдығы ең жоғары өтініштер';

  @override
  String get emptyFeedHint =>
      'Қаладағы мәселені байқадыңыз ба? Фото қосып, картадан орнын белгілеңіз.';

  @override
  String get joinCity => 'Өзгерістерге\nүлес қосыңыз';

  @override
  String get welcomeBack => 'Қайта оралғаныңызға\nқуаныштымыз';

  @override
  String get authSubtitle =>
      'Мәселелерді хабарлап, ауданыңыздағы өзгерістерді бақылаңыз.';

  @override
  String get showPassword => 'Құпиясөзді көрсету';

  @override
  String get hidePassword => 'Құпиясөзді жасыру';

  @override
  String get yourActivity => 'Сіздің үлесіңіз';

  @override
  String get notificationsTab => 'Хабарлар';
}
