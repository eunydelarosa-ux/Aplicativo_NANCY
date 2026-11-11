// ===============================================================
// APLICATIVO NANCY
// Tabla de Aspirantes
// ===============================================================

import '../database_constants.dart';

class ApplicantTable {
  ApplicantTable._();

  static const String createTable =
      '''
    CREATE TABLE ${DatabaseConstants.applicantsTable} (

      ${DatabaseConstants.id}
        TEXT PRIMARY KEY,

      ${DatabaseConstants.documentType}
        TEXT NOT NULL,

      ${DatabaseConstants.documentNumber}
        TEXT NOT NULL,

      ${DatabaseConstants.firstName}
        TEXT NOT NULL,

      ${DatabaseConstants.lastName}
        TEXT NOT NULL,

      ${DatabaseConstants.birthDate}
        TEXT NOT NULL,

      ${DatabaseConstants.gender}
        TEXT NOT NULL,

      ${DatabaseConstants.schooling}
        TEXT,

      ${DatabaseConstants.program}
        TEXT NOT NULL,

      ${DatabaseConstants.phone}
        TEXT,

      ${DatabaseConstants.email}
        TEXT,

      ${DatabaseConstants.address}
        TEXT,

      ${DatabaseConstants.department}
        TEXT,

      ${DatabaseConstants.municipality}
        TEXT,

      ${DatabaseConstants.corregimiento}
        TEXT,

      ${DatabaseConstants.village}
        TEXT,

          ${DatabaseConstants.responsibleName}
        TEXT,

      ${DatabaseConstants.responsibleRole}
        TEXT,

      ${DatabaseConstants.responsibleCedula}
        TEXT,

      ${DatabaseConstants.applicantCreatedByUserId}
        INTEGER,

      ${DatabaseConstants.applicantSiteId}
        INTEGER,

      ${DatabaseConstants.observations}
        TEXT,
      ${DatabaseConstants.syncStatus}
        TEXT NOT NULL,

      ${DatabaseConstants.syncAttempts}
  INTEGER NOT NULL DEFAULT 0,

${DatabaseConstants.lastSyncAttempt}
  TEXT,

${DatabaseConstants.lastSyncError}
  TEXT,

${DatabaseConstants.syncedAt}
  TEXT,  

      ${DatabaseConstants.createdAt}
        TEXT NOT NULL,

      ${DatabaseConstants.updatedAt}
        TEXT NOT NULL,

      ${DatabaseConstants.isDeleted}
        INTEGER NOT NULL DEFAULT 0,

      ${DatabaseConstants.deletedAt}
        TEXT
    )
  ''';
}
