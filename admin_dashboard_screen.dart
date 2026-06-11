import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../utils/responsive.dart';
import '../validation_request.dart';

class AdminDashboardScreen extends StatefulWidget {
  final ValidationRequest? request;
  const AdminDashboardScreen({super.key, this.request});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  // Clave única para forzar la reconstrucción completa
  UniqueKey _listKey = UniqueKey();

  bool _isDetailMode = false;
  late ValidationRequest _editableRequest;
  String? _selectedDate;
  String? _selectedTime;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    if (widget.request != null) {
      _enterDetailMode(widget.request!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _enterDetailMode(ValidationRequest request) {
    setState(() {
      _isDetailMode = true;
      _editableRequest = request.copyWith();
      _selectedDate = _editableRequest.correctedDate ?? _editableRequest.originalDate;
      _selectedTime = _editableRequest.correctedEntryTime ?? _editableRequest.originalEntryTime;
    });
  }

  void _exitDetailMode() {
    setState(() {
      _isDetailMode = false;
      // Generar una nueva clave para forzar la reconstrucción completa de la lista
      _listKey = UniqueKey();
    });
  }

  void _updateDate(String newDate) {
    setState(() {
      _selectedDate = newDate;
      _editableRequest.correctedDate = newDate;
    });
  }

  void _updateTime(String newTime) {
    setState(() {
      _selectedTime = newTime;
      _editableRequest.correctedEntryTime = newTime;
    });
  }

  Future<void> _submitAction(String action) async {
    setState(() {
      _editableRequest.action = action;
    });

    await _persistRequest();

    final message = action == 'edited'
        ? 'Solicitud actualizada'
        : action == 'denied'
        ? 'Solicitud denegada'
        : action == 'validated'
        ? 'Solicitud validada'
        : 'Acción aplicada';

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _persistRequest() async {
    if (_editableRequest.id == null) {
      final id = await _databaseHelper.insertRequest(_editableRequest);
      _editableRequest.id = id;
    } else {
      await _databaseHelper.updateRequest(_editableRequest);
    }
  }

  // Nuevo método para eliminar solicitud
  Future<void> _deleteRequest() async {
    if (_editableRequest.id == null) return;
    
    await _databaseHelper.deleteRequest(_editableRequest.id!);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitud eliminada correctamente')),
      );
      // Salir del modo detalle y regresar a la lista
      _exitDetailMode();
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Estás seguro de eliminar la solicitud de ${_editableRequest.studentName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteRequest();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showConfirmation(String action, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirmar $action'),
        content: Text('¿Estás seguro de $action esta solicitud?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: Text(action),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveSize(context);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isDetailMode) {
          _exitDetailMode();
        } else {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            'VoluntApp - ${_isDetailMode ? 'Edición' : 'Administrador'}',
            style: TextStyle(
              fontSize: responsive.appBarTitleSize,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFAB0F0F),
              letterSpacing: -1.2,
              fontFamily: 'Inter',
            ),
          ),
          leading: _isDetailMode
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _exitDetailMode,
                )
              : null,
        ),
        body: _isDetailMode ? _buildDetailView(responsive) : _buildListView(responsive),
      ),
    );
  }

  Widget _buildListView(ResponsiveSize responsive) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(responsive.mediumSpacing),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, número de control...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<ValidationRequest>>(
            key: _listKey,
            future: _databaseHelper.getFilteredRequests(
              searchQuery: _searchQuery,
              career: null,
              group: null,
              turn: null,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text(
                    'No se encontraron registros',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                );
              }
              final requests = snapshot.data!;
              return ListView.builder(
                padding: EdgeInsets.all(responsive.mediumSpacing),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final req = requests[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: responsive.mediumSpacing),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(responsive.mediumSpacing),
                      title: Text(
                        req.studentName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: responsive.bodySize + 2,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('Núm. control: ${req.userControlNumber ?? 'N/A'}'),
                          Text('Carrera: ${req.career ?? 'N/A'} | Turno: ${req.turno ?? 'N/A'}'),
                          Text('Fecha original: ${req.originalDate}'),
                          Text('Entrada: ${req.originalEntryTime} | Salida: ${req.originalExitTime}'),
                          if (req.correctedDate != null || req.correctedEntryTime != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Correcciones: ${req.correctedDate != null ? 'Fecha: ${req.correctedDate}' : ''} ${req.correctedEntryTime != null ? 'Entrada: ${req.correctedEntryTime}' : ''}',
                                style: const TextStyle(fontSize: 12, color: Colors.blue),
                              ),
                            ),
                        ],
                      ),
                      trailing: Chip(
                        label: Text(
                          req.action == null ? 'Pendiente' : req.action!.toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: req.action == null
                            ? Colors.orange
                            : req.action == 'validated'
                            ? Colors.green
                            : req.action == 'denied'
                            ? Colors.red
                            : Colors.blue,
                      ),
                      onTap: () => _enterDetailMode(req),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDetailView(ResponsiveSize responsive) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(responsive.mediumSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Validación de datos',
            style: TextStyle(
              fontSize: responsive.screenTitleSize,
              fontWeight: FontWeight.w700,
              color: Colors.black,
              fontFamily: 'Inter',
            ),
          ),
          SizedBox(height: responsive.smallSpacing),
          Text(
            'Revisa y valida las horas de servicio social de los estudiantes.',
            style: TextStyle(
              fontSize: responsive.bodySize,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: responsive.largeSpacing),
          _buildRequestSummary(responsive),
          SizedBox(height: responsive.largeSpacing),
          _buildEditSection(responsive),
          SizedBox(height: responsive.largeSpacing),
          Text(
            'Acciones rápidas',
            style: TextStyle(
              fontSize: responsive.headingSize - 4,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          SizedBox(height: responsive.mediumSpacing),
          Wrap(
            spacing: responsive.mediumSpacing,
            runSpacing: responsive.mediumSpacing,
            alignment: WrapAlignment.start,
            children: [
              _buildActionButton('Guardar cambios', const Color(0xFF2563EB), responsive, () {
                _submitAction('edited');
              }),
              _buildActionButton('Denegar', Colors.red, responsive, () {
                _showConfirmation('denegar', () => _submitAction('denied'));
              }),
              _buildActionButton('Validar', Colors.green, responsive, () {
                _showConfirmation('validar', () => _submitAction('validated'));
              }),
              // Nuevo botón Eliminar
              _buildActionButton('Eliminar', Colors.grey, responsive, () {
                _showDeleteConfirmation();
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRequestSummary(ResponsiveSize responsive) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.04), blurRadius: 16, offset: Offset(0, 8))],
      ),
      padding: EdgeInsets.all(responsive.mediumSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _editableRequest.studentName,
                  style: TextStyle(fontSize: responsive.headingSize - 6, fontWeight: FontWeight.w700, color: Colors.black),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: responsive.smallSpacing, vertical: responsive.smallSpacing / 2),
                decoration: BoxDecoration(color: const Color(0xFFF4F6FA), borderRadius: BorderRadius.circular(14)),
                child: Text(
                  _editableRequest.action == null ? 'Pendiente' : _editableRequest.action!.toUpperCase(),
                  style: TextStyle(fontSize: responsive.smallSize, fontWeight: FontWeight.w700, color: Colors.grey[700]),
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.mediumSpacing),
          _buildSummaryRow('Fecha', _editableRequest.originalDate, responsive),
          SizedBox(height: responsive.smallSpacing),
          _buildSummaryRow('Entrada', _editableRequest.originalEntryTime, responsive),
          SizedBox(height: responsive.smallSpacing),
          _buildSummaryRow('Salida', _editableRequest.originalExitTime, responsive),
          if (_editableRequest.correctedDate != null ||
              _editableRequest.correctedEntryTime != null ||
              _editableRequest.correctedExitTime != null) ...[
            const Divider(height: 28),
            Text('Correcciones', style: TextStyle(fontSize: responsive.bodySize, fontWeight: FontWeight.w600, color: Colors.black)),
            SizedBox(height: responsive.smallSpacing),
            if (_editableRequest.correctedDate != null)
              _buildSummaryRow('Nueva fecha', _editableRequest.correctedDate!, responsive),
            if (_editableRequest.correctedEntryTime != null)
              _buildSummaryRow('Nueva entrada', _editableRequest.correctedEntryTime!, responsive),
            if (_editableRequest.correctedExitTime != null)
              _buildSummaryRow('Nueva salida', _editableRequest.correctedExitTime!, responsive),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, ResponsiveSize responsive) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: responsive.bodySize, fontWeight: FontWeight.w500, color: const Color.fromARGB(255, 255, 252, 252))),
        Text(value, style: TextStyle(fontSize: responsive.bodySize, fontWeight: FontWeight.w700, color: Colors.black)),
      ],
    );
  }

  Widget _buildEditSection(ResponsiveSize responsive) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.04), blurRadius: 16, offset: Offset(0, 8))],
      ),
      padding: EdgeInsets.all(responsive.mediumSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Editar solicitud', style: TextStyle(fontSize: responsive.bodySize + 2, fontWeight: FontWeight.w700, color: Colors.black)),
          SizedBox(height: responsive.mediumSpacing),
          Row(
            children: [
              Expanded(
                child: _buildSelectionField(
                  label: 'Fecha',
                  value: _selectedDate ?? 'Seleccionar fecha',
                  icon: Icons.calendar_today,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (!mounted) return;
                    if (date != null) {
                      _updateDate(date.toString().split(' ')[0]);
                    }
                  },
                  responsive: responsive,
                ),
              ),
              SizedBox(width: responsive.smallSpacing),
              Expanded(
                child: _buildSelectionField(
                  label: 'Hora',
                  value: _selectedTime ?? 'Seleccionar hora',
                  icon: Icons.schedule,
                  onTap: () async {
                    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                    if (!mounted) return;
                    if (time != null) {
                      final formattedTime = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                      _updateTime(formattedTime);
                    }
                  },
                  responsive: responsive,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionField({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
    required ResponsiveSize responsive,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: responsive.mediumSpacing, horizontal: responsive.mediumSpacing),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F6FA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE6E8EE)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color.fromARGB(255, 228, 100, 100), size: 20),
            SizedBox(width: responsive.smallSpacing),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: responsive.smallSize, fontWeight: FontWeight.w500, color: const Color.fromARGB(255, 188, 186, 186))),
                  SizedBox(height: responsive.smallSpacing / 2),
                  Text(value, style: TextStyle(fontSize: responsive.bodySize, fontWeight: FontWeight.w600, color: Colors.black)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, ResponsiveSize responsive, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(horizontal: responsive.mediumSpacing, vertical: responsive.smallSpacing),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onPressed,
      child: Text(label, style: TextStyle(fontSize: responsive.bodySize, fontWeight: FontWeight.w600, color: Colors.white)),
    );
  }
}