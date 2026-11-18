# 🧪 QA Automation — Chazin Food Mobile

Script de auditoría automática con **Playwright** para la app Flutter Web de Chazin Food.

## Requisitos

- Node.js ≥ 18
- La app Flutter corriendo localmente (`flutter run -d chrome`)

## Instalación

```bash
cd qa
npm install
npm run install:browsers   # descarga Chromium para Playwright
```

## Uso

```bash
# Con la URL por defecto (localhost:52562)
npm run audit

# Con una URL personalizada
node chazin-audit.js http://localhost:PUERTO
```

## Qué hace el script

| Paso | Descripción |
|------|-------------|
| 1 | Carga la app y espera que Flutter Web renderice |
| 2 | Detecta y prueba la pantalla de Login |
| 3 | Valida el Dashboard y sus KPIs |
| 4 | Navega a Gestión de Productos |
| 5 | Abre el modal "Crear Evento" y verifica que renderice |
| 6 | Rellena el formulario del modal |
| 7 | Audita accesibilidad (aria-labels) |
| 8 | Mide performance (tiempos de carga) |

## Salida

- `reporte-qa-chazin-mobile.html` — Reporte HTML con resumen, tabla de hallazgos y galería de screenshots
- `screenshots/` — Capturas de cada paso

## Severidades

| Nivel | Descripción |
|-------|-------------|
| 🔴 Critical | Bloqueo total — funcionalidad no disponible |
| 🟠 High | Bug grave que afecta al usuario |
| 🟡 Medium | Bug moderado con workaround |
| 🔵 Low | Mejora recomendada |
| ✅ Pass | Verificación exitosa |
| ℹ️ Info | Información de contexto |
