class UserModel {
  final String id;
  final String email;
  final String nombre;
  final String tipo; // 'CLIENTE' o 'EMPLEADO' (según el backend)
  final bool activo;
  
  // Datos específicos para empleados
  final String? empleadoId; // ID del empleado en la tabla empleados
  final String? microId;
  final String? placaMicro;
  final String? entidadId;
  final String? rutaAsignada;
  
  // Datos específicos para clientes
  final String? telefono;
  final String? direccion;

  UserModel({
    required this.id,
    required this.email,
    required this.nombre,
    required this.tipo,
    required this.activo,
    this.empleadoId,
    this.microId,
    this.placaMicro,
    this.entidadId,
    this.rutaAsignada,
    this.telefono,
    this.direccion,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Extraer datos del empleado si están presentes
    String? empleadoId;
    String? microId;
    String? placaMicro;
    String? entidadId;
    
    if (json.containsKey('empleado') && json['empleado'] != null) {
      final empleadoData = json['empleado'];
      empleadoId = empleadoData['id'];
      microId = empleadoData['id_micro'];
      entidadId = empleadoData['id_entidad'];
      
      // Extraer placa del micro si está en la lista de micros
      if (empleadoData.containsKey('micros') && 
          empleadoData['micros'] != null && 
          empleadoData['micros'] is List && 
          empleadoData['micros'].isNotEmpty) {
        placaMicro = empleadoData['micros'][0]['placa'];
      }
    }
    
    return UserModel(
      id: json['id'] ?? '',
      email: json['correo'] ?? '', // El backend usa 'correo', no 'email'
      nombre: json['nombre'] ?? '',
      tipo: json['tipo'] ?? 'CLIENTE',
      activo: json['activo'] ?? true,
      empleadoId: empleadoId,
      microId: microId,
      placaMicro: placaMicro,
      entidadId: entidadId,
      rutaAsignada: json['ruta_asignada'],
      telefono: json['telefono'],
      direccion: json['direccion'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'correo': email, // Usar 'correo' para ser consistente con el backend
      'nombre': nombre,
      'tipo': tipo,
      'activo': activo,
      'empleado_id': empleadoId,
      'micro_id': microId,
      'placa_micro': placaMicro,
      'entidad_id': entidadId,
      'ruta_asignada': rutaAsignada,
      'telefono': telefono,
      'direccion': direccion,
    };
  }

  bool get esMicrero => tipo == 'EMPLEADO'; // Cambiar a 'EMPLEADO'
  bool get esCliente => tipo == 'CLIENTE'; // Cambiar a 'CLIENTE'

  UserModel copyWith({
    String? id,
    String? email,
    String? nombre,
    String? tipo,
    bool? activo,
    String? empleadoId,
    String? microId,
    String? placaMicro,
    String? entidadId,
    String? rutaAsignada,
    String? telefono,
    String? direccion,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      nombre: nombre ?? this.nombre,
      tipo: tipo ?? this.tipo,
      activo: activo ?? this.activo,
      empleadoId: empleadoId ?? this.empleadoId,
      microId: microId ?? this.microId,
      placaMicro: placaMicro ?? this.placaMicro,
      entidadId: entidadId ?? this.entidadId,
      rutaAsignada: rutaAsignada ?? this.rutaAsignada,
      telefono: telefono ?? this.telefono,
      direccion: direccion ?? this.direccion,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, nombre: $nombre, tipo: $tipo, empleadoId: $empleadoId, microId: $microId, placaMicro: $placaMicro)';
  }
}

class Cliente {
  final String id;
  final String wallet_address;
  final List<dynamic>? registros;
  final List<dynamic>? notificaciones;
  final List<dynamic>? tarjetas;

  Cliente({
    required this.id,
    required this.wallet_address,
    this.registros,
    this.notificaciones,
    this.tarjetas,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
        id: json['id'] ?? '',
        wallet_address: json['wallet_address'] ?? '',
        registros: json['registros'],
        notificaciones: json['notificaciones'],
        tarjetas: json['tarjetas']);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'wallet_address': wallet_address,
      'registros': registros,
      'notificaciones': notificaciones,
      'tarjetas': tarjetas,
    };
  }
}

class Empleado {
  final String id;
  final String tipo; // CHOFER, ADMIN
  final String id_entidad;
  final String id_micro;

  Empleado({
    required this.id,
    required this.tipo,
    required this.id_entidad,
    required this.id_micro,
  });
  
  factory Empleado.fromJson(Map<String, dynamic> json) {
    print("Empleado JSON: $json");
    String idMicro = '';
    
    // Primero intentar obtener id_micro directamente
    if (json.containsKey('id_micro') && json['id_micro'] != null) {
      idMicro = json['id_micro'].toString();
    }
    // Si no está disponible, intentar extraerlo de la lista de micros
    else if (json.containsKey('micros') && 
        json['micros'] != null && 
        json['micros'] is List && 
        json['micros'].isNotEmpty &&
        json['micros'][0] is Map) {
      idMicro = json['micros'][0]['id']?.toString() ?? '';
    } else {
      print("No se encontró información de micros o formato incorrecto");
    }
    
    return Empleado(
      id: json['id']?.toString() ?? '',
      tipo: json['tipo']?.toString() ?? '',
      id_entidad: json['id_entidad']?.toString() ?? '',
      id_micro: idMicro,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tipo': tipo,
      'id_entidad': id_entidad,
      'id_micro': id_micro,
    };
  }
}
