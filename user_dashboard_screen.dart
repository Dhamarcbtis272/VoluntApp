import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import '../database/database_helper.dart';
import '../validation_request.dart';
import '../models/user.dart';

class UserDashboardScreen extends StatefulWidget {
  final User user;
  const UserDashboardScreen({super.key, required this.user});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<ValidationRequest> _requests = [];
  int _validatedHours = 0;
  
  // Para registrar nueva jornada
  DateTime? _selectedDate;
  TimeOfDay? _selectedEntryTime;
  TimeOfDay? _selectedExitTime;
  
  // Para editar registro existente
  bool _isEditingMode = false;
  ValidationRequest? _editingRequest;
  DateTime? _editDate;
  TimeOfDay? _editEntryTime;
  TimeOfDay? _editExitTime;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    await _loadRequests();
    _validatedHours = await _db.getTotalValidatedHoursForUser(
      widget.user.controlNumber,
    );
    if (mounted) setState(() {});
  }

  Future<void> _loadRequests() async {
    _requests = await _db.getRequestsByUser(widget.user.controlNumber);
    if (mounted) setState(() {});
  }

  // ==================== REGISTRAR NUEVA JORNADA ====================
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }
  
  Future<void> _selectEntryTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedEntryTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedEntryTime = picked;
      });
    }
  }
  
  Future<void> _selectExitTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedExitTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedExitTime = picked;
      });
    }
  }

  // Función auxiliar para calcular diferencia de horas en minutos
  int _calculateMinutesDifference(TimeOfDay entry, TimeOfDay exit) {
    final entryMinutes = entry.hour * 60 + entry.minute;
    final exitMinutes = exit.hour * 60 + exit.minute;
    
    if (exitMinutes > entryMinutes) {
      return exitMinutes - entryMinutes;
    } else {
      // Si la salida es al día siguiente (ej: entrada 22:00, salida 02:00)
      return (24 * 60 - entryMinutes) + exitMinutes;
    }
  }

  Future<void> _saveJornada() async {
    if (_selectedDate == null ||
        _selectedEntryTime == null ||
        _selectedExitTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    // ✅ VALIDACIÓN: Calcular diferencia de horas (debe ser al menos 1 hora = 60 minutos)
    final diffMinutes = _calculateMinutesDifference(_selectedEntryTime!, _selectedExitTime!);
    
    if (diffMinutes < 60) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La jornada debe ser de al menos 1 hora de duración'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final dateStr =
        '${_selectedDate!.year.toString().padLeft(4, '0')}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
    final entryTimeStr =
        '${_selectedEntryTime!.hour.toString().padLeft(2, '0')}:${_selectedEntryTime!.minute.toString().padLeft(2, '0')}';
    final exitTimeStr =
        '${_selectedExitTime!.hour.toString().padLeft(2, '0')}:${_selectedExitTime!.minute.toString().padLeft(2, '0')}';

    final request = ValidationRequest(
      studentName: widget.user.name,
      originalDate: dateStr,
      originalEntryTime: entryTimeStr,
      originalExitTime: exitTimeStr,
      action: 'submitted',
      userControlNumber: widget.user.controlNumber,
      groupName: widget.user.groupName,
      career: widget.user.career,
      turno: widget.user.turno,
    );

    await _db.insertRequest(request);
    await _loadRequests();

    // Limpiar campos
    _selectedDate = null;
    _selectedEntryTime = null;
    _selectedExitTime = null;
    setState(() {});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jornada guardada exitosamente')),
      );
    }
  }

  // ==================== EDITAR REGISTRO EXISTENTE ====================
  void _startEditing(ValidationRequest request) {
    // Solo permitir editar si NO está validado
    if (request.action == 'validated') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede editar un registro ya validado'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Convertir fechas y horas existentes
    _editDate = DateTime.tryParse(request.originalDate);
    
    final entryParts = request.originalEntryTime.split(':');
    _editEntryTime = TimeOfDay(
      hour: int.parse(entryParts[0]),
      minute: int.parse(entryParts[1]),
    );
    
    final exitParts = request.originalExitTime.split(':');
    _editExitTime = TimeOfDay(
      hour: int.parse(exitParts[0]),
      minute: int.parse(exitParts[1]),
    );
    
    setState(() {
      _isEditingMode = true;
      _editingRequest = request;
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditingMode = false;
      _editingRequest = null;
      _editDate = null;
      _editEntryTime = null;
      _editExitTime = null;
    });
  }

  Future<void> _selectEditDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _editDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _editDate = picked;
      });
    }
  }

  Future<void> _selectEditEntryTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _editEntryTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _editEntryTime = picked;
      });
    }
  }

  Future<void> _selectEditExitTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _editExitTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _editExitTime = picked;
      });
    }
  }

  Future<void> _saveEdit() async {
    if (_editDate == null || _editEntryTime == null || _editExitTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    // ✅ VALIDACIÓN: Calcular diferencia de horas (debe ser al menos 1 hora = 60 minutos)
    final diffMinutes = _calculateMinutesDifference(_editEntryTime!, _editExitTime!);
    
    if (diffMinutes < 60) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La jornada debe ser de al menos 1 hora de duración'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final dateStr =
        '${_editDate!.year.toString().padLeft(4, '0')}-${_editDate!.month.toString().padLeft(2, '0')}-${_editDate!.day.toString().padLeft(2, '0')}';
    final entryTimeStr =
        '${_editEntryTime!.hour.toString().padLeft(2, '0')}:${_editEntryTime!.minute.toString().padLeft(2, '0')}';
    final exitTimeStr =
        '${_editExitTime!.hour.toString().padLeft(2, '0')}:${_editExitTime!.minute.toString().padLeft(2, '0')}';

    final updatedRequest = _editingRequest!.copyWith(
      originalDate: dateStr,
      originalEntryTime: entryTimeStr,
      originalExitTime: exitTimeStr,
      action: 'submitted',
    );

    await _db.updateRequest(updatedRequest);
    await _loadRequests();

    _cancelEditing();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro actualizado exitosamente')),
      );
    }
  }

  // ==================== ELIMINAR REGISTRO (solo no validados) ====================
  Future<void> _deleteRequest(ValidationRequest request) async {
    if (request.action == 'validated') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede eliminar un registro ya validado'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de eliminar el registro del ${request.originalDate}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _db.deleteRequest(request.id!);
              await _loadRequests();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Registro eliminado')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveSize(context);

    return Scaffold(
      backgroundColor: const Color(0xFFCDCDCD),
      appBar: AppBar(
        backgroundColor: Colors.grey[300],
        elevation: 0,
        title: Text(
          'VoluntApp',
          style: TextStyle(
            fontSize: responsive.appBarTitleSize,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFAB0F0F),
            letterSpacing: -1.2,
            fontFamily: 'Inter',
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: responsive.mediumSpacing),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Bienvenido',
                    style: TextStyle(
                      fontSize: responsive.smallSize,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    widget.user.name,
                    style: TextStyle(
                      fontSize: responsive.bodySize,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFAB0F0F),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(responsive.mediumSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mi Control de Horas',
              style: TextStyle(
                fontSize: responsive.headingSize,
                fontWeight: FontWeight.w600,
                color: Colors.black,
                fontFamily: 'Inter',
              ),
            ),
            SizedBox(height: responsive.largeSpacing),
            _buildSummaryCard(
              'Horas Validadas',
              '$_validatedHours',
              Colors.green,
              responsive,
            ),
            SizedBox(height: responsive.largeSpacing),
            
            // Mostrar formulario de edición si está activo
            if (_isEditingMode) ...[
              _buildEditForm(responsive),
              SizedBox(height: responsive.largeSpacing),
            ],
            
            // Mostrar formulario de nueva jornada solo si no está editando
            if (!_isEditingMode) ...[
              Text(
                'Registrar Jornada',
                style: TextStyle(
                  fontSize: responsive.headingSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: responsive.mediumSpacing),
              _buildDateSelector(responsive),
              SizedBox(height: responsive.mediumSpacing),
              _buildTimeSelector('Hora de Entrada', _selectedEntryTime, _selectEntryTime, responsive),
              SizedBox(height: responsive.mediumSpacing),
              _buildTimeSelector('Hora de Salida', _selectedExitTime, _selectExitTime, responsive),
              SizedBox(height: responsive.largeSpacing),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFAB0F0F),
                    padding: EdgeInsets.symmetric(vertical: responsive.mediumSpacing),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _saveJornada,
                  child: Text(
                    'Guardar Jornada',
                    style: TextStyle(
                      fontSize: responsive.bodySize,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
            
            SizedBox(height: responsive.largeSpacing),
            
            Text(
              'Mis Registros',
              style: TextStyle(
                fontSize: responsive.headingSize,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(height: responsive.mediumSpacing),
            
            if (_requests.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: responsive.mediumSpacing),
                child: Text('No hay registros todavía.'),
              ),
            for (final r in _requests) ...[
              _buildRegistryItem(r, responsive),
              SizedBox(height: responsive.smallSpacing),
            ],
            
            SizedBox(height: responsive.mediumSpacing),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  padding: EdgeInsets.symmetric(vertical: responsive.smallSpacing),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  'Cerrar Sesión',
                  style: TextStyle(
                    fontSize: responsive.bodySize,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector(ResponsiveSize responsive) {
    return Container(
      padding: EdgeInsets.all(responsive.mediumSpacing),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fecha',
            style: TextStyle(
              fontSize: responsive.bodySize,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: responsive.smallSpacing),
          InkWell(
            onTap: _selectDate,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.mediumSpacing,
                vertical: responsive.smallSpacing,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedDate == null
                        ? 'Seleccionar fecha'
                        : '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: responsive.bodySize,
                      color: _selectedDate == null ? Colors.grey[600] : Colors.black,
                    ),
                  ),
                  Icon(Icons.calendar_today, color: const Color(0xFFAB0F0F)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSelector(String label, TimeOfDay? selectedTime, VoidCallback onTap, ResponsiveSize responsive) {
    return Container(
      padding: EdgeInsets.all(responsive.mediumSpacing),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: responsive.bodySize,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: responsive.smallSpacing),
          InkWell(
            onTap: onTap,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.mediumSpacing,
                vertical: responsive.smallSpacing,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    selectedTime == null
                        ? 'Seleccionar hora'
                        : selectedTime.format(context),
                    style: TextStyle(
                      fontSize: responsive.bodySize,
                      color: selectedTime == null ? Colors.grey[600] : Colors.black,
                    ),
                  ),
                  Icon(Icons.access_time, color: const Color(0xFFAB0F0F)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm(ResponsiveSize responsive) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange, width: 2),
      ),
      padding: EdgeInsets.all(responsive.mediumSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit, color: Colors.orange),
              SizedBox(width: responsive.smallSpacing),
              Text(
                'Editando registro del ${_editingRequest?.originalDate}',
                style: TextStyle(
                  fontSize: responsive.bodySize,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.mediumSpacing),
          // Selector de fecha para edición
          InkWell(
            onTap: _selectEditDate,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.mediumSpacing,
                vertical: responsive.smallSpacing,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _editDate == null
                        ? 'Seleccionar fecha'
                        : '${_editDate!.year}-${_editDate!.month.toString().padLeft(2, '0')}-${_editDate!.day.toString().padLeft(2, '0')}',
                    style: TextStyle(fontSize: responsive.bodySize),
                  ),
                  Icon(Icons.calendar_today, color: const Color(0xFFAB0F0F)),
                ],
              ),
            ),
          ),
          SizedBox(height: responsive.mediumSpacing),
          // Selector de hora de entrada para edición
          InkWell(
            onTap: _selectEditEntryTime,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.mediumSpacing,
                vertical: responsive.smallSpacing,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _editEntryTime == null
                        ? 'Seleccionar hora de entrada'
                        : _editEntryTime!.format(context),
                    style: TextStyle(fontSize: responsive.bodySize),
                  ),
                  Icon(Icons.access_time, color: const Color(0xFFAB0F0F)),
                ],
              ),
            ),
          ),
          SizedBox(height: responsive.mediumSpacing),
          // Selector de hora de salida para edición
          InkWell(
            onTap: _selectEditExitTime,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.mediumSpacing,
                vertical: responsive.smallSpacing,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _editExitTime == null
                        ? 'Seleccionar hora de salida'
                        : _editExitTime!.format(context),
                    style: TextStyle(fontSize: responsive.bodySize),
                  ),
                  Icon(Icons.access_time, color: const Color(0xFFAB0F0F)),
                ],
              ),
            ),
          ),
          SizedBox(height: responsive.largeSpacing),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: responsive.smallSpacing),
                  ),
                  onPressed: _saveEdit,
                  child: const Text('Guardar cambios', style: TextStyle(color: Colors.white)),
                ),
              ),
              SizedBox(width: responsive.mediumSpacing),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    padding: EdgeInsets.symmetric(vertical: responsive.smallSpacing),
                  ),
                  onPressed: _cancelEditing,
                  child: const Text('Cancelar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRegistryItem(ValidationRequest request, ResponsiveSize responsive) {
    final bool isValidated = request.action == 'validated';
    
    return Container(
      padding: EdgeInsets.all(responsive.mediumSpacing),
      decoration: BoxDecoration(
        color: isValidated ? Colors.green[50] : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isValidated ? Colors.green : Colors.grey[300]!,
          width: isValidated ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.originalDate,
                      style: TextStyle(
                        fontSize: responsive.bodySize,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: responsive.smallSpacing),
                    Text(
                      'Entrada: ${request.originalEntryTime}  •  Salida: ${request.correctedExitTime ?? request.originalExitTime}',
                      style: TextStyle(
                        fontSize: responsive.smallSize,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (request.action == 'edited')
                      Padding(
                        padding: EdgeInsets.only(top: responsive.smallSpacing),
                        child: Chip(
                          label: Text(
                            'Editado por admin',
                            style: TextStyle(fontSize: responsive.smallSize, color: Colors.blue),
                          ),
                          backgroundColor: Colors.blue[100],
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    if (request.correctedDate != null || request.correctedEntryTime != null)
                      Padding(
                        padding: EdgeInsets.only(top: responsive.smallSpacing),
                        child: Text(
                          'Correcciones: ${request.correctedDate != null ? 'Fecha: ${request.correctedDate}' : ''} ${request.correctedEntryTime != null ? 'Entrada: ${request.correctedEntryTime}' : ''}',
                          style: TextStyle(fontSize: responsive.smallSize, color: Colors.blue),
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: isValidated ? Colors.green : request.action == 'denied' ? Colors.red : Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isValidated ? 'Validado' : request.action == 'denied' ? 'Denegado' : 'Pendiente',
                    style: TextStyle(
                      fontSize: responsive.smallSize,
                      fontWeight: FontWeight.w500,
                      color: isValidated ? Colors.green : request.action == 'denied' ? Colors.red : Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (!isValidated) ...[
            SizedBox(height: responsive.mediumSpacing),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                    ),
                    onPressed: () => _startEditing(request),
                    child: const Text('Editar'),
                  ),
                ),
                SizedBox(width: responsive.smallSpacing),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    onPressed: () => _deleteRequest(request),
                    child: const Text('Eliminar'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    Color color,
    ResponsiveSize responsive,
  ) {
    return Container(
      padding: EdgeInsets.all(responsive.mediumSpacing),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: responsive.bodySize,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: responsive.mediumSpacing,
              vertical: responsive.smallSpacing,
            ),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: responsive.headingSize,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}