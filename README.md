# Daylyo

<div align="center">

![Daylyo](https://img.shields.io/badge/Daylyo-v0.1.0-blue)
![Flutter](https://img.shields.io/badge/Flutter-3.9.2+-02569B?logo=flutter)
![License](https://img.shields.io/badge/license-Private-red)

**Construye hábitos, día a día**

Una aplicación móvil para crear rutinas personalizadas, hacer seguimiento de tu progreso y mantener un diario personal.

</div>

---

## 📱 Descripción

Daylyo es una aplicación móvil desarrollada en Flutter que te ayuda a construir y mantener hábitos saludables a través de rutinas personalizadas. Con un diseño moderno y una interfaz intuitiva, Daylyo te permite organizar tu día, hacer seguimiento de tu progreso y reflexionar sobre tu crecimiento personal.

## ✨ Características Principales

### 🎯 Rutinas Personalizadas

- Crea rutinas con múltiples tareas
- Define horarios y recordatorios
- Personaliza con iconos y colores
- Organiza tus rutinas según tus necesidades

### 📊 Seguimiento de Progreso

- Visualiza estadísticas detalladas
- Mantén rachas de días consecutivos
- Gráficos de progreso
- Celebra tus logros

### 📝 Anotaciones del Día

- Registra tu estado de ánimo
- Elige el color que representa tu día
- Nivel de energía
- Momentos de gratitud
- Notas personales opcionales

### 🔔 Notificaciones

- Recordatorios personalizables
- Notificaciones locales
- Configuración flexible

### 📱 Widgets

- Widget para pantalla de inicio
- Muestra tu racha actual
- Próxima rutina programada

### 🎨 Personalización

- Múltiples paletas de colores pastel
- Temas personalizables
- Interfaz moderna y atractiva

### 💾 Almacenamiento Local

- Funciona completamente offline
- Datos almacenados localmente
- Exporta e importa tus datos
- Privacidad garantizada

## 🛠️ Tecnologías Utilizadas

- **Flutter** 3.9.2+ - Framework multiplataforma
- **Riverpod** 2.5.1 - Gestión de estado
- **Hive** 2.2.3 - Base de datos local NoSQL
- **Google Mobile Ads** 3.1.0 - Publicidad
- **Flutter Local Notifications** 17.1.2 - Notificaciones locales
- **Home Widget** 0.8.1 - Widgets para pantalla de inicio
- **Google Fonts** 6.1.0 - Tipografías personalizadas
- **Intl** 0.20.2 - Internacionalización

## 📋 Requisitos

- Flutter SDK 3.9.2 o superior
- Dart SDK 3.9.2 o superior
- Android Studio / VS Code con extensiones de Flutter
- Android SDK (para desarrollo Android)
- Xcode (para desarrollo iOS, solo macOS)

## 🚀 Instalación

### 1. Clonar el repositorio

```bash
git clone https://github.com/tu-usuario/rutina_diaria.git
cd rutina_diaria
```

### 2. Instalar dependencias

```bash
flutter pub get
```

### 3. Configurar la aplicación

#### Android

1. Configurar el keystore para firmar la app (opcional para release):

   - Crear archivo `android/key.properties` con:

   ```properties
   storePassword=tu_password
   keyPassword=tu_password
   keyAlias=tu_alias
   storeFile=../keystore/tu_keystore.jks
   ```

2. Configurar AdMob (si aplica):
   - El Application ID ya está configurado en `AndroidManifest.xml`
   - Los Ad Unit IDs están en `lib/services/ads_service.dart`

#### iOS

1. Configurar AdMob en `ios/Runner/Info.plist`
2. Ejecutar `pod install` en la carpeta `ios/`

### 4. Ejecutar la aplicación

```bash
# Modo desarrollo
flutter run

# Modo release (Android)
flutter build apk --release

# App Bundle para Play Store
flutter build appbundle --release

# iOS
flutter build ios --release
```

## 📁 Estructura del Proyecto

```
lib/
├── main.dart                 # Punto de entrada de la aplicación
├── models/                   # Modelos de datos
│   ├── routine_model.dart
│   ├── task_model.dart
│   └── journal_model.dart
├── providers/                # Providers de Riverpod
│   └── routine_controller.dart
├── screens/                  # Pantallas de la aplicación
│   ├── home_screen.dart
│   ├── settings_screen.dart
│   ├── journal_screen.dart
│   ├── stats_screen.dart
│   └── ...
├── services/                 # Servicios
│   ├── storage_service.dart
│   ├── notifications_service.dart
│   ├── ads_service.dart
│   └── widget_service.dart
├── utils/                    # Utilidades
│   ├── app_theme.dart
│   └── ...
└── widgets/                  # Widgets reutilizables
    └── ...
```

## 🔧 Configuración

### Variables de Entorno

No se requieren variables de entorno. La aplicación funciona completamente offline.

### AdMob

Los IDs de AdMob están configurados en:

- `android/app/src/main/AndroidManifest.xml` (Application ID)
- `ios/Runner/Info.plist` (Application ID)
- `lib/services/ads_service.dart` (Ad Unit IDs)

## 📦 Build y Release

### Android

```bash
# Limpiar build anterior
flutter clean

# Build App Bundle para Play Store
flutter build appbundle --release

# Build APK
flutter build apk --release
```

El archivo se generará en `build/app/outputs/bundle/release/app-release.aab`

### iOS

```bash
flutter build ios --release
```

## 🧪 Testing

```bash
# Ejecutar tests
flutter test

# Ejecutar con cobertura
flutter test --coverage
```

## 📄 Licencia

Este proyecto es privado y no está disponible para uso público.

## 👤 Autor

**Diego Barbecho**

- Email: diegobarbecho133@gmail.com

## 🙏 Agradecimientos

- Flutter team por el excelente framework
- Comunidad de Flutter por el apoyo y recursos
- Todos los desarrolladores de los paquetes utilizados

## 📝 Notas

- La aplicación funciona completamente offline
- Todos los datos se almacenan localmente en el dispositivo
- Se requiere conexión a internet solo para mostrar anuncios (AdMob)
- La exportación/importación de datos está disponible para respaldos

## 🔗 Enlaces

- [Política de Privacidad](https://tu-usuario.github.io/daylyo-privacy/)
- [Soporte](mailto:diegobarbecho133@gmail.com)

---

<div align="center">

Hecho con ❤️ usando Flutter

</div>
