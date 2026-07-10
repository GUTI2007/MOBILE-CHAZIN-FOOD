# Chazin Food - Sistema de Gestión 🍔📱

Aplicación móvil desarrollada con **Flutter** para la gestión integral de productos, ventas, control de inventario y operaciones de Chazin Food.

## 🚀 Características
- **Panel de Control (Dashboard):** Métricas y gráficos de rendimiento de ventas en tiempo real.
- **Gestión de Producción y Productos:** Catálogo completo de insumos y menús con formularios interactivos.
- **Administración de Ventas:** Visualización y procesamiento de órdenes de venta.
- **Modo Oscuro Integrado:** Interfaz adaptativa que responde a la preferencia del usuario o del sistema.
- **Navegación Dinámica:** Drawer lateral personalizado y Bottom Navigation Bar.
- **Inicio de Sesión Seguro:** Autenticación fluida con animación premium y scroll manual siempre disponible.

---

## 🛠️ Tecnologías y Librerías
- **Framework Principal:** [Flutter](https://flutter.dev) (SDK ^3.11.5)
- **Gestor de Estado:** [Riverpod](https://pub.dev/packages/flutter_riverpod)
- **Enrutamiento:** [GoRouter](https://pub.dev/packages/go_router)
- **Cliente HTTP:** [Dio](https://pub.dev/packages/dio)
- **Persistencia Segura:** [Flutter Secure Storage](https://pub.dev/packages/flutter_secure_storage)
- **Tipografía:** [Google Fonts (Poppins, Inter, Outfit)](https://pub.dev/packages/google_fonts)
- **Animaciones y UI:** Shimmer, Flutter Staggered Animations y Animated Text Kit.

---

## 📦 Configuración e Instalación

### Requisitos Previos
Asegúrate de tener Flutter SDK configurado correctamente en tu equipo:
```bash
flutter doctor
```

### Clonar e Instalar dependencias
1. Instala los paquetes de Flutter:
   ```bash
   flutter pub get
   ```
2. Genera los íconos del lanzador personalizados (en caso de realizar algún cambio sobre los logos):
   ```bash
   dart run flutter_launcher_icons
   ```

---

## 🏗️ Compilación y Despliegue

### Compilar APK para Android
Genera el paquete ejecutable optimizado para su instalación en dispositivos móviles:
```bash
flutter build apk --release
```
El archivo se generará en:
`build/app/outputs/flutter-apk/app-release.apk`

### Compilar para Web
Genera los archivos optimizados para subir a un servidor web:
```bash
flutter build web --release
```
El build final estará listo en:
`build/web`
