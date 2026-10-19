import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_kk.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('kk'),
    Locale('ru'),
  ];

  /// No description provided for @sessionExpired.
  ///
  /// In ru, this message translates to:
  /// **'Сессия завершена. Войдите снова; ваш черновик сохранён.'**
  String get sessionExpired;

  /// No description provided for @invalidCategory.
  ///
  /// In ru, this message translates to:
  /// **'Категория больше недоступна. Выберите другую; фото, точка и текст сохранены.'**
  String get invalidCategory;

  /// No description provided for @publicationConflict.
  ///
  /// In ru, this message translates to:
  /// **'Ключ отправки связан с другим содержимым. Проверьте результат предыдущей попытки перед исправлением.'**
  String get publicationConflict;

  /// No description provided for @uploadAlreadyUsed.
  ///
  /// In ru, this message translates to:
  /// **'Фото уже связано с обращением. Проверьте предыдущую отправку; при исправлении выберите новое фото.'**
  String get uploadAlreadyUsed;

  /// No description provided for @publicationCancelled.
  ///
  /// In ru, this message translates to:
  /// **'Предыдущая попытка отменена. Проверьте результат, чтобы продолжить редактирование.'**
  String get publicationCancelled;

  /// No description provided for @publicationUnknown.
  ///
  /// In ru, this message translates to:
  /// **'Результат отправки пока неизвестен. Повтор использует тот же ключ и не создаст вторую копию.'**
  String get publicationUnknown;

  /// No description provided for @recoverPublication.
  ///
  /// In ru, this message translates to:
  /// **'Проверить исход и исправить'**
  String get recoverPublication;

  /// No description provided for @discardDraft.
  ///
  /// In ru, this message translates to:
  /// **'Удалить черновик'**
  String get discardDraft;

  /// No description provided for @discardDraftPrompt.
  ///
  /// In ru, this message translates to:
  /// **'Удалить локальный черновик? Если отправка уже завершилась, откроется созданное обращение. При недоступном сервере черновик останется сохранённым.'**
  String get discardDraftPrompt;

  /// No description provided for @searchHere.
  ///
  /// In ru, this message translates to:
  /// **'Искать здесь'**
  String get searchHere;

  /// No description provided for @refreshMap.
  ///
  /// In ru, this message translates to:
  /// **'Обновить карту'**
  String get refreshMap;

  /// No description provided for @mapSearchArea.
  ///
  /// In ru, this message translates to:
  /// **'Обращения в радиусе {radius} м от точки поиска. Переместите карту и нажмите «Искать здесь».'**
  String mapSearchArea(int radius);

  /// No description provided for @mapResultsLimited.
  ///
  /// In ru, this message translates to:
  /// **'Показаны первые 200 обращений. Приблизьте карту или уточните категорию.'**
  String get mapResultsLimited;

  /// No description provided for @appName.
  ///
  /// In ru, this message translates to:
  /// **'QalaPulse'**
  String get appName;

  /// No description provided for @home.
  ///
  /// In ru, this message translates to:
  /// **'Главная'**
  String get home;

  /// No description provided for @map.
  ///
  /// In ru, this message translates to:
  /// **'Карта'**
  String get map;

  /// No description provided for @create.
  ///
  /// In ru, this message translates to:
  /// **'Создать'**
  String get create;

  /// No description provided for @notifications.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления'**
  String get notifications;

  /// No description provided for @profile.
  ///
  /// In ru, this message translates to:
  /// **'Профиль'**
  String get profile;

  /// No description provided for @welcome.
  ///
  /// In ru, this message translates to:
  /// **'Город начинается\nс участия'**
  String get welcome;

  /// No description provided for @heroSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Замечайте проблемы. Помогайте соседям. Следите за изменениями.'**
  String get heroSubtitle;

  /// No description provided for @reportProblem.
  ///
  /// In ru, this message translates to:
  /// **'Сообщить о проблеме'**
  String get reportProblem;

  /// No description provided for @nearby.
  ///
  /// In ru, this message translates to:
  /// **'Проблемы рядом'**
  String get nearby;

  /// No description provided for @latest.
  ///
  /// In ru, this message translates to:
  /// **'Последние обращения'**
  String get latest;

  /// No description provided for @highPriority.
  ///
  /// In ru, this message translates to:
  /// **'Высокий приоритет'**
  String get highPriority;

  /// No description provided for @allIncidents.
  ///
  /// In ru, this message translates to:
  /// **'Все обращения'**
  String get allIncidents;

  /// No description provided for @honestNotice.
  ///
  /// In ru, this message translates to:
  /// **'QalaPulse — гражданская платформа. Публикация не означает передачу обращения государственному органу.'**
  String get honestNotice;

  /// No description provided for @login.
  ///
  /// In ru, this message translates to:
  /// **'Войти'**
  String get login;

  /// No description provided for @register.
  ///
  /// In ru, this message translates to:
  /// **'Регистрация'**
  String get register;

  /// No description provided for @email.
  ///
  /// In ru, this message translates to:
  /// **'Электронная почта'**
  String get email;

  /// No description provided for @password.
  ///
  /// In ru, this message translates to:
  /// **'Пароль'**
  String get password;

  /// No description provided for @displayName.
  ///
  /// In ru, this message translates to:
  /// **'Имя'**
  String get displayName;

  /// No description provided for @noAccount.
  ///
  /// In ru, this message translates to:
  /// **'Создать аккаунт'**
  String get noAccount;

  /// No description provided for @haveAccount.
  ///
  /// In ru, this message translates to:
  /// **'Уже есть аккаунт? Войти'**
  String get haveAccount;

  /// No description provided for @passwordHint.
  ///
  /// In ru, this message translates to:
  /// **'Не менее 10 символов'**
  String get passwordHint;

  /// No description provided for @loginRequired.
  ///
  /// In ru, this message translates to:
  /// **'Войдите, чтобы продолжить'**
  String get loginRequired;

  /// No description provided for @logout.
  ///
  /// In ru, this message translates to:
  /// **'Выйти'**
  String get logout;

  /// No description provided for @language.
  ///
  /// In ru, this message translates to:
  /// **'Язык интерфейса'**
  String get language;

  /// No description provided for @russian.
  ///
  /// In ru, this message translates to:
  /// **'Русский'**
  String get russian;

  /// No description provided for @kazakh.
  ///
  /// In ru, this message translates to:
  /// **'Қазақша'**
  String get kazakh;

  /// No description provided for @myIncidents.
  ///
  /// In ru, this message translates to:
  /// **'Мои обращения'**
  String get myIncidents;

  /// No description provided for @myConfirmations.
  ///
  /// In ru, this message translates to:
  /// **'Мои подтверждения'**
  String get myConfirmations;

  /// No description provided for @settings.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get settings;

  /// No description provided for @retry.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get retry;

  /// No description provided for @save.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get cancel;

  /// No description provided for @next.
  ///
  /// In ru, this message translates to:
  /// **'Продолжить'**
  String get next;

  /// No description provided for @back.
  ///
  /// In ru, this message translates to:
  /// **'Назад'**
  String get back;

  /// No description provided for @done.
  ///
  /// In ru, this message translates to:
  /// **'Готово'**
  String get done;

  /// No description provided for @close.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть'**
  String get close;

  /// No description provided for @loading.
  ///
  /// In ru, this message translates to:
  /// **'Загрузка…'**
  String get loading;

  /// No description provided for @empty.
  ///
  /// In ru, this message translates to:
  /// **'Здесь пока нет обращений'**
  String get empty;

  /// No description provided for @loadMore.
  ///
  /// In ru, this message translates to:
  /// **'Показать ещё'**
  String get loadMore;

  /// No description provided for @networkError.
  ///
  /// In ru, this message translates to:
  /// **'Нет связи с сервером. Черновик сохранён — повторите отправку позже.'**
  String get networkError;

  /// No description provided for @serverError.
  ///
  /// In ru, this message translates to:
  /// **'Сервис временно недоступен. Повторите попытку.'**
  String get serverError;

  /// No description provided for @actionError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось выполнить действие. Проверьте разрешения и повторите.'**
  String get actionError;

  /// No description provided for @invalidCredentials.
  ///
  /// In ru, this message translates to:
  /// **'Неверная почта или пароль'**
  String get invalidCredentials;

  /// No description provided for @emailUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Этот адрес уже используется'**
  String get emailUnavailable;

  /// No description provided for @alreadyConfirmed.
  ///
  /// In ru, this message translates to:
  /// **'Вы уже отправили это подтверждение'**
  String get alreadyConfirmed;

  /// No description provided for @reviewRequired.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте данные и подтвердите публикацию'**
  String get reviewRequired;

  /// No description provided for @rateLimited.
  ///
  /// In ru, this message translates to:
  /// **'Слишком много запросов. Подождите минуту.'**
  String get rateLimited;

  /// No description provided for @checkFields.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте заполненные поля'**
  String get checkFields;

  /// No description provided for @fileTooLarge.
  ///
  /// In ru, this message translates to:
  /// **'Фотография до 10 МБ, аудио до 15 МБ'**
  String get fileTooLarge;

  /// No description provided for @invalidStatus.
  ///
  /// In ru, this message translates to:
  /// **'Это действие недоступно для текущего статуса'**
  String get invalidStatus;

  /// No description provided for @photo.
  ///
  /// In ru, this message translates to:
  /// **'Фотография'**
  String get photo;

  /// No description provided for @camera.
  ///
  /// In ru, this message translates to:
  /// **'Сделать фото'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать из галереи'**
  String get gallery;

  /// No description provided for @photoHint.
  ///
  /// In ru, this message translates to:
  /// **'Снимите проблему крупно. Избегайте лиц, номеров и личных документов.'**
  String get photoHint;

  /// No description provided for @location.
  ///
  /// In ru, this message translates to:
  /// **'Место проблемы'**
  String get location;

  /// No description provided for @currentLocation.
  ///
  /// In ru, this message translates to:
  /// **'Моя геолокация'**
  String get currentLocation;

  /// No description provided for @locationHint.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите на карту или введите координаты. Убедитесь, что точка верна.'**
  String get locationHint;

  /// No description provided for @latitude.
  ///
  /// In ru, this message translates to:
  /// **'Широта'**
  String get latitude;

  /// No description provided for @longitude.
  ///
  /// In ru, this message translates to:
  /// **'Долгота'**
  String get longitude;

  /// No description provided for @address.
  ///
  /// In ru, this message translates to:
  /// **'Ориентир или адрес'**
  String get address;

  /// No description provided for @gpsDenied.
  ///
  /// In ru, this message translates to:
  /// **'Геолокация недоступна. Выберите точку вручную или откройте настройки.'**
  String get gpsDenied;

  /// No description provided for @description.
  ///
  /// In ru, this message translates to:
  /// **'Описание'**
  String get description;

  /// No description provided for @descriptionHint.
  ///
  /// In ru, this message translates to:
  /// **'Что произошло? Чем это мешает или опасно?'**
  String get descriptionHint;

  /// No description provided for @voice.
  ///
  /// In ru, this message translates to:
  /// **'Голосовое описание'**
  String get voice;

  /// No description provided for @record.
  ///
  /// In ru, this message translates to:
  /// **'Записать'**
  String get record;

  /// No description provided for @stopRecording.
  ///
  /// In ru, this message translates to:
  /// **'Остановить запись'**
  String get stopRecording;

  /// No description provided for @play.
  ///
  /// In ru, this message translates to:
  /// **'Прослушать'**
  String get play;

  /// No description provided for @stopPlayback.
  ///
  /// In ru, this message translates to:
  /// **'Остановить'**
  String get stopPlayback;

  /// No description provided for @recordAgain.
  ///
  /// In ru, this message translates to:
  /// **'Записать заново'**
  String get recordAgain;

  /// No description provided for @transcribe.
  ///
  /// In ru, this message translates to:
  /// **'Распознать речь'**
  String get transcribe;

  /// No description provided for @transcribing.
  ///
  /// In ru, this message translates to:
  /// **'Распознаём запись…'**
  String get transcribing;

  /// No description provided for @transcriptHint.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте транскрипт и исправьте ошибки перед продолжением.'**
  String get transcriptHint;

  /// No description provided for @mockTranscript.
  ///
  /// In ru, this message translates to:
  /// **'Показан тестовый транскрипт. Он не является распознаванием вашей записи.'**
  String get mockTranscript;

  /// No description provided for @aiAnalysis.
  ///
  /// In ru, this message translates to:
  /// **'AI-анализ'**
  String get aiAnalysis;

  /// No description provided for @analyze.
  ///
  /// In ru, this message translates to:
  /// **'Проанализировать'**
  String get analyze;

  /// No description provided for @analyzing.
  ///
  /// In ru, this message translates to:
  /// **'Анализируем фотографию и описание…'**
  String get analyzing;

  /// No description provided for @manualEntry.
  ///
  /// In ru, this message translates to:
  /// **'Заполнить вручную'**
  String get manualEntry;

  /// No description provided for @aiReview.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте предложение AI'**
  String get aiReview;

  /// No description provided for @aiWarning.
  ///
  /// In ru, this message translates to:
  /// **'AI может ошибаться. Вы определяете окончательное содержание обращения.'**
  String get aiWarning;

  /// No description provided for @mockAi.
  ///
  /// In ru, this message translates to:
  /// **'Демо-режим: анализ по тексту, фотография не распознаётся. Уверенность не измерена.'**
  String get mockAi;

  /// No description provided for @notCivic.
  ///
  /// In ru, this message translates to:
  /// **'На снимке может не быть городской проблемы. Вы можете описать её вручную.'**
  String get notCivic;

  /// No description provided for @cloudConsent.
  ///
  /// In ru, this message translates to:
  /// **'Разрешаю отправить фото, текст и голос настроенному внешнему AI-провайдеру для анализа.'**
  String get cloudConsent;

  /// No description provided for @title.
  ///
  /// In ru, this message translates to:
  /// **'Заголовок'**
  String get title;

  /// No description provided for @category.
  ///
  /// In ru, this message translates to:
  /// **'Категория'**
  String get category;

  /// No description provided for @severity.
  ///
  /// In ru, this message translates to:
  /// **'Опасность'**
  String get severity;

  /// No description provided for @confidence.
  ///
  /// In ru, this message translates to:
  /// **'Уверенность модели'**
  String get confidence;

  /// No description provided for @duplicates.
  ///
  /// In ru, this message translates to:
  /// **'Похожие обращения'**
  String get duplicates;

  /// No description provided for @searchDuplicates.
  ///
  /// In ru, this message translates to:
  /// **'Найти похожие'**
  String get searchDuplicates;

  /// No description provided for @noDuplicates.
  ///
  /// In ru, this message translates to:
  /// **'Вероятных дубликатов не найдено'**
  String get noDuplicates;

  /// No description provided for @duplicatesHint.
  ///
  /// In ru, this message translates to:
  /// **'Если речь об одной проблеме, поддержите существующее обращение.'**
  String get duplicatesHint;

  /// No description provided for @confirmExisting.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердить эту проблему'**
  String get confirmExisting;

  /// No description provided for @createAnyway.
  ///
  /// In ru, this message translates to:
  /// **'Создать новое обращение'**
  String get createAnyway;

  /// No description provided for @publish.
  ///
  /// In ru, this message translates to:
  /// **'Опубликовать'**
  String get publish;

  /// No description provided for @publishConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Я проверил(а) фотографию, координаты, описание и предложение AI.'**
  String get publishConfirm;

  /// No description provided for @privacyPreview.
  ///
  /// In ru, this message translates to:
  /// **'Публичная версия фотографии'**
  String get privacyPreview;

  /// No description provided for @privacyNotice.
  ///
  /// In ru, this message translates to:
  /// **'В MVP ко всему фото применяется сильная мозаика. Оригинал закрыт. Не включайте личные данные в текст.'**
  String get privacyNotice;

  /// No description provided for @success.
  ///
  /// In ru, this message translates to:
  /// **'Обращение опубликовано'**
  String get success;

  /// No description provided for @successSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Теперь соседи могут увидеть и подтвердить проблему в QalaPulse.'**
  String get successSubtitle;

  /// No description provided for @openIncident.
  ///
  /// In ru, this message translates to:
  /// **'Открыть обращение'**
  String get openIncident;

  /// No description provided for @draftSaved.
  ///
  /// In ru, this message translates to:
  /// **'Черновик сохранён на устройстве'**
  String get draftSaved;

  /// No description provided for @waitingToSend.
  ///
  /// In ru, this message translates to:
  /// **'Ожидает отправки'**
  String get waitingToSend;

  /// No description provided for @retryPublish.
  ///
  /// In ru, this message translates to:
  /// **'Повторить отправку'**
  String get retryPublish;

  /// No description provided for @pendingLocked.
  ///
  /// In ru, this message translates to:
  /// **'Содержимое зафиксировано для безопасной повторной отправки.'**
  String get pendingLocked;

  /// No description provided for @stillExists.
  ///
  /// In ru, this message translates to:
  /// **'Проблема всё ещё актуальна'**
  String get stillExists;

  /// No description provided for @reportResolution.
  ///
  /// In ru, this message translates to:
  /// **'Сообщить о решении'**
  String get reportResolution;

  /// No description provided for @resolvedConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Решение подтверждено'**
  String get resolvedConfirm;

  /// No description provided for @partiallyResolved.
  ///
  /// In ru, this message translates to:
  /// **'Решено частично / оспорить решение'**
  String get partiallyResolved;

  /// No description provided for @confirmationSent.
  ///
  /// In ru, this message translates to:
  /// **'Подтверждение принято'**
  String get confirmationSent;

  /// No description provided for @comments.
  ///
  /// In ru, this message translates to:
  /// **'Комментарии'**
  String get comments;

  /// No description provided for @addComment.
  ///
  /// In ru, this message translates to:
  /// **'Добавить комментарий'**
  String get addComment;

  /// No description provided for @send.
  ///
  /// In ru, this message translates to:
  /// **'Отправить'**
  String get send;

  /// No description provided for @commentSent.
  ///
  /// In ru, this message translates to:
  /// **'Комментарий опубликован'**
  String get commentSent;

  /// No description provided for @reportContent.
  ///
  /// In ru, this message translates to:
  /// **'Пожаловаться на содержимое'**
  String get reportContent;

  /// No description provided for @reportReason.
  ///
  /// In ru, this message translates to:
  /// **'Причина жалобы'**
  String get reportReason;

  /// No description provided for @reportSent.
  ///
  /// In ru, this message translates to:
  /// **'Жалоба отправлена модератору'**
  String get reportSent;

  /// No description provided for @timeline.
  ///
  /// In ru, this message translates to:
  /// **'История статусов'**
  String get timeline;

  /// No description provided for @priority.
  ///
  /// In ru, this message translates to:
  /// **'Приоритет'**
  String get priority;

  /// No description provided for @confirmations.
  ///
  /// In ru, this message translates to:
  /// **'Подтверждения'**
  String get confirmations;

  /// No description provided for @published.
  ///
  /// In ru, this message translates to:
  /// **'Опубликовано в QalaPulse'**
  String get published;

  /// No description provided for @underReview.
  ///
  /// In ru, this message translates to:
  /// **'Проверяется модератором'**
  String get underReview;

  /// No description provided for @accepted.
  ///
  /// In ru, this message translates to:
  /// **'Принято организацией'**
  String get accepted;

  /// No description provided for @inProgress.
  ///
  /// In ru, this message translates to:
  /// **'В работе'**
  String get inProgress;

  /// No description provided for @resolvedPending.
  ///
  /// In ru, this message translates to:
  /// **'Отмечено как решённое'**
  String get resolvedPending;

  /// No description provided for @resolved.
  ///
  /// In ru, this message translates to:
  /// **'Решение подтверждено'**
  String get resolved;

  /// No description provided for @rejected.
  ///
  /// In ru, this message translates to:
  /// **'Отклонено'**
  String get rejected;

  /// No description provided for @allCategories.
  ///
  /// In ru, this message translates to:
  /// **'Все категории'**
  String get allCategories;

  /// No description provided for @mapAttribution.
  ///
  /// In ru, this message translates to:
  /// **'© OpenStreetMap contributors'**
  String get mapAttribution;

  /// No description provided for @notificationHint.
  ///
  /// In ru, this message translates to:
  /// **'Изменения статусов ваших обращений. Push-уведомления пока не подключены.'**
  String get notificationHint;

  /// No description provided for @noNotifications.
  ///
  /// In ru, this message translates to:
  /// **'Новых событий пока нет'**
  String get noNotifications;

  /// No description provided for @permissionSettings.
  ///
  /// In ru, this message translates to:
  /// **'Открыть настройки разрешений'**
  String get permissionSettings;

  /// No description provided for @dateFormat.
  ///
  /// In ru, this message translates to:
  /// **'dd.MM.yyyy HH:mm'**
  String get dateFormat;

  /// No description provided for @requiredField.
  ///
  /// In ru, this message translates to:
  /// **'Обязательное поле'**
  String get requiredField;

  /// No description provided for @offlineDraftHint.
  ///
  /// In ru, this message translates to:
  /// **'Фото, точка и описание сохраняются автоматически. Для публикации нужен интернет.'**
  String get offlineDraftHint;

  /// No description provided for @citizenPlatform.
  ///
  /// In ru, this message translates to:
  /// **'Платформа жителей Казахстана'**
  String get citizenPlatform;

  /// No description provided for @greeting.
  ///
  /// In ru, this message translates to:
  /// **'Здравствуйте, {name}'**
  String greeting(String name);

  /// No description provided for @mapExploreHint.
  ///
  /// In ru, this message translates to:
  /// **'Посмотрите, что происходит в вашем районе'**
  String get mapExploreHint;

  /// No description provided for @prioritySectionHint.
  ///
  /// In ru, this message translates to:
  /// **'Обращения с наибольшим приоритетом'**
  String get prioritySectionHint;

  /// No description provided for @emptyFeedHint.
  ///
  /// In ru, this message translates to:
  /// **'Заметили городскую проблему? Добавьте фото и отметьте место на карте.'**
  String get emptyFeedHint;

  /// No description provided for @joinCity.
  ///
  /// In ru, this message translates to:
  /// **'Станьте частью\nперемен'**
  String get joinCity;

  /// No description provided for @welcomeBack.
  ///
  /// In ru, this message translates to:
  /// **'Рады видеть\nвас снова'**
  String get welcomeBack;

  /// No description provided for @authSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Сообщайте о проблемах и следите за тем, как меняется ваш район.'**
  String get authSubtitle;

  /// No description provided for @showPassword.
  ///
  /// In ru, this message translates to:
  /// **'Показать пароль'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In ru, this message translates to:
  /// **'Скрыть пароль'**
  String get hidePassword;

  /// No description provided for @yourActivity.
  ///
  /// In ru, this message translates to:
  /// **'Ваше участие'**
  String get yourActivity;

  /// No description provided for @notificationsTab.
  ///
  /// In ru, this message translates to:
  /// **'События'**
  String get notificationsTab;
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
      <String>['kk', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'kk':
      return AppLocalizationsKk();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
