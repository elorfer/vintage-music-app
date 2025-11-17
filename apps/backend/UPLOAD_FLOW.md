# Flujo de Subida de Canciones - Documentación Técnica

## 📋 Resumen

Sistema robusto de subida de canciones con procesamiento asíncrono, idempotencia, compensación tipo SAGA y limpieza automática de archivos huérfanos.

## 🏗️ Arquitectura

```
Controller → Orquestador → Servicios → Cola (BullMQ) → Worker → Procesador
```

### Componentes Principales

1. **Controller** (`songs.controller.ts`)
   - Recibe petición HTTP
   - Valida archivos
   - Responde 202 Accepted inmediatamente
   - Delega al orquestador

2. **Orquestador** (`upload-orchestrator.service.ts`)
   - Maneja idempotencia
   - Crea registro de tracking
   - Sube archivos temporalmente
   - Envía job a cola
   - Responde rápidamente

3. **Cola** (BullMQ)
   - Almacena jobs de procesamiento
   - Maneja reintentos automáticos
   - Persiste estado

4. **Worker** (`upload.processor.ts`)
   - Procesa jobs de la cola
   - Delega al procesador

5. **Procesador** (`upload-processor.service.ts`)
   - Extrae metadatos del audio
   - Valida entidades relacionadas
   - Crea registro de canción
   - Actualiza estado del upload

6. **Compensación** (`compensation.service.ts`)
   - Limpia archivos en caso de error
   - Implementa patrón SAGA

## 🔄 Flujo Completo

### 1. Inicio de Upload (POST /songs/upload)

```
Cliente → Controller → Orquestador
```

**Pasos:**
1. Cliente envía FormData con:
   - `audio`: Archivo de audio (requerido)
   - `cover`: Archivo de portada (opcional)
   - `title`: Título de la canción
   - `artistId`: ID del artista
   - `uploadId`: ID opcional para idempotencia
   - Otros campos opcionales

2. Controller valida archivos y campos

3. Orquestador:
   - Genera o valida `uploadId` (idempotencia)
   - Verifica si el upload ya existe
   - Crea registro en `song_uploads` con status `PENDING`
   - Sube archivos a storage (rápido, sin procesamiento)
   - Envía job a cola BullMQ
   - Actualiza registro con `jobId` y status `PROCESSING`

4. Controller responde **202 Accepted** con:
   ```json
   {
     "uploadId": "upload-1234567890-abc123",
     "status": "processing",
     "jobId": "123",
     "message": "Upload iniciado, procesando en segundo plano",
     "checkStatusUrl": "/api/v1/songs/upload/upload-1234567890-abc123/status"
   }
   ```

### 2. Procesamiento en Background

```
Cola → Worker → Procesador
```

**Pasos:**
1. Worker recibe job de la cola
2. Procesador:
   - Lee archivos desde storage
   - Extrae metadatos del audio (proceso pesado)
   - Valida artista, álbum, género
   - Crea registro de canción en BD (transacción)
   - Actualiza registro de upload con status `COMPLETED`
   - Commit de transacción

3. Si falla:
   - Rollback de transacción
   - Actualiza registro con status `FAILED` y error
   - Aplica compensación (limpia archivos)
   - Marca `compensationApplied = true`

### 3. Consulta de Estado (GET /songs/upload/:uploadId/status)

```
Cliente → Controller → Orquestador → BD
```

**Respuesta:**
```json
{
  "id": "uuid",
  "uploadId": "upload-1234567890-abc123",
  "status": "completed",
  "songId": "uuid-de-la-cancion",
  "metadata": {
    "duration": 180,
    "codec": "mp3",
    "bitrate": 128000
  },
  "createdAt": "2024-01-01T00:00:00Z",
  "updatedAt": "2024-01-01T00:01:00Z"
}
```

## 🔐 Idempotencia

### Cómo Funciona

1. **Cliente proporciona `uploadId`**:
   - Si el cliente envía el mismo `uploadId` dos veces, el segundo request retorna el estado del primero
   - Útil para reintentos seguros

2. **Servidor genera `uploadId`**:
   - Si el cliente no proporciona `uploadId`, el servidor genera uno único
   - Formato: `upload-{timestamp}-{uuid}`

