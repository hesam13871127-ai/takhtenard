/// Every user-facing string of the app, in Persian.
///
/// The app ships Persian-only by design; keeping all copy in one typed
/// place makes future localization straightforward.
abstract final class AppStrings {
  // ----------------------------------------------------------------- app
  static const String appTitle = 'تخته نرد';
  static const String appSubtitle = 'بازی سنتی ایرانی';
  static const String madeWithLove = 'ساخته شده با ❤️';
  static const String version = 'نسخه';
  static const String ok = 'باشه';
  static const String back = 'بازگشت';

  // ---------------------------------------------------------------- home
  static const String playVsAi = 'بازی با کامپیوتر';
  static const String playWithFriend = 'بازی دو نفره';
  static const String rules = 'قوانین بازی';
  static const String settings = 'تنظیمات';
  static const String continueGame = 'ادامه بازی';
  static const String chooseDifficulty = 'انتخاب درجه سختی';
  static const String easy = 'آسان';
  static const String medium = 'متوسط';
  static const String hard = 'سخت';
  static const String easyDesc = 'حرکت‌های تصادفی و ساده؛ مناسب تمرین';
  static const String mediumDesc = 'استراتژی پایه؛ زدن مهره و ساختن دیوار';
  static const String hardDesc = 'بازی حساب‌شده و حرفه‌ای؛ برای حریف‌های جدی';
  static const String startGame = 'شروع بازی';
  static const String friendModeHint =
      'دو بازیکن روی یک دستگاه؛ نوبت‌ها مشخص می‌شوند';

  // --------------------------------------------------------------- game
  static const String yourTurn = 'نوبت شما';
  static const String opponentTurn = 'نوبت حریف';
  static String playerTurn(String name) => 'نوبت $name';
  static String startsGame(String name) => '$name شروع می‌کند';
  static const String rollDice = 'تاس بریز';
  static const String rolling = 'در حال ریختن تاس…';
  static const String noMovesAvailable = 'حرکتی ممکن نیست!';
  static const String diceMustBeUsed =
      'باید بیشترین تعداد تاس ممکن بازی شود'; // shown never as error; used in rules
  static const String hitExclamation = 'مهره زده شد!';
  static const String backToBar = 'به مانع رفت!';
  static const String borneOff = 'جمع‌آوری مهره';
  static const String reenterFromBar = 'ورود از مانع';
  static const String undo = 'برگردان';
  static const String menu = 'منو';
  static const String pauseTitle = 'بازی متوقف شد';
  static const String resume = 'ادامه بازی';
  static const String restart = 'شروع دوباره';
  static const String exitToHome = 'خروج به منوی اصلی';
  static const String aiThinking = 'در حال فکر کردن…';
  static const String pip = 'پیپ';
  static const String offCount = 'جمع';
  static const String score = 'امتیاز';
  static const String youWin = 'شما برنده شدید!';
  static const String youLose = 'شریفانه باختید!';
  static const String openWithDice = 'تاسِ آغازین';
  static const String openingHint =
      'هر بازیکن یک تاس می‌اندازد؛ بازیکنِ بزرگ‌تر بازی را آغاز می‌کند';
  static const String openingTie = 'مساوی! دوباره تاس بریزید';
  static const String openingResultPause = 'نتیجهٔ تاس آغازین نمایش داده می‌شود…';
  static const String flipBoard = 'چرخش تخته';
  static const String whitePlayer = 'بازیکن سفید';
  static const String blackPlayer = 'بازیکن مشکی';
  static const String player1 = 'بازیکن ۱';
  static const String player2 = 'بازیکن ۲';
  static const String you = 'شما';
  static const String computer = 'کامپیوتر';

