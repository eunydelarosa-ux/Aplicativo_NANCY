import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/site_model.dart';
import '../../providers/site_municipality_provider.dart';
import '../../providers/site_provider.dart';
import '../../../location/models/municipality_model.dart';
import '../../../location/providers/location_provider.dart';

class SiteManagementPage extends StatefulWidget {
  const SiteManagementPage({super.key});

  @override
  State<SiteManagementPage> createState() => _SiteManagementPageState();
}

class _SiteManagementPageState extends State<SiteManagementPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  int? _editingSiteId;
  final Set<int> _selectedMunicipalityIds = <int>{};

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final SiteProvider siteProvider = context.read<SiteProvider>();
    final LocationProvider locationProvider = context.read<LocationProvider>();

    await Future.wait([
      siteProvider.loadSites(),
      locationProvider.loadAllLocations(),
    ]);
  }

  Future<void> _openSiteForm({SiteModel? site}) async {
    _editingSiteId = site?.id;

    _nameController.text = site?.name ?? '';
    _addressController.text = site?.address ?? '';

    _selectedMunicipalityIds.clear();

    if (site?.id != null) {
      final SiteMunicipalityProvider relationProvider = context
          .read<SiteMunicipalityProvider>();

      await relationProvider.loadMunicipalitiesBySite(site!.id!);

      _selectedMunicipalityIds.addAll(relationProvider.municipalityIds);
    }

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return _buildSiteForm(sheetContext);
      },
    );

    _editingSiteId = null;
    _nameController.clear();
    _addressController.clear();
    _selectedMunicipalityIds.clear();
  }

  Future<void> _saveSite() async {
    final String name = _nameController.text.trim();
    final String address = _addressController.text.trim();

    if (name.isEmpty) {
      _showMessage('Ingrese el nombre de la sede.');
      return;
    }

    final SiteProvider siteProvider = context.read<SiteProvider>();
    final SiteMunicipalityProvider relationProvider = context
        .read<SiteMunicipalityProvider>();

    final DateTime now = DateTime.now();

    bool success;

    if (_editingSiteId == null) {
      success = await siteProvider.createSite(
        name: name,
        address: address.isEmpty ? null : address,
      );

      if (success) {
        final SiteModel? createdSite = siteProvider.sites
            .where((SiteModel item) => item.name == name)
            .cast<SiteModel?>()
            .firstOrNull;

        if (createdSite?.id != null) {
          await relationProvider.replaceMunicipalities(
            siteId: createdSite!.id!,
            municipalityIds: _selectedMunicipalityIds.toList(),
          );
        }
      }
    } else {
      final SiteModel? existingSite = siteProvider.sites
          .where((SiteModel item) => item.id == _editingSiteId)
          .cast<SiteModel?>()
          .firstOrNull;

      if (existingSite == null) {
        _showMessage('No fue posible encontrar la sede.');
        return;
      }

      final SiteModel updatedSite = existingSite.copyWith(
        name: name,
        address: address.isEmpty ? null : address,
        updatedAt: now,
      );

      success = await siteProvider.updateSite(site: updatedSite);

      if (success) {
        await relationProvider.replaceMunicipalities(
          siteId: _editingSiteId!,
          municipalityIds: _selectedMunicipalityIds.toList(),
        );
      }
    }

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      _showMessage(
        _editingSiteId == null
            ? 'Sede creada correctamente.'
            : 'Sede actualizada correctamente.',
      );
    } else {
      _showMessage(
        siteProvider.errorMessage ?? 'No fue posible guardar la sede.',
      );
    }
  }

  Future<void> _toggleSite(SiteModel site) async {
    if (site.id == null) return;

    final SiteProvider provider = context.read<SiteProvider>();

    final bool success = await provider.setSiteActive(
      siteId: site.id!,
      active: !site.active,
    );
    if (!mounted) return;

    if (success) {
      _showMessage(site.active ? 'Sede desactivada.' : 'Sede activada.');
    } else {
      _showMessage(
        provider.errorMessage ?? 'No fue posible actualizar la sede.',
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildSiteForm(BuildContext sheetContext) {
    final LocationProvider locationProvider = context.watch<LocationProvider>();

    final List<MunicipalityModel> municipalities = locationProvider
        .municipalities
        .where((MunicipalityModel municipality) => municipality.id != null)
        .toList();

    final bool isEditing = _editingSiteId != null;

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setModalState) {
        return SafeArea(
          child: Container(
            constraints: const BoxConstraints(maxHeight: 700),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isEditing ? 'Editar sede' : 'Nueva sede',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la sede',
                      prefixIcon: Icon(Icons.location_city_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _addressController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Dirección',
                      prefixIcon: Icon(Icons.place_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Municipios de la sede',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Selecciona los municipios que pertenecen a esta sede.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  if (municipalities.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text('No hay municipios disponibles.'),
                      ),
                    )
                  else
                    ...municipalities.map((MunicipalityModel municipality) {
                      final int municipalityId = municipality.id!;

                      return CheckboxListTile(
                        value: _selectedMunicipalityIds.contains(
                          municipalityId,
                        ),
                        title: Text(municipality.name),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (bool? selected) {
                          setModalState(() {
                            if (selected == true) {
                              _selectedMunicipalityIds.add(municipalityId);
                            } else {
                              _selectedMunicipalityIds.remove(municipalityId);
                            }
                          });
                        },
                      );
                    }),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveSite,
                      icon: const Icon(Icons.save_outlined),
                      label: Text(isEditing ? 'Guardar cambios' : 'Crear sede'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSiteCard(SiteModel site) {
    final bool active = site.active;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.location_city_outlined,
                    color: Color(0xFF8B5CF6),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        site.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (site.address != null &&
                          site.address!.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          site.address!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: active
                              ? Colors.green.withValues(alpha: 0.10)
                              : Colors.red.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          active ? 'Activa' : 'Inactiva',
                          style: TextStyle(
                            color: active
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (String value) {
                    if (value == 'edit') {
                      _openSiteForm(site: site);
                    } else if (value == 'toggle') {
                      _toggleSite(site);
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return [
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Editar'),
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'toggle',
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            active
                                ? Icons.block_outlined
                                : Icons.check_circle_outline,
                          ),
                          title: Text(active ? 'Desactivar' : 'Activar'),
                        ),
                      ),
                    ];
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final SiteProvider siteProvider = context.watch<SiteProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gestión de Sedes',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openSiteForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva sede'),
      ),
      body: siteProvider.isLoading && siteProvider.sites.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : siteProvider.sites.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                itemCount: siteProvider.sites.length,
                itemBuilder: (BuildContext context, int index) {
                  return _buildSiteCard(siteProvider.sites[index]);
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_city_outlined,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay sedes registradas',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea la primera sede para comenzar a asociar municipios.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _openSiteForm(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Crear sede'),
            ),
          ],
        ),
      ),
    );
  }
}
