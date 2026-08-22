// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Patrimoine 360';

  @override
  String get navHome => 'Accueil';

  @override
  String get navBudget => 'Budget';

  @override
  String get navAnalysis => 'Analyse';

  @override
  String get navRetirement => 'Retraite';

  @override
  String get navSimulators => 'Outils';

  @override
  String get navProfile => 'Profil';

  @override
  String get totalGrossWealth => 'PATRIMOINE BRUT TOTAL';

  @override
  String get netWealth => 'Patrimoine net';

  @override
  String get investedAmount => 'Montant investi';

  @override
  String get investedPart => 'Part investie';

  @override
  String get performance => 'Performance';

  @override
  String get globalPerformance => 'Performance globale';

  @override
  String get detailsPatrimoine => 'Détails du patrimoine';

  @override
  String get netWealthConstituted => 'Patrimoine net constitué';

  @override
  String get netWealthEstimated => 'Patrimoine net estimé';

  @override
  String get analysisTitle => 'ANALYSE STRATÉGIQUE';

  @override
  String get independencePilot => 'Pilote d\'Indépendance';

  @override
  String get monthlyGains => 'GAINS MENSUELS ESTIMÉS';

  @override
  String get averageGenerated => 'Moyenne générée par vos actifs';

  @override
  String get needs => 'BESOINS';

  @override
  String get growth => 'CROISSANCE';

  @override
  String get liberty => 'LIBERTÉ';

  @override
  String get expenseCoverage => 'COUVERTURE DES DÉPENSES';

  @override
  String get investmentCoverage => 'COUVERTURE DE L\'INVESTISSEMENT';

  @override
  String get salaryCoverage => 'COUVERTURE DU SALAIRE';

  @override
  String get progression => 'Progression';

  @override
  String get objective => 'Objectif';

  @override
  String get appearance => 'APPARENCE';

  @override
  String get theme => 'Thème de l\'application';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get themeSystem => 'Adaptatif';

  @override
  String get language => 'Langue de l\'application';

  @override
  String get languageSystem => 'Système';

  @override
  String get notifications => 'NOTIFICATIONS';

  @override
  String get dailySummary => 'Résumé quotidien (19h)';

  @override
  String get testNotification => 'TESTER LA NOTIFICATION MAINTENANT';

  @override
  String get financialProfile => 'PROFIL FINANCIER';

  @override
  String get monthlySalary => 'Salaire net mensuel';

  @override
  String get monthlyInvestment => 'Investissement mensuel';

  @override
  String get account => 'MON COMPTE';

  @override
  String get about => 'À propos';

  @override
  String get version => 'Version de l\'application';

  @override
  String get logout => 'DÉCONNEXION';

  @override
  String get cancel => 'ANNULER';

  @override
  String get delete => 'SUPPRIMER';

  @override
  String get deleteTitle => 'Supprimer ?';

  @override
  String confirmDelete(Object name) {
    return 'Voulez-vous vraiment supprimer \'\'$name\'\' ?';
  }

  @override
  String get noAccountsAvailable => 'Aucun compte disponible';

  @override
  String get usePlusButtonToStart => 'Utilisez le bouton + pour commencer';

  @override
  String get monthlyBudget => 'BUDGET MENSUEL';

  @override
  String get financialFlows => 'Flux financiers';

  @override
  String get income => 'REVENUS';

  @override
  String get expenses => 'DÉPENSES';

  @override
  String get noIncomeReported => 'Aucun revenu renseigné';

  @override
  String get noExpenseReported => 'Aucune dépense renseignée';

  @override
  String get other => 'Autre';

  @override
  String get addFlow => 'Ajouter un flux';

  @override
  String get editFlow => 'Modifier le flux';

  @override
  String get incomeType => 'REVENU';

  @override
  String get expenseType => 'DÉPENSE';

  @override
  String get label => 'Libellé';

  @override
  String get monthlyAmount => 'Montant mensuel';

  @override
  String get category => 'Catégorie';

  @override
  String get save => 'ENREGISTRER';

  @override
  String get update => 'METTRE À JOUR';

  @override
  String get retirementFire => 'RETRAITE & FIRE';

  @override
  String get freedomGoal => 'Objectif Liberté';

  @override
  String get grossAnnualSimulations => 'Simulations en brut annuel.';

  @override
  String get yourAssumptions => 'VOS HYPOTHÈSES';

  @override
  String get desiredIncome => 'Revenu souhaité';

  @override
  String get estimatedPension => 'Pension estimée';

  @override
  String get rate => 'Taux';

  @override
  String get needAndTarget => 'BESOIN & CIBLE';

  @override
  String get toFinance => 'À FINANCER';

  @override
  String get targetCapital => 'CAPITAL CIBLE';

  @override
  String capitalGenerationInfo(Object amount, Object rate) {
    return 'Avec un taux de $rate%, ce capital génère $amount / an.';
  }

  @override
  String get pensionCoversGoal => 'Votre pension couvre déjà votre objectif.';

  @override
  String get current => 'Actuel';

  @override
  String reachedPercent(Object percent) {
    return '$percent% atteint';
  }

  @override
  String remainingAmount(Object amount) {
    return 'Reste : $amount';
  }

  @override
  String get resources => 'RESSOURCES';

  @override
  String get retirementInsurance => 'L\'Assurance Retraite';

  @override
  String get estimatePensionOfficialSite =>
      'Estimer ma pension sur le site officiel';

  @override
  String get fillDesiredIncomePrompt =>
      'Renseignez votre revenu souhaité pour projeter votre capital cible.';

  @override
  String get projectionTools => 'OUTILS DE PROJECTION';

  @override
  String get simulators => 'Simulateurs';

  @override
  String get realEstateSimulator => 'Simulateur Immobilier';

  @override
  String get calculatePurchaseCapacity =>
      'Calculez votre capacité d\'achat réelle';

  @override
  String get retirementSimulator => 'Simulateur Retraite';

  @override
  String get projectIndependence => 'Projetez votre indépendance financière';

  @override
  String get realEstate => 'IMMOBILIER';

  @override
  String get simulator => 'Simulateur';

  @override
  String get maxPurchaseCapacity => 'CAPACITÉ D\'ACHAT MAXIMALE';

  @override
  String get monthlyPayment => 'Mensualité';

  @override
  String get maxLoan => 'Prêt Maximum';

  @override
  String get yourFinancialProfile => 'VOTRE PROFIL FINANCIER';

  @override
  String get personalDownPayment => 'Apport Perso.';

  @override
  String get loanParameters => 'PARAMÈTRES DU PRÊT';

  @override
  String get duration => 'Durée';

  @override
  String get interestRate => 'Taux';

  @override
  String get exploreMarket => 'EXPLORER LE MARCHÉ';
}