  // ------------------------------------------------------------ tutorial
  static const String tutorialTitle = 'آموزش سریع بازی';
  static const String tutorialSkip = 'رد شدن از آموزش';
  static const String tutorialPrevious = 'قبلی';
  static const String tutorialNext = 'بعدی';
  static const String tutorialStart = 'شروع بازی';
  static const String tutorialGoalTitle = 'هدف بازی';
  static const String tutorialGoalBody =
      'هر ۱۵ مهرهٔ خود را در جهت حرکت به خانهٔ خودی برسانید و سپس از تخته بیرون ببرید؛ هر که زودتر همه را جمع کند برنده است.';
  static const String tutorialDiceTitle = 'تاس و نوبت';
  static const String tutorialDiceBody =
      'در آغاز، هر بازیکن یک تاس می‌اندازد و عدد بزرگ‌تر شروع می‌کند. در نوبت خود دو تاس بریزید؛ هر تاس یک حرکت است و جفت، چهار حرکت می‌دهد.';
  static const String tutorialMoveTitle = 'حرکت مهره‌ها';
  static const String tutorialMoveBody =
      'مهره‌های درخشان قابل انتخاب‌اند. بعد از انتخاب، نقطه‌های روشن مقصدهای مجازند. تاس‌ها را یکی‌یکی بازی کنید یا اگر مسیر قانونی است، مقصد نهایی چند تاس را لمس کنید.';
  static const String tutorialHitTitle = 'زدن و ورود از مانع';
  static const String tutorialHitBody =
      'با فرود روی تک‌مهرهٔ حریف، آن را به مانع می‌فرستید؛ دو مهره یا بیشتر خانه را می‌بندند. اگر مهره‌ای روی مانع دارید، پیش از هر حرکت دیگری باید آن را وارد کنید.';
  static const String tutorialBearOffTitle = 'جمع‌کردن و قانون ایرانی';
  static const String tutorialBearOffBody =
      'وقتی هر ۱۵ مهره در خانهٔ خودی است، آن‌ها را با تاس بیرون ببرید. باید بیشترین تعداد تاس ممکن را بازی کنید. طبق قانون ایرانی، مهره‌ای که در خانهٔ خودی حریف را می‌زند تا پایان نوبت حرکت دوباره ندارد، مگر برای مصرف اجباری تاس باقی‌مانده.';
  static const String tutorialHintOpening =
      'برای شروع، «تاس آغازین» را بزنید؛ عدد بزرگ‌تر نوبت اول را می‌گیرد.';
  static const String tutorialHintRoll =
      'برای گرفتن تاس‌های نوبت، دکمهٔ «تاس بریز» را لمس کنید.';
  static const String tutorialHintRolling = 'تاس‌ها در حال چرخش‌اند؛ کمی صبر کنید.';
  static const String tutorialHintWait = 'نوبت حریف است؛ پس از حرکت او دوباره بازی کنید.';
  static const String tutorialHintSelect =
      'مهره‌های درخشان قابل حرکت‌اند؛ یکی را لمس کنید تا مقصدهای مجاز روشن شوند.';
  static const String tutorialHintDestination =
      'نقطه‌های روشن مقصدهای قانونی‌اند؛ حلقهٔ عدددار چند تاس را یکجا اجرا می‌کند.';
  static const String tutorialHintDismiss = 'بستن راهنما';

  // -------------------------------------------------------------- result
  static const String normalWin = 'برد ساده';
  static const String gammonWin = 'مارس';
  static String pointsWon(int points) =>
      points == 1 ? '۱ امتیاز' : '۲ امتیاز';
  static const String rematch = 'بازی مجدد';
  static const String backToHome = 'بازگشت به منوی اصلی';
  static const String matchScore = 'نتیجهٔ مجموعه';
  static String winnerIs(String name) => 'برنده: $name';
  static const String congratulations = 'آفرین!';

  // ------------------------------------------------------------ settings
  static const String soundSettings = 'صدا';
  static const String soundSettingsDesc = 'جلوه‌های صوتی بازی';
  static const String defaultDifficulty = 'درجه سختی پیش‌فرض';
  static const String boardTheme = 'تم تخته';
  static const String aboutApp = 'درباره برنامه';
  static const String flipForBlack = 'چرخش تخته برای بازیکن مشکی';
  static const String flipForBlackDesc =
      'در بازی دو نفره، تخته رو به بازیکنِ در نوبت می‌چرخد';
  static const String aboutTitle = 'تخته نرد';
  static String aboutBody(String version) =>
      'بازی سنتی تخته نرد ایرانی\n'
      '$version\n\n'
      'یک بازی کاملاً آفلاین، بدون تبلیغ و بدون نیاز به اینترنت.\n'
      'پیاده‌سازی کامل قوانین سنتی ایرانی همراه با حریف هوش مصنوعی '
      'در سه سطح.\n\n'
      'فونت: وزیرمتن (انتشار تحت مجوز OFL)\n'
      'ساخته شده با ❤️';

