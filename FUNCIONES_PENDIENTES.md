# 🚀 FUNCIONES PRIORITARIAS PENDIENTES

## 📋 Lista de Funcionalidades Críticas por Implementar

---

## 🎵 **ALTA PRIORIDAD - REPRODUCTOR DE MÚSICA**

### 1. **Sistema de Reproducción de Audio**
- [ ] **Implementar reproductor de audio** (usar `just_audio` o `audioplayers`)
- [ ] **Pantalla de reproductor musical** (mini player y fullscreen player)
- [ ] **Control de reproducción** (play, pause, next, previous)
- [ ] **Control de volumen** (slider de volumen)
- [ ] **Barra de progreso** (mostrar tiempo actual y duración)
- [ ] **Controles de reproducción** (shuffle, repeat)
- [ ] **Gestión de cola de reproducción** (queue management)
- [ ] **Reproducción en background** (background audio)
- [ ] **Notificaciones de media** (media notifications con controles)
- [ ] **Lockscreen controls** (controles en pantalla de bloqueo)

**Ubicación sugerida:** `apps/frontend/lib/features/player/`

**Notas:**
- Actualmente las canciones tienen un botón "Reproducir" que solo muestra un SnackBar
- Necesario para la funcionalidad core de la app

---

## 🔍 **ALTA PRIORIDAD - BÚSQUEDA COMPLETA**

### 2. **Sistema de Búsqueda Avanzada**
- [ ] **Implementar búsqueda real** (conectar con backend `/api/v1/public/search`)
- [ ] **Búsqueda de canciones** (por título, artista)
- [ ] **Búsqueda de artistas** (por nombre, género)
- [ ] **Búsqueda de playlists** (por nombre, descripción)
- [ ] **Resultados en tiempo real** (debounce para evitar demasiadas requests)
- [ ] **Historial de búsqueda** (guardar búsquedas recientes)
- [ ] **Filtros de búsqueda** (por tipo: canciones, artistas, playlists)
- [ ] **Búsqueda por voz** (opcional, usando speech_to_text)

**Ubicación:** `apps/frontend/lib/features/search/`

**Estado actual:**
- `SearchScreen` existe pero parece estar vacío o básico
- Falta conectar con backend y mostrar resultados

---

## 👤 **ALTA PRIORIDAD - PERFIL DE ARTISTA**

### 3. **Pantalla de Detalle de Artista**
- [ ] **Pantalla de perfil de artista** (mostrar info, avatar, bio)
- [ ] **Lista de canciones del artista** (todas las canciones publicadas)
- [ ] **Lista de álbumes** (si existe funcionalidad de álbumes)
- [ ] **Estadísticas del artista** (total streams, followers)
- [ ] **Botón seguir/dejar de seguir** (follow/unfollow)
- [ ] **Playlists del artista** (si tiene)

**Ubicación sugerida:** `apps/frontend/lib/features/artists/screens/artist_detail_screen.dart`

**Notas:**
- Actualmente hay `_onArtistTap` que solo muestra un SnackBar
- Necesario para navegación completa

---

## 🎵 **MEDIA PRIORIDAD - DETALLES DE CANCIÓN**

### 4. **Pantalla de Detalle de Canción**
- [ ] **Pantalla de detalles de canción** (info completa, letras)
- [ ] **Mostrar letras** (lyrics display)
- [ ] **Artista relacionado** (link a perfil de artista)
- [ ] **Acciones de canción** (agregar a playlist, compartir, like)
- [ ] **Reproducir canción** (integrar con reproductor)
- [ ] **Lista de reproducción sugerida** (similar songs)

**Ubicación sugerida:** `apps/frontend/lib/features/songs/screens/song_detail_screen.dart`

**Notas:**
- Actualmente hay `_onSongTap` que solo muestra un SnackBar

---

## 📱 **MEDIA PRIORIDAD - GESTIÓN DE USUARIO**

### 5. **Funcionalidades de Usuario**
- [ ] **Actualizar perfil** (cambiar nombre, avatar, bio)
- [ ] **Crear playlist personal** (desde la app móvil)
- [ ] **Gestionar playlists propias** (editar, eliminar, agregar canciones)
- [ ] **Biblioteca personal** (mis canciones favoritas, mis playlists)
- [ ] **Historial de reproducción** (últimas canciones escuchadas)
- [ ] **Configuración de cuenta** (preferencias, notificaciones)

**Ubicación:** `apps/frontend/lib/features/profile/`

**Estado actual:**
- `ProfileScreen` existe pero probablemente básico
- Necesario expandir funcionalidades

---

## 📚 **MEDIA PRIORIDAD - BIBLIOTECA/MIS LUGARES**

### 6. **Mejoras en Library Screen**
- [ ] **Mis canciones favoritas** (liked songs)
- [ ] **Mis playlists** (user playlists)
- [ ] **Artistas seguidos** (followed artists)
- [ ] **Álbumes guardados** (saved albums, si existe)
- [ ] **Descargas offline** (descargar canciones para offline)
- [ ] **Recientemente reproducido** (recently played)

