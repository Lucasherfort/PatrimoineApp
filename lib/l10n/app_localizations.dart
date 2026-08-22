import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In fr, this message translates to:
  /// **'Patrimoine 360'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get navHome;

  /// No description provided for @navBudget.
  ///
  /// In fr, this message translates to:
  /// **'Budget'**
  String get navBudget;

  /// No description provided for @navAnalysis.
  ///
  /// In fr, this message translates to:
  /// **'Analyse'**
  String get navAnalysis;

  /// No description provided for @navRetirement.
  ///
  /// In fr, this message translates to:
  /// **'Retraite'**
  String get navRetirement;

  /// No description provided for @navSimulators.
  ///
  /// In fr, this message translates to:
  /// **'Outils'**
  String get navSimulators;

  /// No description provided for @navProfile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get navProfile;

  /// No description provided for @totalGrossWealth.
  ///
  /// In fr, this message translates to:
  /// **'PATRIMOINE BRUT TOTAL'**
  String get totalGrossWealth;

  /// No description provided for @netWealth.
  ///
  /// In fr, this message translates to:
  /// **'Patrimoine net'**
  String get netWealth;

  /// No description provided for @investedAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant investi'**
  String get investedAmount;

  /// No description provided for @investedPart.
  ///
  /// In fr, this message translates to:
  /// **'Part investie'**
  String get investedPart;

  /// No description provided for @performance.
  ///
  /// In fr, this message translates to:
  /// **'Performance'**
  String get performance;

  /// No description provided for @globalPerformance.
  ///
  /// In fr, this message translates to:
  /// **'Performance globale'**
  String get globalPerformance;

  /// No description provided for @detailsPatrimoine.
  ///
  /// In fr, this message translates to:
  /// **'Détails du patrimoine'**
  String get detailsPatrimoine;

  /// No description provided for @netWealthConstituted.
  ///
  /// In fr, this message translates to:
  /// **'Patrimoine net constitué'**
  String get netWealthConstituted;

  /// No description provided for @netWealthEstimated.
  ///
  /// In fr, this message translates to:
  /// **'Patrimoine net estimé'**
  String get netWealthEstimated;

  /// No description provided for @analysisTitle.
  ///
  /// In fr, this message translates to:
  /// **'ANALYSE STRATÉGIQUE'**
  String get analysisTitle;

  /// No description provided for @independencePilot.
  ///
  /// In fr, this message translates to:
  /// **'Pilote d\'Indépendance'**
  String get independencePilot;

  /// No description provided for @monthlyGains.
  ///
  /// In fr, this message translates to:
  /// **'GAINS MENSUELS ESTIMÉS'**
  String get monthlyGains;

  /// No description provided for @averageGenerated.
  ///
  /// In fr, this message translates to:
  /// **'Moyenne générée par vos actifs'**
  String get averageGenerated;

  /// No description provided for @needs.
  ///
  /// In fr, this message translates to:
  /// **'BESOINS'**
  String get needs;

  /// No description provided for @growth.
  ///
  /// In fr, this message translates to:
  /// **'CROISSANCE'**
  String get growth;

  /// No description provided for @liberty.
  ///
  /// In fr, this message translates to:
  /// **'LIBERTÉ'**
  String get liberty;

  /// No description provided for @expenseCoverage.
  ///
  /// In fr, this message translates to:
  /// **'COUVERTURE DES DÉPENSES'**
  String get expenseCoverage;

  /// No description provided for @investmentCoverage.
  ///
  /// In fr, this message translates to:
  /// **'COUVERTURE DE L\'INVESTISSEMENT'**
  String get investmentCoverage;

  /// No description provided for @salaryCoverage.
  ///
  /// In fr, this message translates to:
  /// **'COUVERTURE DU SALAIRE'**
  String get salaryCoverage;

  /// No description provided for @progression.
  ///
  /// In fr, this message translates to:
  /// **'Progression'**
  String get progression;

  /// No description provided for @objective.
  ///
  /// In fr, this message translates to:
  /// **'Objectif'**
  String get objective;

  /// No description provided for @appearance.
  ///
  /// In fr, this message translates to:
  /// **'APPARENCE'**
  String get appearance;

  /// No description provided for @theme.
  ///
  /// In fr, this message translates to:
  /// **'Thème de l\'application'**
  String get theme;

  /// No description provided for @themeLight.
  ///
  /// In fr, this message translates to:
  /// **'Clair'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In fr, this message translates to:
  /// **'Sombre'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In fr, this message translates to:
  /// **'Adaptatif'**
  String get themeSystem;

  /// No description provided for @language.
  ///
  /// In fr, this message translates to:
  /// **'Langue de l\'application'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In fr, this message translates to:
  /// **'Système'**
  String get languageSystem;

  /// No description provided for @notifications.
  ///
  /// In fr, this message translates to:
  /// **'NOTIFICATIONS'**
  String get notifications;

  /// No description provided for @dailySummary.
  ///
  /// In fr, this message translates to:
  /// **'Résumé quotidien (19h)'**
  String get dailySummary;

  /// No description provided for @testNotification.
  ///
  /// In fr, this message translates to:
  /// **'TESTER LA NOTIFICATION MAINTENANT'**
  String get testNotification;

  /// No description provided for @financialProfile.
  ///
  /// In fr, this message translates to:
  /// **'PROFIL FINANCIER'**
  String get financialProfile;

  /// No description provided for @monthlySalary.
  ///
  /// In fr, this message translates to:
  /// **'Salaire net mensuel'**
  String get monthlySalary;

  /// No description provided for @monthlyInvestment.
  ///
  /// In fr, this message translates to:
  /// **'Investissement mensuel'**
  String get monthlyInvestment;

  /// No description provided for @account.
  ///
  /// In fr, this message translates to:
  /// **'MON COMPTE'**
  String get account;

  /// No description provided for @about.
  ///
  /// In fr, this message translates to:
  /// **'À propos'**
  String get about;

  /// No description provided for @version.
  ///
  /// In fr, this message translates to:
  /// **'Version de l\'application'**
  String get version;

  /// No description provided for @logout.
  ///
  /// In fr, this message translates to:
  /// **'DÉCONNEXION'**
  String get logout;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'ANNULER'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In fr, this message translates to:
  /// **'SUPPRIMER'**
  String get delete;

  /// No description provided for @deleteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ?'**
  String get deleteTitle;

  /// No description provided for @confirmDelete.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous vraiment supprimer \'\'{name}\'\' ?'**
  String confirmDelete(Object name);

  /// No description provided for @noAccountsAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Aucun compte disponible'**
  String get noAccountsAvailable;

  /// No description provided for @usePlusButtonToStart.
  ///
  /// In fr, this message translates to:
  /// **'Utilisez le bouton + pour commencer'**
  String get usePlusButtonToStart;

  /// No description provided for @monthlyBudget.
  ///
  /// In fr, this message translates to:
  /// **'BUDGET MENSUEL'**
  String get monthlyBudget;

  /// No description provided for @financialFlows.
  ///
  /// In fr, this message translates to:
  /// **'Flux financiers'**
  String get financialFlows;

  /// No description provided for @income.
  ///
  /// In fr, this message translates to:
  /// **'REVENUS'**
  String get income;

  /// No description provided for @expenses.
  ///
  /// In fr, this message translates to:
  /// **'DÉPENSES'**
  String get expenses;

  /// No description provided for @noIncomeReported.
  ///
  /// In fr, this message translates to:
  /// **'Aucun revenu renseigné'**
  String get noIncomeReported;

  /// No description provided for @noExpenseReported.
  ///
  /// In fr, this message translates to:
  /// **'Aucune dépense renseignée'**
  String get noExpenseReported;

  /// No description provided for @other.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get other;

  /// No description provided for @addFlow.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un flux'**
  String get addFlow;

  /// No description provided for @editFlow.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le flux'**
  String get editFlow;

  /// No description provided for @incomeType.
  ///
  /// In fr, this message translates to:
  /// **'REVENU'**
  String get incomeType;

  /// No description provided for @expenseType.
  ///
  /// In fr, this message translates to:
  /// **'DÉPENSE'**
  String get expenseType;

  /// No description provided for @label.
  ///
  /// In fr, this message translates to:
  /// **'Libellé'**
  String get label;

  /// No description provided for @monthlyAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant mensuel'**
  String get monthlyAmount;

  /// No description provided for @category.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get category;

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'ENREGISTRER'**
  String get save;

  /// No description provided for @update.
  ///
  /// In fr, this message translates to:
  /// **'METTRE À JOUR'**
  String get update;

  /// No description provided for @retirementFire.
  ///
  /// In fr, this message translates to:
  /// **'RETRAITE & FIRE'**
  String get retirementFire;

  /// No description provided for @freedomGoal.
  ///
  /// In fr, this message translates to:
  /// **'Objectif Liberté'**
  String get freedomGoal;

  /// No description provided for @grossAnnualSimulations.
  ///
  /// In fr, this message translates to:
  /// **'Simulations en brut annuel.'**
  String get grossAnnualSimulations;

  /// No description provided for @yourAssumptions.
  ///
  /// In fr, this message translates to:
  /// **'VOS HYPOTHÈSES'**
  String get yourAssumptions;

  /// No description provided for @desiredIncome.
  ///
  /// In fr, this message translates to:
  /// **'Revenu souhaité'**
  String get desiredIncome;

  /// No description provided for @estimatedPension.
  ///
  /// In fr, this message translates to:
  /// **'Pension estimée'**
  String get estimatedPension;

  /// No description provided for @rate.
  ///
  /// In fr, this message translates to:
  /// **'Taux'**
  String get rate;

  /// No description provided for @needAndTarget.
  ///
  /// In fr, this message translates to:
  /// **'BESOIN & CIBLE'**
  String get needAndTarget;

  /// No description provided for @toFinance.
  ///
  /// In fr, this message translates to:
  /// **'À FINANCER'**
  String get toFinance;

  /// No description provided for @targetCapital.
  ///
  /// In fr, this message translates to:
  /// **'CAPITAL CIBLE'**
  String get targetCapital;

  /// No description provided for @capitalGenerationInfo.
  ///
  /// In fr, this message translates to:
  /// **'Avec un taux de {rate}%, ce capital génère {amount} / an.'**
  String capitalGenerationInfo(Object amount, Object rate);

  /// No description provided for @pensionCoversGoal.
  ///
  /// In fr, this message translates to:
  /// **'Votre pension couvre déjà votre objectif.'**
  String get pensionCoversGoal;

  /// No description provided for @current.
  ///
  /// In fr, this message translates to:
  /// **'Actuel'**
  String get current;

  /// No description provided for @reachedPercent.
  ///
  /// In fr, this message translates to:
  /// **'{percent}% atteint'**
  String reachedPercent(Object percent);

  /// No description provided for @remainingAmount.
  ///
  /// In fr, this message translates to:
  /// **'Reste : {amount}'**
  String remainingAmount(Object amount);

  /// No description provided for @resources.
  ///
  /// In fr, this message translates to:
  /// **'RESSOURCES'**
  String get resources;

  /// No description provided for @retirementInsurance.
  ///
  /// In fr, this message translates to:
  /// **'L\'Assurance Retraite'**
  String get retirementInsurance;

  /// No description provided for @estimatePensionOfficialSite.
  ///
  /// In fr, this message translates to:
  /// **'Estimer ma pension sur le site officiel'**
  String get estimatePensionOfficialSite;

  /// No description provided for @fillDesiredIncomePrompt.
  ///
  /// In fr, this message translates to:
  /// **'Renseignez votre revenu souhaité pour projeter votre capital cible.'**
  String get fillDesiredIncomePrompt;

  /// No description provided for @projectionTools.
  ///
  /// In fr, this message translates to:
  /// **'OUTILS DE PROJECTION'**
  String get projectionTools;

  /// No description provided for @simulators.
  ///
  /// In fr, this message translates to:
  /// **'Simulateurs'**
  String get simulators;

  /// No description provided for @realEstateSimulator.
  ///
  /// In fr, this message translates to:
  /// **'Simulateur Immobilier'**
  String get realEstateSimulator;

  /// No description provided for @calculatePurchaseCapacity.
  ///
  /// In fr, this message translates to:
  /// **'Calculez votre capacité d\'achat réelle'**
  String get calculatePurchaseCapacity;

  /// No description provided for @retirementSimulator.
  ///
  /// In fr, this message translates to:
  /// **'Simulateur Retraite'**
  String get retirementSimulator;

  /// No description provided for @projectIndependence.
  ///
  /// In fr, this message translates to:
  /// **'Projetez votre indépendance financière'**
  String get projectIndependence;

  /// No description provided for @realEstate.
  ///
  /// In fr, this message translates to:
  /// **'IMMOBILIER'**
  String get realEstate;

  /// No description provided for @simulator.
  ///
  /// In fr, this message translates to:
  /// **'Simulateur'**
  String get simulator;

  /// No description provided for @maxPurchaseCapacity.
  ///
  /// In fr, this message translates to:
  /// **'CAPACITÉ D\'ACHAT MAXIMALE'**
  String get maxPurchaseCapacity;

  /// No description provided for @monthlyPayment.
  ///
  /// In fr, this message translates to:
  /// **'Mensualité'**
  String get monthlyPayment;

  /// No description provided for @maxLoan.
  ///
  /// In fr, this message translates to:
  /// **'Prêt Maximum'**
  String get maxLoan;

  /// No description provided for @yourFinancialProfile.
  ///
  /// In fr, this message translates to:
  /// **'VOTRE PROFIL FINANCIER'**
  String get yourFinancialProfile;

  /// No description provided for @personalDownPayment.
  ///
  /// In fr, this message translates to:
  /// **'Apport Perso.'**
  String get personalDownPayment;

  /// No description provided for @loanParameters.
  ///
  /// In fr, this message translates to:
  /// **'PARAMÈTRES DU PRÊT'**
  String get loanParameters;

  /// No description provided for @duration.
  ///
  /// In fr, this message translates to:
  /// **'Durée'**
  String get duration;

  /// No description provided for @interestRate.
  ///
  /// In fr, this message translates to:
  /// **'Taux'**
  String get interestRate;

  /// No description provided for @exploreMarket.
  ///
  /// In fr, this message translates to:
  /// **'EXPLORER LE MARCHÉ'**
  String get exploreMarket;
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
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