  // --------------------------------------------------------------- rules
  static const String rulesTitle = 'قوانین تخته نرد ایرانی';
  static const String rulesIntroTitle = 'مقدمه';
  static const String rulesIntro =
      'تخته نرد یکی کهن‌ترین بازی‌های صفحه‌ای ایران است. هدف: رساندن '
      'هر ۱۵ مهره به خانهٔ خودی و سپس بیرون آوردن آن‌ها پیش از حریف.';
  static const String rulesSetupTitle = '۱. چیدمان آغازین';
  static const String rulesSetupBody =
      'هر بازیکن ۱۵ مهره دارد. مهره‌ها به شکل سنتی چیده می‌شوند: '
      '۲ مهره در خانهٔ ۲۴، ۵ مهره در خانهٔ ۱۳، ۳ مهره در خانهٔ ۸ و '
      '۵ مهره در خانهٔ ۶. حرکت سفیدها پادساعتگرد و مشکی‌ها ساعتگرد است.';
  static const String rulesOpeningTitle = '۲. تاسِ آغازین';
  static const String rulesOpeningBody =
      'هر بازیکن یک تاس می‌اندازد. هر که عدد بزرگ‌تری آورد بازی را شروع '
      'می‌کند؛ اگر مساوی شد، دوباره می‌اندازند. برندهٔ تاس آغازین، برای '
      'نوبت اول دو تاس تازه می‌اندازد (رسوم سنتی ایرانی).';
  static const String rulesMovementTitle = '۳. حرکت مهره‌ها';
  static const String rulesMovementBody =
      'با هر تاس می‌توان یک مهره را به تعداد خانه‌های آن تاس جلو برد. '
      'هر تاس مستقل است: می‌توان یک مهره را با هر دو تاس پشت سر هم '
      'حرکت داد یا با دو مهرهٔ متفاوت بازی کرد. اگر دو تاس یکسان '
      'بیاید (جفت)، چهار حرکت با همان عدد در اختیار شماست.\n'
      'فرود فقط روی خانهٔ خالی، خانهٔ خودی یا خانه‌ای با فقط یک مهرهٔ '
      'حریف (مهرهٔ تنها) مجاز است. خانه‌ای با دو مهره یا بیشتر از '
      'حریف، بسته است.';
  static const String rulesHitTitle = '۴. زدن مهره (مهره‌زدن)';
  static const String rulesHitBody =
      'اگر روی خانه‌ای با یک مهرهٔ حریف فرود بیایید، آن مهره را زده‌اید '
      'و به «مانع» (وسط تخته) می‌فرستید.';
  static const String rulesHitAndRunTitle =
      '۵. قانون مهم ایرانی: ممنوعیت «زدن و گریختن» در خانه';
  static const String rulesHitAndRunBody =
      'در تخته نرد ایرانی، اگر مهرهٔ شما داخل خانهٔ خودی (خانه‌های ۱ تا ۶) '
      'مهرهٔ حریف را بزند، همان مهره تا پایان نوبت اجازهٔ حرکت مجدد ندارد '
      '— مگر اینکه ناچار به بازیِ تاس‌های باقی‌مانده باشید تا تاس '
      'نسوزد (خل‌سوزی نکند).';
  static const String rulesBarTitle = '۶. مانع و ورود مجدد';
  static const String rulesBarBody =
      'تا وقتی مهره‌ای در مانع دارید، اجازهٔ حرکت هیچ مهرهٔ دیگری را '
      'ندارید. ورود از مانع در خانهٔ حریف (خانه‌های ۱ تا ۶ از دید حریف) '
      'انجام می‌شود: عدد تاس دقیقاً همان خانهٔ ورود است و آن خانه باید '
      'باز باشد.';
  static const String rulesBearOffTitle = '۷. جمع‌کردن مهره‌ها';
  static const String rulesBearOffBody =
      'وقتی هر ۱۵ مهرهٔ شما داخل خانهٔ خودی باشد، می‌توانید مهره‌ها را '
      'بیرون ببرید. تاس دقیق، مهرهٔ همان شماره را بیرون می‌برد. اگر '
      'خانهٔ دقیق خالی بود و هیچ مهره‌ای در خانه‌های بالاتر نمانده باشد، '
      'تاسِ بزرگ‌تر می‌تواند بالاترین مهرهٔ موجود را بیرون ببرد.';
  static const String rulesMandatoryTitle = '۸. اجبار به بازی تاس';
  static const String rulesMandatoryBody =
      'باید هر چه بیشتر تاس‌های ممکن را بازی کنید. اگر فقط یکی از دو تاس '
      'قابل بازی است و هر دو امکان‌پذیرند، تاسِ بزرگ‌تر الزامی است. '
      'وقتی حرکتی نماند، نوبت خودکار به حریف می‌رسد.';
  static const String rulesScoringTitle = '۹. امتیازدهی';
  static const String rulesScoringBody =
      'برد ساده ۱ امتیاز دارد. اگر بازنده حتی یک مهره هم بیرون نیاورده '
      'باشد، برد «مارس» است و ۲ امتیاز دارد. در قوانین سنتی ایرانی '
      'امتیاز جداگانه‌ای برای مارسِ بزرگ (بکگمون) وجود ندارد و همان مارس '
      'محسوب می‌شود. تاسِ دوبرابر (دابلینگ) در این نسخهٔ سنتی استفاده '
      'نمی‌شود.';
  static const String rulesEtiquetteTitle = '۱۰. پایان بازی';
  static const String rulesEtiquetteBody =
      'برنده کسی است که زودتر هر ۱۵ مهره را از تخته بیرون ببرد. '
      'امتیازها در طول مجموعه جمع می‌شوند و می‌توانید تا هر تعداد دست '
      'ادامه دهید.';
}
