import 'package:flutter/material.dart';

import '../domain/models/procedure_models.dart';

/// Catalogue statique des démarches administratives — sans backend.
abstract final class ProcedureCatalog {
  static const guides = <ProcedureGuide>[
    ProcedureGuide(
      id: 'cin-renewal',
      title: 'Renouveler la CIN',
      summary:
          'Renouvellement de la Carte Nationale d\'Identité pour les Marocains '
          'résidant au Maroc ou à l\'étranger.',
      category: ProcedureCategory.identite,
      categoryLabel: 'Identité',
      estimatedDuration: '2 à 4 semaines',
      icon: Icons.badge_outlined,
      officialUrl: 'https://www.cnie.ma/',
      documents: [
        'Ancienne CIN ou récépissé de déclaration de perte',
        'Justificatif de domicile récent',
        'Photos d\'identité conformes',
        'Formulaire de demande rempli',
      ],
      steps: [
        'Prendre rendez-vous en ligne ou se présenter à la commune de résidence.',
        'Déposer le dossier complet au guichet dédié.',
        'Payer les frais administratifs et conserver le récépissé.',
        'Retirer la nouvelle CIN à la date indiquée sur le récépissé.',
      ],
    ),
    ProcedureGuide(
      id: 'residence-card',
      title: 'Carte de séjour',
      summary:
          'Demande ou renouvellement de la carte de séjour pour les étrangers '
          'résidant au Maroc.',
      category: ProcedureCategory.sejour,
      categoryLabel: 'Séjour',
      estimatedDuration: '1 à 3 mois',
      icon: Icons.card_membership_outlined,
      officialUrl: 'https://www.service-public.ma/',
      documents: [
        'Passeport en cours de validité',
        'Visa ou titre de séjour précédent',
        'Justificatif de domicile au Maroc',
        'Contrat de travail ou preuve de ressources',
        'Photos d\'identité',
      ],
      steps: [
        'Vérifier l\'éligibilité selon votre motif de séjour.',
        'Constituer le dossier et prendre rendez-vous à la préfecture.',
        'Déposer la demande et payer les droits de timbre.',
        'Suivre l\'instruction du dossier et retirer la carte de séjour.',
      ],
    ),
    ProcedureGuide(
      id: 'driving-license',
      title: 'Permis de conduire',
      summary:
          'Échange ou obtention du permis de conduire marocain pour les '
          'résidents et MRE.',
      category: ProcedureCategory.transport,
      categoryLabel: 'Transport',
      estimatedDuration: '2 à 6 semaines',
      icon: Icons.directions_car_outlined,
      officialUrl: 'https://www.service-public.ma/',
      documents: [
        'CIN ou carte de séjour en cours de validité',
        'Permis étranger original (si échange)',
        'Certificat médical d\'aptitude',
        'Photos d\'identité',
        'Justificatif de domicile',
      ],
      steps: [
        'Vérifier si votre pays a une convention d\'échange avec le Maroc.',
        'Passer le certificat médical dans un centre agréé.',
        'Déposer le dossier à la NARSA ou en préfecture.',
        'Retirer le permis marocain après validation du dossier.',
      ],
    ),
    ProcedureGuide(
      id: 'visa-extension',
      title: 'Prolongation de visa',
      summary:
          'Demande de prolongation d\'un visa de court séjour depuis le Maroc.',
      category: ProcedureCategory.sejour,
      categoryLabel: 'Séjour',
      estimatedDuration: '1 à 3 semaines',
      icon: Icons.flight_land_outlined,
      officialUrl: 'https://www.service-public.ma/',
      documents: [
        'Passeport et visa en cours de validité',
        'Motif détaillé de la prolongation',
        'Justificatif de moyens de subsistance',
        'Réservation de retour ou poursuite de voyage',
      ],
      steps: [
        'Déposer la demande avant l\'expiration du visa en cours.',
        'Se présenter à la Direction Générale de la Sûreté Nationale (DGSN).',
        'Fournir les justificatifs selon le motif (tourisme, affaires, etc.).',
        'Retirer le récépissé ou le visa prolongé.',
      ],
    ),
    ProcedureGuide(
      id: 'admission-temporaire',
      title: 'Admission temporaire véhicule',
      summary:
          'Importation temporaire d\'un véhicule étranger pour les MRE et '
          'touristes — validité limitée à 90 jours renouvelable.',
      category: ProcedureCategory.vehicule,
      categoryLabel: 'Véhicule',
      estimatedDuration: '1 à 2 jours',
      icon: Icons.local_shipping_outlined,
      officialUrl: 'https://www.douane.gov.ma/',
      documents: [
        'Passeport ou CIN',
        'Carte grise du véhicule',
        'Attestation d\'assurance internationale',
        'Permis de conduire valide',
      ],
      steps: [
        'Se présenter à la douane à l\'entrée du territoire ou en bureau local.',
        'Déclarer le véhicule et remplir le formulaire d\'admission temporaire.',
        'Payer la caution douanière si demandée.',
        'Conserver le document dans le véhicule — surveiller la date d\'expiration.',
      ],
    ),
    ProcedureGuide(
      id: 'birth-certificate',
      title: 'Extrait d\'acte de naissance',
      summary:
          'Demande d\'extrait d\'acte de naissance auprès de l\'officier d\'état '
          'civil de la commune de naissance.',
      category: ProcedureCategory.identite,
      categoryLabel: 'Identité',
      estimatedDuration: 'Quelques jours',
      icon: Icons.description_outlined,
      officialUrl: 'https://www.service-public.ma/',
      documents: [
        'CIN du demandeur',
        'Informations sur la personne concernée (nom, date, lieu de naissance)',
        'Justificatif de lien de parenté si demande pour un tiers',
      ],
      steps: [
        'Identifier la commune d\'enregistrement de la naissance.',
        'Déposer la demande au bureau d\'état civil ou en ligne si disponible.',
        'Payer les frais de légalisation si nécessaire.',
        'Retirer l\'extrait ou le recevoir par voie postale.',
      ],
    ),
    ProcedureGuide(
      id: 'tax-id',
      title: 'Identifiant fiscal (IF)',
      summary:
          'Obtention de l\'identifiant fiscal pour les résidents devant ouvrir '
          'un compte, acheter un bien ou exercer une activité.',
      category: ProcedureCategory.identite,
      categoryLabel: 'Identité',
      estimatedDuration: '1 à 2 semaines',
      icon: Icons.receipt_long_outlined,
      officialUrl: 'https://www.tax.gov.ma/',
      documents: [
        'CIN ou carte de séjour',
        'Justificatif de domicile',
        'Contrat de bail ou titre de propriété (si applicable)',
      ],
      steps: [
        'Créer un compte sur le portail de la Direction Générale des Impôts.',
        'Déposer la demande d\'identifiant fiscal en ligne ou en centre.',
        'Recevoir l\'IF par courrier ou le télécharger depuis le portail.',
        'Conserver l\'identifiant pour vos démarches bancaires et immobilières.',
      ],
    ),
    ProcedureGuide(
      id: 'cnss-registration',
      title: 'Affiliation CNSS',
      summary:
          'Affiliation à la Caisse Nationale de Sécurité Sociale pour les '
          'salariés et employeurs au Maroc.',
      category: ProcedureCategory.sejour,
      categoryLabel: 'Séjour',
      estimatedDuration: '2 à 4 semaines',
      icon: Icons.work_outline,
      officialUrl: 'https://www.cnss.ma/',
      documents: [
        'CIN ou carte de séjour de l\'employé',
        'Contrat de travail signé',
        'Identifiant fiscal de l\'employeur',
        'Registre de commerce (si applicable)',
      ],
      steps: [
        'L\'employeur crée un compte employeur sur le portail CNSS.',
        'Déclarer le salarié et transmettre le contrat de travail.',
        'Obtenir le numéro d\'immatriculation CNSS du salarié.',
        'Conserver l\'attestation pour les démarches médicales et retraite.',
      ],
    ),
  ];
}
