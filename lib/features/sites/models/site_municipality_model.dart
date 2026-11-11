// ===============================================================
// APLICATIVO NANCY
// Modelo de relación Sede - Municipio
// ===============================================================

class SiteMunicipalityModel {
  final int siteId;
  final int municipalityId;

  const SiteMunicipalityModel({
    required this.siteId,
    required this.municipalityId,
  });

  // =============================================================
  // CONVERTIR MODELO → MAP
  // =============================================================

  Map<String, dynamic> toMap() {
    return {'site_id': siteId, 'municipality_id': municipalityId};
  }

  // =============================================================
  // CONVERTIR MAP → MODELO
  // =============================================================

  factory SiteMunicipalityModel.fromMap(Map<String, dynamic> map) {
    return SiteMunicipalityModel(
      siteId: map['site_id'] as int,
      municipalityId: map['municipality_id'] as int,
    );
  }
}