3. **Estados de Idempotencia**:
   - `COMPLETED`: Retorna resultado existente
   - `PROCESSING`/`PENDING`: Retorna estado actual
   - `FAILED`: Permite reintento (incrementa `retryCount`)

## 🧹 Compensación (SAGA Pattern)

### Cuándo se Aplica

1. Error al subir archivos inicialmente
2. Error al enviar job a cola
3. Error durante procesamiento (worker)

### Qué Hace

1. Elimina archivo de audio si existe
2. Elimina archivo de portada si existe
3. No lanza excepciones (solo loggea errores)
4. Marca `compensationApplied = true`

## 📊 Base de Datos

### Tabla: `song_uploads`

```sql
CREATE TABLE song_uploads (
    id UUID PRIMARY KEY,
    upload_id VARCHAR(255) UNIQUE NOT NULL,  -- Para idempotencia
    user_id UUID NOT NULL,
    status upload_status NOT NULL,
    audio_file_key VARCHAR(500),
    cover_file_key VARCHAR(500),
    song_id UUID,                            -- ID de canción creada
    title VARCHAR(200),
    artist_id UUID,
    album_id UUID,
    genre_id UUID,
    error TEXT,
    metadata JSONB,                          -- Metadatos extraídos
    job_id VARCHAR(255),                     -- ID del job BullMQ
    retry_count INTEGER DEFAULT 0,
    compensation_applied BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);
```

**Índices:**
- `upload_id` (único)
- `(user_id, status)`
- `created_at`
- `song_id` (parcial, donde no es NULL)

## 🚀 Uso desde el Cliente

### Ejemplo: Subir Canción

```typescript
const formData = new FormData();
formData.append('audio', audioFile);
formData.append('cover', coverFile);
formData.append('title', 'Mi Canción');
formData.append('artistId', 'artist-uuid');
formData.append('uploadId', 'my-unique-upload-id'); // Opcional para idempotencia

const response = await fetch('/api/v1/songs/upload', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`,
  },
  body: formData,
});

// Respuesta 202 Accepted
const { uploadId, checkStatusUrl } = await response.json();

// Consultar estado periódicamente
const statusResponse = await fetch(checkStatusUrl, {
  headers: { 'Authorization': `Bearer ${token}` },
});
const status = await statusResponse.json();

if (status.status === 'completed') {
  console.log('Canción creada:', status.songId);
} else if (status.status === 'failed') {
  console.error('Error:', status.error);
}
```

## ⚙️ Configuración

### Variables de Entorno

```env
# Redis para BullMQ
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=

# Storage
APP_URL=http://localhost:3000
```

### Instalación de Dependencias

```bash
npm install @nestjs/bull bull
```

### Migración de Base de Datos

```bash
npm run migration:run
```

O ejecutar manualmente el SQL en `src/database/migrations/create-song-uploads-table.sql`

## 🔍 Monitoreo

### Logs

El sistema genera logs detallados en cada paso:
- Inicio de upload
- Subida de archivos
- Envío a cola
- Procesamiento
- Errores y compensación

### Estado de Jobs

BullMQ proporciona dashboard para monitorear:
- Jobs pendientes
- Jobs en proceso
- Jobs completados
- Jobs fallidos
- Reintentos

## ✅ Ventajas del Nuevo Sistema

1. **Respuesta Rápida**: 202 Accepted inmediato
2. **Idempotencia**: Reintentos seguros
3. **Sin Archivos Huérfanos**: Compensación automática
4. **Escalable**: Procesamiento en background
5. **Robusto**: Reintentos automáticos
6. **Trazable**: Tracking completo del proceso
7. **Transaccional**: Rollback automático en errores

## 🐛 Troubleshooting

### Upload queda en "processing"

1. Verificar logs del worker
2. Verificar estado del job en BullMQ
3. Verificar Redis está funcionando
4. Revisar errores en `song_uploads.error`

### Archivos no se eliminan

1. Verificar logs de compensación
2. Verificar permisos de storage
3. Verificar `compensationApplied` en BD

### Metadatos no se extraen

1. Verificar que `music-metadata` está instalado
2. Verificar formato del archivo de audio
3. Revisar logs del procesador



