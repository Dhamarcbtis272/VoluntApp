import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../utils/responsive.dart';
import '../validation_request.dart';
import 'admin_dashboard_screen.dart';

class AdminRequestsListScreen extends StatefulWidget {
  const AdminRequestsListScreen({super.key});

  @override
  State<AdminRequestsListScreen> createState() =>
      _AdminRequestsListScreenState();
}

class _AdminRequestsListScreenState extends State<AdminRequestsListScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final TextEditingController _searchController = TextEditingController();
  List<ValidationRequest> _requests = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
    _loadRequests();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    final requests = await _databaseHelper.getAllRequests();
    if (requests.isEmpty) {
      await _seedRequests();
      final seededRequests = await _databaseHelper.getAllRequests();
      setState(() {
        _requests = seededRequests;
      });
      return;
    }
    setState(() {
      _requests = requests;
    });
  }

  List<ValidationRequest> get _filteredRequests {
    if (_searchQuery.isEmpty) return _requests;
    return _requests.where((request) {
      final name = request.studentName.toLowerCase();
      final group = (request.groupName ?? '').toLowerCase();
      final career = (request.career ?? '').toLowerCase();
      final turno = (request.turno ?? '').toLowerCase();
      return name.contains(_searchQuery) ||
          group.contains(_searchQuery) ||
          career.contains(_searchQuery) ||
          turno.contains(_searchQuery);
    }).toList();
  }

  Future<void> _seedRequests() async {
    final sampleRequests = [
      ValidationRequest(
        studentName: 'María López',
        originalDate: '2026-05-27',
        originalEntryTime: '09:00',
        originalExitTime: '13:00',
        groupName: 'A1',
        career: 'Ingeniería',
        turno: 'matutino',
      ),
      ValidationRequest(
        studentName: 'Carlos Pérez',
        originalDate: '2026-05-28',
        originalEntryTime: '08:45',
        originalExitTime: '12:45',
        action: 'edited',
        correctedDate: '2026-05-28',
        correctedEntryTime: '09:00',
        correctedExitTime: '13:00',
        groupName: 'B2',
        career: 'Administración',
        turno: 'vespertino',
      ),
      ValidationRequest(
        studentName: 'Ana Torres',
        originalDate: '2026-05-29',
        originalEntryTime: '09:30',
        originalExitTime: '13:30',
        action: 'validated',
        groupName: 'A1',
        career: 'Ingeniería',
        turno: 'matutino',
      ),
    ];

    for (final request in sampleRequests) {
      await _databaseHelper.insertRequest(request);
    }
  }

  Future<void> _saveRequest(ValidationRequest request) async {
    if (request.id == null) {
      await _databaseHelper.insertRequest(request);
    } else {
      await _databaseHelper.updateRequest(request);
    }
  }

  void _openRequestDetail(ValidationRequest request) async {
    final updatedRequest = await Navigator.push<ValidationRequest>(
      context,
      MaterialPageRoute(
        builder: (context) => AdminDashboardScreen(request: request),
      ),
    );
    if (updatedRequest != null) {
      await _saveRequest(updatedRequest);
      setState(() {
        final index = _requests.indexWhere((r) => r.id == updatedRequest.id);
        if (index != -1) {
          _requests[index] = updatedRequest;
        }
      });
    }
  }

  void _setRequestAction(ValidationRequest request, String action) async {
    final updatedRequest = request.copyWith(action: action);
    await _saveRequest(updatedRequest);
    setState(() {
      final index = _requests.indexWhere((r) => r.id == updatedRequest.id);
      if (index != -1) {
        _requests[index] = updatedRequest;
      }
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Solicitud ${request.studentName} ${action == 'validated'
                ? 'validada'
                : action == 'denied'
                ? 'denegada'
                : 'actualizada'}',
          ),
        ),
      );
    }
  }

  void _showConfirmation(ValidationRequest request, String action) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          action == 'validated' ? 'Validar solicitud' : 'Denegar solicitud',
        ),
        content: Text(
          '¿Estás seguro de ${action == 'validated' ? 'validar' : 'denegar'} esta solicitud?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _setRequestAction(request, action);
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  String _studentInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return parts
        .take(2)
        .map((part) => part.substring(0, 1).toUpperCase())
        .join();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveSize(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'VoluntApp',
          style: TextStyle(
            fontSize: responsive.appBarTitleSize,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFAB0F0F),
            letterSpacing: -1.2,
            fontFamily: 'Inter',
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(responsive.mediumSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Validación de datos - Administrador',
              style: TextStyle(
                fontSize: responsive.screenTitleSize,
                fontWeight: FontWeight.w700,
                color: Colors.black,
                fontFamily: 'Inter',
              ),
            ),
            SizedBox(height: responsive.smallSpacing / 2),
            Text(
              'Revisa y valida las solicitudes de horas de servicio social.',
              style: TextStyle(
                fontSize: responsive.bodySize,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: responsive.mediumSpacing),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar por nombre, carrera, grupo o turno',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            SizedBox(height: responsive.largeSpacing),
            Text(
              'Registros existentes',
              style: TextStyle(
                fontSize: responsive.headingSize,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            SizedBox(height: responsive.mediumSpacing),
            Expanded(
              child: _filteredRequests.isEmpty
                  ? Center(
                      child: Text(
                        _searchQuery.isEmpty
                            ? 'No hay registros todavía.'
                            : 'No se encontraron registros para "$_searchQuery".',
                        style: TextStyle(
                          fontSize: responsive.bodySize,
                          color: Colors.grey[700],
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _filteredRequests.length,
                      separatorBuilder: (context, index) =>
                          SizedBox(height: responsive.mediumSpacing),
                      itemBuilder: (context, index) {
                        final request = _filteredRequests[index];
                  final status = request.action == null
                      ? 'Pendiente'
                      : request.action == 'validated'
                      ? 'Validada'
                      : request.action == 'denied'
                      ? 'Denegada'
                      : 'Editada';
                  final statusColor = request.action == 'validated'
                      ? Colors.green
                      : request.action == 'denied'
                      ? Colors.red
                      : Colors.orange;

                  return InkWell(
                    onTap: () => _openRequestDetail(request),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromRGBO(0, 0, 0, 0.04),
                            blurRadius: 16,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(responsive.mediumSpacing),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: responsive.mediumSpacing + 2,
                                backgroundColor: statusColor.withValues(
                                  alpha: 0.18,
                                ),
                                child: Text(
                                  _studentInitials(request.studentName),
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              SizedBox(width: responsive.mediumSpacing),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      request.studentName,
                                      style: TextStyle(
                                        fontSize: responsive.bodySize + 2,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black,
                                      ),
                                    ),
                                    SizedBox(
                                      height: responsive.smallSpacing / 2,
                                    ),
                                    Text(
                                      '${request.originalDate} · ${request.originalEntryTime} - ${request.originalExitTime}',
                                      style: TextStyle(
                                        fontSize: responsive.smallSize,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: responsive.smallSpacing,
                                  vertical: responsive.smallSpacing / 2,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    fontSize: responsive.smallSize,
                                    fontWeight: FontWeight.w600,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (request.correctedDate != null ||
                              request.correctedEntryTime != null ||
                              request.correctedExitTime != null) ...[
                            const Divider(height: 24),
                            Text(
                              'Correcciones',
                              style: TextStyle(
                                fontSize: responsive.bodySize,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: responsive.smallSpacing / 2),
                            if (request.correctedDate != null)
                              Text(
                                'Fecha: ${request.correctedDate}',
                                style: TextStyle(
                                  fontSize: responsive.smallSize,
                                  color: Colors.grey[700],
                                ),
                              ),
                            if (request.correctedEntryTime != null)
                              Text(
                                'Entrada: ${request.correctedEntryTime}',
                                style: TextStyle(
                                  fontSize: responsive.smallSize,
                                  color: Colors.grey[700],
                                ),
                              ),
                            if (request.correctedExitTime != null)
                              Text(
                                'Salida: ${request.correctedExitTime}',
                                style: TextStyle(
                                  fontSize: responsive.smallSize,
                                  color: Colors.grey[700],
                                ),
                              ),
                          ],
                          SizedBox(height: responsive.mediumSpacing),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Color(0xFFAB0F0F),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      vertical: responsive.smallSpacing,
                                    ),
                                  ),
                                  onPressed: () => _openRequestDetail(request),
                                  child: const Text('Editar'),
                                ),
                              ),
                              SizedBox(width: responsive.smallSpacing),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFAB0F0F),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      vertical: responsive.smallSpacing,
                                    ),
                                  ),
                                  onPressed: () =>
                                      _showConfirmation(request, 'validated'),
                                  child: const Text('Validar'),
                                ),
                              ),
                              SizedBox(width: responsive.smallSpacing),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF616161),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      vertical: responsive.smallSpacing,
                                    ),
                                  ),
                                  onPressed: () =>
                                      _showConfirmation(request, 'denied'),
                                  child: const Text('Denegar'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
