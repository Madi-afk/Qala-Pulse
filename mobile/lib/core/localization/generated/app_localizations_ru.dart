// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get sessionExpired =>
      'Сессия завершена. Войдите снова; ваш черновик сохранён.';

  @override
  String get invalidCategory =>
      'Категория больше недоступна. Выберите другую; фото, точка и текст сохранены.';

  @override
  String get publicationConflict =>
      'Ключ отправки связан с другим содержимым. Проверьте результат предыдущей попытки перед исправлением.';

  @override
  String get uploadAlreadyUsed =>
      'Фото уже связано с обращением. Проверьте предыдущую отправку; при исправлении выберите новое фото.';

  @override
  String get publicationCancelled =>
      'Предыдущая попытка отменена. Проверьте результат, чтобы продолжить редактирование.';

  @override
  String get publicationUnknown =>
      'Результат отправки пока неизвестен. Повтор использует тот же ключ и не создаст вторую копию.';

  @override
  String get recoverPublication => 'Проверить исход и исправить';

  @override
  String get discardDraft => 'Удалить черновик';

  @override
  String get discardDraftPrompt =>
      'Удалить локальный черновик? Если отправка уже завершилась, откроется созданное обращение. При недоступном сервере черновик останется сохранённым.';

  @override
  String get searchHere => 'Искать здесь';

  @override
  String get refreshMap => 'Обновить карту';

  @override
  String mapSearchArea(int radius) {
    return 'Обращения в радиусе $radius м от точки поиска. Переместите карту и нажмите «Искать здесь».';
  }

  @override
  String get mapResultsLimited =>
      'Показаны первые 200 обращений. Приблизьте карту или уточните категорию.';

  @override
  String get appName => 'QalaPulse';

  @override
  String get home => 'Главная';

  @override
  String get map => 'Карта';

  @override
  String get create => 'Создать';

  @override
  String get notifications => 'Уведомления';

  @override
  String get profile => 'Профиль';

  @override
  String get welcome => 'Город начинается\nс участия';

  @override
  String get heroSubtitle =>
      'Замечайте проблемы. Помогайте соседям. Следите за изменениями.';

  @override
  String get reportProblem => 'Сообщить о проблеме';

  @override
  String get nearby => 'Проблемы рядом';

  @override
  String get latest => 'Последние обращения';

  @override
  String get highPriority => 'Высокий приоритет';

  @override
  String get allIncidents => 'Все обращения';

  @override
  String get honestNotice =>
      'QalaPulse — гражданская платформа. Публикация не означает передачу обращения государственному органу.';

  @override
  String get login => 'Войти';

  @override
  String get register => 'Регистрация';

  @override
  String get email => 'Электронная почта';

  @override
  String get password => 'Пароль';

  @override
  String get displayName => 'Имя';

  @override
  String get noAccount => 'Создать аккаунт';

  @override
  String get haveAccount => 'Уже есть аккаунт? Войти';

  @override
  String get passwordHint => 'Не менее 10 символов';

  @override
  String get loginRequired => 'Войдите, чтобы продолжить';

  @override
  String get logout => 'Выйти';

  @override
  String get language => 'Язык интерфейса';

  @override
  String get russian => 'Русский';

  @override
  String get kazakh => 'Қазақша';

  @override
  String get myIncidents => 'Мои обращения';

  @override
  String get myConfirmations => 'Мои подтверждения';

  @override
  String get settings => 'Настройки';

  @override
  String get retry => 'Повторить';

  @override
  String get save => 'Сохранить';

  @override
  String get cancel => 'Отмена';

  @override
  String get next => 'Продолжить';

  @override
  String get back => 'Назад';

  @override
  String get done => 'Готово';

  @override
  String get close => 'Закрыть';

  @override
  String get loading => 'Загрузка…';

  @override
  String get empty => 'Здесь пока нет обращений';

  @override
  String get loadMore => 'Показать ещё';

  @override
  String get networkError =>
      'Нет связи с сервером. Черновик сохранён — повторите отправку позже.';

  @override
  String get serverError => 'Сервис временно недоступен. Повторите попытку.';

  @override
  String get actionError =>
      'Не удалось выполнить действие. Проверьте разрешения и повторите.';

  @override
  String get invalidCredentials => 'Неверная почта или пароль';

  @override
  String get emailUnavailable => 'Этот адрес уже используется';

  @override
  String get alreadyConfirmed => 'Вы уже отправили это подтверждение';

  @override
  String get reviewRequired => 'Проверьте данные и подтвердите публикацию';

  @override
  String get rateLimited => 'Слишком много запросов. Подождите минуту.';

  @override
  String get checkFields => 'Проверьте заполненные поля';

  @override
  String get fileTooLarge => 'Фотография до 10 МБ, аудио до 15 МБ';

  @override
  String get invalidStatus => 'Это действие недоступно для текущего статуса';

  @override
  String get photo => 'Фотография';

  @override
  String get camera => 'Сделать фото';

  @override
  String get gallery => 'Выбрать из галереи';

  @override
  String get photoHint =>
      'Снимите проблему крупно. Избегайте лиц, номеров и личных документов.';

  @override
  String get location => 'Место проблемы';

  @override
  String get currentLocation => 'Моя геолокация';

  @override
  String get locationHint =>
      'Нажмите на карту или введите координаты. Убедитесь, что точка верна.';

  @override
  String get latitude => 'Широта';

  @override
  String get longitude => 'Долгота';

  @override
  String get address => 'Ориентир или адрес';

  @override
  String get gpsDenied =>
      'Геолокация недоступна. Выберите точку вручную или откройте настройки.';

  @override
  String get description => 'Описание';

  @override
  String get descriptionHint => 'Что произошло? Чем это мешает или опасно?';

  @override
  String get voice => 'Голосовое описание';

  @override
  String get record => 'Записать';

  @override
  String get stopRecording => 'Остановить запись';

  @override
  String get play => 'Прослушать';

  @override
  String get stopPlayback => 'Остановить';

  @override
  String get recordAgain => 'Записать заново';

  @override
  String get transcribe => 'Распознать речь';

  @override
  String get transcribing => 'Распознаём запись…';

  @override
  String get transcriptHint =>
      'Проверьте транскрипт и исправьте ошибки перед продолжением.';

  @override
  String get mockTranscript =>
      'Показан тестовый транскрипт. Он не является распознаванием вашей записи.';

  @override
  String get aiAnalysis => 'AI-анализ';

  @override
  String get analyze => 'Проанализировать';

  @override
  String get analyzing => 'Анализируем фотографию и описание…';

  @override
  String get manualEntry => 'Заполнить вручную';

  @override
  String get aiReview => 'Проверьте предложение AI';

  @override
  String get aiWarning =>
      'AI может ошибаться. Вы определяете окончательное содержание обращения.';

  @override
  String get mockAi =>
      'Демо-режим: анализ по тексту, фотография не распознаётся. Уверенность не измерена.';

  @override
  String get notCivic =>
      'На снимке может не быть городской проблемы. Вы можете описать её вручную.';

  @override
  String get cloudConsent =>
      'Разрешаю отправить фото, текст и голос настроенному внешнему AI-провайдеру для анализа.';

  @override
  String get title => 'Заголовок';

  @override
  String get category => 'Категория';

  @override
  String get severity => 'Опасность';

  @override
  String get confidence => 'Уверенность модели';

  @override
  String get duplicates => 'Похожие обращения';

  @override
  String get searchDuplicates => 'Найти похожие';

  @override
  String get noDuplicates => 'Вероятных дубликатов не найдено';

  @override
  String get duplicatesHint =>
      'Если речь об одной проблеме, поддержите существующее обращение.';

  @override
  String get confirmExisting => 'Подтвердить эту проблему';

  @override
  String get createAnyway => 'Создать новое обращение';

  @override
  String get publish => 'Опубликовать';

  @override
  String get publishConfirm =>
      'Я проверил(а) фотографию, координаты, описание и предложение AI.';

  @override
  String get privacyPreview => 'Публичная версия фотографии';

  @override
  String get privacyNotice =>
      'Лица и номера ищутся локально, найденные области размываются. Автопоиск может ошибаться: проверьте весь снимок. Оригинал закрыт. Не включайте личные данные в текст.';

  @override
  String get privacyFullFrameNotice =>
      'Ко всему фото применено размытие: выбран усиленный режим либо точечная обработка недоступна. Публикуется только эта версия.';

  @override
  String get privacyNoRegions =>
      'Лица и номера не найдены. Это не гарантирует их отсутствия — проверьте снимок перед публикацией.';

  @override
  String get privacyZoomHint =>
      'Нажмите на фото, чтобы увеличить и проверить детали.';

  @override
  String get privacyBlurAll => 'Размыть фото целиком';

  @override
  String get privacyPublishConfirm =>
      'Я проверил описание и публичное фото: видимых лиц, читаемых номеров и других личных данных нет.';

  @override
  String get success => 'Обращение опубликовано';

  @override
  String get successSubtitle =>
      'Теперь соседи могут увидеть и подтвердить проблему в QalaPulse.';

  @override
  String get openIncident => 'Открыть обращение';

  @override
  String get draftSaved => 'Черновик сохранён на устройстве';

  @override
  String get waitingToSend => 'Ожидает отправки';

  @override
  String get retryPublish => 'Повторить отправку';

  @override
  String get pendingLocked =>
      'Содержимое зафиксировано для безопасной повторной отправки.';

  @override
  String get stillExists => 'Проблема всё ещё актуальна';

  @override
  String get reportResolution => 'Сообщить о решении';

  @override
  String get resolvedConfirm => 'Решение подтверждено';

  @override
  String get partiallyResolved => 'Решено частично / оспорить решение';

  @override
  String get confirmationSent => 'Подтверждение принято';

  @override
  String get comments => 'Комментарии';

  @override
  String get addComment => 'Добавить комментарий';

  @override
  String get send => 'Отправить';

  @override
  String get commentSent => 'Комментарий опубликован';

  @override
  String get reportContent => 'Пожаловаться на содержимое';

  @override
  String get reportReason => 'Причина жалобы';

  @override
  String get reportSent => 'Жалоба отправлена модератору';

  @override
  String get timeline => 'История статусов';

  @override
  String get priority => 'Приоритет';

  @override
  String get confirmations => 'Подтверждения';

  @override
  String get published => 'Опубликовано в QalaPulse';

  @override
  String get underReview => 'Проверяется модератором';

  @override
  String get accepted => 'Принято организацией';

  @override
  String get inProgress => 'В работе';

  @override
  String get resolvedPending => 'Отмечено как решённое';

  @override
  String get resolved => 'Решение подтверждено';

  @override
  String get rejected => 'Отклонено';

  @override
  String get allCategories => 'Все категории';

  @override
  String get mapAttribution => '© OpenStreetMap contributors';

  @override
  String get notificationHint =>
      'Изменения статусов ваших обращений. Push-уведомления пока не подключены.';

  @override
  String get noNotifications => 'Новых событий пока нет';

  @override
  String get permissionSettings => 'Открыть настройки разрешений';

  @override
  String get dateFormat => 'dd.MM.yyyy HH:mm';

  @override
  String get requiredField => 'Обязательное поле';

  @override
  String get offlineDraftHint =>
      'Фото, точка и описание сохраняются автоматически. Для публикации нужен интернет.';

  @override
  String get citizenPlatform => 'Платформа жителей Казахстана';

  @override
  String greeting(String name) {
    return 'Здравствуйте, $name';
  }

  @override
  String get mapExploreHint => 'Посмотрите, что происходит в вашем районе';

  @override
  String get prioritySectionHint => 'Обращения с наибольшим приоритетом';

  @override
  String get emptyFeedHint =>
      'Заметили городскую проблему? Добавьте фото и отметьте место на карте.';

  @override
  String get joinCity => 'Станьте частью\nперемен';

  @override
  String get welcomeBack => 'Рады видеть\nвас снова';

  @override
  String get authSubtitle =>
      'Сообщайте о проблемах и следите за тем, как меняется ваш район.';

  @override
  String get showPassword => 'Показать пароль';

  @override
  String get hidePassword => 'Скрыть пароль';

  @override
  String get yourActivity => 'Ваше участие';

  @override
  String get notificationsTab => 'События';

  @override
  String get forgotPassword => 'Забыли пароль?';

  @override
  String get uploadExpired =>
      'Срок хранения фото истёк. Загрузите его снова и проверьте обработку. Текст и координаты сохранены.';

  @override
  String get pilotInvitationRequired =>
      'Регистрация доступна приглашённым участникам пилота. Обратитесь к организатору.';

  @override
  String get sendRecovery => 'Отправить ссылку';

  @override
  String get recoverySent =>
      'Если активная учётная запись существует, письмо придёт на указанный адрес. Проверьте папку «Спам» и откройте ссылку в браузере. После смены пароля вернитесь в приложение и войдите заново.';
}
