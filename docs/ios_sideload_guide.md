# Guía de Instalación Manual (.ipa) para iPhone desde Windows

Esta guía te guiará paso a paso para compilar la aplicación móvil **Chazin Food** en la nube con GitHub Actions y luego instalar el archivo `.ipa` resultante en tu iPhone utilizando **Sideloadly** desde tu computadora Windows.

---

## Parte 1: Cómo Compilar el archivo `.ipa` en GitHub

Una vez que hayas subido los cambios de tu proyecto a tu repositorio de GitHub (incluyendo la carpeta `.github/workflows/`), sigue estos pasos:

1. Entra a tu repositorio en **GitHub.com**.
2. Ve a la pestaña **Actions** en el menú superior.
3. En la barra lateral izquierda, selecciona el workflow llamado **Build iOS IPA (Unsigned)**.
4. A la derecha, haz clic en el menú desplegable **Run workflow** y presiona el botón verde **Run workflow** (usando la rama principal, por ejemplo `main`).
5. Espera unos minutos a que finalice la compilación (se pondrá un check verde).
6. Haz clic en el nombre de la ejecución de la compilación completada.
7. Baja hasta la sección **Artifacts** (Artefactos) en la parte inferior y haz clic en **ChazinFood-iOS-Unsigned** para descargar el archivo zip.
8. Descomprime el archivo zip en tu computadora para obtener el archivo `ChazinFood.ipa`.

---

## Parte 2: Preparación en Windows (Requisitos)

Para que tu PC Windows reconozca tu iPhone y permita firmar la aplicación localmente, debes instalar las siguientes aplicaciones oficiales de Apple en tu computadora (no uses las versiones de la Microsoft Store ya que no son compatibles con Sideloadly):

1. **iTunes (Versión clásica de instalador directo):**
   - [Descargar iTunes para Windows 64-bit](https://www.apple.com/itunes/download/win64) o [32-bit](https://www.apple.com/itunes/download/win32)
2. **iCloud (Versión clásica de instalador directo):**
   - [Descargar iCloud para Windows](https://updates.cdn-apple.com/2020/windows/001-39935-20200911-5D726D3C-F3F6-11EA-860D-C6C42D3C46B1/iCloudSetup.exe) (Enlace oficial de Apple).
3. **Instalar Sideloadly:**
   - Descarga e instala Sideloadly desde su sitio web oficial: [sideloadly.io](https://sideloadly.io/)

*Nota: Una vez instalado iTunes e iCloud, inicia sesión con tu cuenta de Apple en ambos y reinicia tu PC si es necesario.*

---

## Parte 3: Instalación del `.ipa` en tu iPhone

1. **Conecta tu iPhone** a tu PC Windows mediante cable USB.
2. Si te aparece un aviso en la pantalla del iPhone preguntando si confías en esta computadora, selecciona **Confiar** e introduce el código de bloqueo de tu dispositivo.
3. Abre **Sideloadly** en tu PC Windows.
4. Verifica que en el apartado **Device** aparezca detectado tu iPhone.
5. Haz clic en el icono grande de IPA a la izquierda (o arrastra y suelta el archivo `ChazinFood.ipa` directamente sobre el recuadro de Sideloadly).
6. En el campo **Apple Account**, introduce tu correo de **Apple ID** (el mismo que usas en tu iPhone).
7. Presiona el botón **Start**.
8. **Introducir Contraseña:** Sideloadly te pedirá la contraseña de tu Apple ID para autenticarse ante los servidores de Apple y firmar la app. 
   - *Tip de Seguridad:* Sideloadly es seguro y ampliamente utilizado, pero si lo prefieres, puedes usar un Apple ID secundario creado para pruebas o generar una contraseña específica de aplicación desde [appleid.apple.com](https://appleid.apple.com/).
9. Espera a que el progreso llegue al 100% y veas el mensaje **Done**. La aplicación aparecerá instalada en la pantalla de inicio de tu iPhone, pero aún no podrás abrirla.

---

## Parte 4: Autorizar la App en el iPhone (Paso Final)

Dado que la app se firmó con una cuenta gratuita, iOS requiere que autorices al desarrollador antes de abrirla:

1. En tu iPhone, ve a **Ajustes > General > Gestión de VPN y dispositivos** (o *Administración de dispositivos*).
2. Bajo la sección "App de desarrollador", verás tu correo de **Apple ID**. Tócalo.
3. Selecciona **Confiar en [tu_correo@ejemplo.com]** y confirma la acción en la ventana emergente.
4. **Habilitar Modo Desarrollador (Solo iOS 16 o superior):**
   - Ve a **Ajustes > Privacidad y seguridad**.
   - Desplázate hacia abajo hasta el final y toca en **Modo de desarrollador**.
   - Activa el interruptor y pulsa **Reiniciar** cuando lo solicite.
   - Tras reiniciarse el iPhone, desbloquéalo y toca en **Activar** en el mensaje que aparece en pantalla, e ingresa tu código de bloqueo.

¡Listo! Ya puedes abrir y utilizar la aplicación **Chazin Food** en tu iPhone de forma normal.

> [!NOTE]
> **Duración de la firma gratuita:** Las firmas con cuentas gratuitas de Apple ID duran **7 días**. Después de este tiempo la app se cerrará sola al intentar abrirla. Para reactivarla por otros 7 días, simplemente vuelve a conectar tu iPhone a la PC por USB, abre Sideloadly y presiona **Start** nuevamente (no se perderán tus datos ni configuraciones de la app).
