# 🚀 Guía: flutter run - Desarrollo vs Producción

## 📋 Resumen

Cómo usar `flutter run` para ejecutar la app en desarrollo (localhost) o producción (AWS).

---

## 🔧 Desarrollo (Modo DEBUG)

### Comando Básico:
```bash
cd apps/frontend
flutter run
```

### Características:
- ✅ **Modo DEBUG** automático
- ✅ Se conecta a `localhost` o `10.0.2.2:3000`
- ✅ Hot Reload habilitado
- ✅ Logs de debugging disponibles
- ✅ Más lento pero con herramientas de desarrollo

### Opciones Adicionales:

```bash
# Especificar dispositivo
flutter run -d emulator-5554

# Ver dispositivos disponibles
flutter devices

# Ejecutar sin hot reload (más rápido)
flutter run --no-hot

# Ejecutar en modo profile (performance testing)
flutter run --profile
```

### Logs Esperados:
```
🔧 MODO DEBUG: Usando URL de desarrollo: http://10.0.2.2:3000
🔗 API Base URL configurada: http://10.0.2.2:3000/api/v1
```

---

## 🚀 Producción (Modo RELEASE)

### Comando:
```bash
cd apps/frontend
flutter run --release
```

### Características:
- ✅ **Modo RELEASE** (optimizado)
- ✅ Se conecta a producción (AWS)
- ❌ Sin Hot Reload
- ❌ Sin herramientas de debugging
- ✅ Más rápido y optimizado

### Opciones:

```bash
# Android
flutter run --release -d <device-id>

# iOS
flutter run --release

# Web
flutter run --release -d chrome
```

### Logs Esperados:
```
🚀 MODO RELEASE: Usando URL de producción: http://backend-alb-1038609925.us-east-1.elb.amazonaws.com
🔗 API Base URL configurada: http://backend-alb-.../api/v1
```

---

## 📊 Comparación: `flutter run` vs `flutter build`

| Acción | Comando | Modo | URL | Hot Reload | Uso |
|--------|---------|------|-----|------------|-----|
| **Desarrollo** | `flutter run` | DEBUG | localhost | ✅ Sí | Desarrollo diario |
| **Testing Producción** | `flutter run --release` | RELEASE | Producción | ❌ No | Probar en producción |
| **APK Debug** | `flutter build apk --debug` | DEBUG | localhost | ❌ No | Compartir APK debug |
| **APK Release** | `flutter build apk --release` | RELEASE | Producción | ❌ No | Distribuir a usuarios |

---

## 🎯 Casos de Uso

### 1. Desarrollo Normal (99% del tiempo)
```bash
flutter run
```
- ✅ Usa localhost automáticamente
- ✅ Hot reload para cambios rápidos
- ✅ Debugging completo

### 2. Probar Conexión a Producción
```bash
flutter run --release
```
- ✅ Verifica que la app funcione con el backend de producción
- ✅ Testing final antes de generar APK

### 3. Generar APK para Compartir
```bash
# Debug (para testing con otros desarrolladores)
flutter build apk --debug

# Release (para usuarios finales)
flutter build apk --release
```

---

## ⚠️ Errores Comunes

### ❌ "La app se conecta a producción en desarrollo"
**Causa**: Ejecutaste `flutter run --release` por error

**Solución**:
```bash
flutter run  # ✅ Sin --release
```

### ❌ "No se conecta al backend local"
**Verifica**:
1. ✅ Backend corriendo en `localhost:3000`
2. ✅ Ejecutaste `flutter run` (sin `--release`)
3. ✅ Revisa logs: debe decir "MODO DEBUG"

### ❌ "Hot reload no funciona"
**Causa**: Estás en modo RELEASE

**Solución**:
```bash
flutter run  # Sin --release para tener hot reload
```

---

## 🔍 Verificar Qué Modo Está Usando

### En los Logs:
- **DEBUG**: `🔧 MODO DEBUG: Usando URL de desarrollo`
- **RELEASE**: `🚀 MODO RELEASE: Usando URL de producción`

### En la App:
- **DEBUG**: Banner "DEBUG" en la esquina superior derecha (si no lo ocultaste)
- **RELEASE**: Sin banner, app optimizada

---

## 📝 Resumen de Comandos

### Desarrollo:
```bash
flutter run                    # ✅ Usa localhost
flutter run -d <device-id>      # ✅ Especificar dispositivo
flutter devices                # Ver dispositivos
```

### Producción:
```bash
flutter run --release          # ✅ Usa producción (AWS)
flutter build apk --release    # ✅ Generar APK
```

---

## 💡 Recomendación

**Para desarrollo diario:**
```bash
flutter run
```

**Para testing de producción:**
```bash
flutter run --release
```

**Para distribuir:**
```bash
flutter build apk --release
```

---

**Última actualización**: Noviembre 2025