**Ubicación:** `apps/frontend/lib/features/library/`

**Estado actual:**
- `LibraryScreen` existe pero necesita contenido real

---

## 🎨 **BAJA PRIORIDAD - MEJORAS UX/UI**

### 7. **Mejoras Visuales y UX**
- [ ] **Modo oscuro completo** (dark mode implementation)
- [ ] **Temas personalizables** (custom themes)
- [ ] **Animaciones mejoradas** (smooth transitions)
- [ ] **Gestos de navegación** (swipe gestures)
- [ ] **Pull to refresh** (ya implementado en algunos lugares, expandir)
- [ ] **Infinite scroll optimizado** (ya implementado, mejorar)

---

## 🔐 **MEDIA PRIORIDAD - AUTENTICACIÓN**

### 8. **Funcionalidades de Auth**
- [ ] **Recuperación de contraseña** (password recovery)
- [ ] **Cambiar contraseña** (change password)
- [ ] **Verificación de email** (email verification)
- [ ] **Autenticación social** (Google, Facebook, Apple - opcional)
- [ ] **Logout mejorado** (confirmación, limpieza de datos)

**Ubicación:** `apps/frontend/lib/features/auth/`

---

## 📊 **BAJA PRIORIDAD - ANALYTICS Y ESTADÍSTICAS**

### 9. **Estadísticas y Analytics**
- [ ] **Dashboard de estadísticas** (para usuarios premium)
- [ ] **Estadísticas de reproducción** (tiempo escuchado, canciones favoritas)
- [ ] **Estadísticas de artista** (para artistas: views, streams, followers)

---

## 🔔 **BAJA PRIORIDAD - NOTIFICACIONES**

### 10. **Sistema de Notificaciones**
- [ ] **Notificaciones push** (nuevas canciones, artistas seguidos)
- [ ] **Notificaciones in-app** (updates, recomendaciones)
- [ ] **Configuración de notificaciones** (preferencias)

---

## 🌐 **MEDIA PRIORIDAD - COMPARTIR**

### 11. **Funcionalidad de Compartir**
- [ ] **Compartir canciones** (share song)
- [ ] **Compartir playlists** (share playlist)
- [ ] **Compartir artista** (share artist)
- [ ] **Deep linking** (enlaces profundos a canciones/playlists)

---

## 💾 **BAJA PRIORIDAD - OFFLINE**

### 12. **Modo Offline**
- [ ] **Descargar canciones** (download songs for offline)
- [ ] **Sincronización offline** (offline sync)
- [ ] **Gestión de descargas** (manage downloads)
- [ ] **Indicador de estado offline** (offline indicator)

---

## 📝 **NOTAS IMPORTANTES**

### **Prioridad de Implementación Recomendada:**

1. **Semana 1-2:**
   - ✅ Reproductor de música (CRÍTICO)
   - ✅ Búsqueda completa (CRÍTICO)
   - ✅ Perfil de artista (ALTO)

2. **Semana 3-4:**
   - ✅ Detalles de canción
   - ✅ Gestión de usuario (playlists propias)
   - ✅ Mejoras en Library Screen

3. **Semana 5+ (Opcional):**
   - Modo offline
   - Notificaciones
   - Analytics
   - Mejoras UX avanzadas

---

## 🔧 **CONSIDERACIONES TÉCNICAS**

### **Backend - Endpoints Necesarios:**
- [ ] `GET /api/v1/public/search?q=query` (búsqueda)
- [ ] `GET /api/v1/public/artists/:id` (detalle de artista)
- [ ] `GET /api/v1/public/artists/:id/songs` (canciones del artista)
- [ ] `GET /api/v1/public/songs/:id` (detalle de canción)
- [ ] `POST /api/v1/users/me/playlists` (crear playlist)
- [ ] `PUT /api/v1/users/me/playlists/:id` (editar playlist)
- [ ] `GET /api/v1/users/me/favorites` (canciones favoritas)
- [ ] `POST /api/v1/users/me/favorites/:songId` (agregar a favoritos)

### **Dependencias Flutter Necesarias:**
- `just_audio` o `audioplayers` (para reproductor)
- `audio_service` (para background playback)
- `speech_to_text` (opcional, para búsqueda por voz)
- `share_plus` (para compartir)

---

## ✅ **FUNCIONES YA IMPLEMENTADAS**

- ✅ Sistema de autenticación (login/register)
- ✅ Navegación con bottom bar
- ✅ Pantalla de Home con secciones destacadas
- ✅ Lista de playlists
- ✅ Detalle de playlist con canciones
- ✅ Optimizaciones de rendimiento (scroll, imágenes, providers)
- ✅ Caché HTTP implementado
- ✅ Sistema de temas (light/dark)

---

**Última actualización:** $(date)



