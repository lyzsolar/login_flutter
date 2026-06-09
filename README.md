# Login Flutter - Seguridad Avanzada (RASP)

Este proyecto es una aplicación de Flutter diseñada con múltiples capas de autoprotección en tiempo de ejecución (RASP) y respuesta ante incidentes.

## Características de Seguridad Implementadas

### 1. Control de Inactividad y Cierre Seguro (C2-A3)
- **Monitoreo Global:** Captura de eventos de hardware (taps, scrolls y teclado) a nivel raíz.
- **Temporizador de Sesión:** Cierre automático tras 15 segundos de inactividad.
- **Navegación Destructiva:** Limpieza total del historial de navegación al expirar la sesión para evitar el acceso físico no autorizado.
- **Notificación de Seguridad:** Alerta persistente al usuario sobre la expiración de la sesión.

### 2. Wipe Remoto vía FCM (C2-A2)
- **Borrado de Datos:** Capacidad de eliminar toda la información sensible de forma remota mediante Firebase Cloud Messaging.
- **Almacenamiento Seguro:** Uso de `flutter_secure_storage` para proteger tokens y credenciales con cifrado de hardware.
- **Acción Específica:** Ejecución de limpieza mediante el payload `action: wipe_data`.

### 3. Protección de Entorno y Privacidad (C2-A1)
- **Anti-Screenshot:** Uso de `FLAG_SECURE` en Android para bloquear capturas y grabaciones de pantalla.
- **Detección de Fake GPS:** Bloqueo de la aplicación si se detectan ubicaciones simuladas o aplicaciones de "Mock Location" activas.

## Requisitos para Pruebas
1. Ejecutar `flutter pub get`.
2. Asegurarse de tener el archivo `google-services.json` en `android/app/`.
3. El Token de FCM se imprimirá en la consola al iniciar la aplicación para pruebas de Wipe Remoto.

## Integrantes
- Lyz Berenice [Tu Apellido]
