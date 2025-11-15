const { Client } = require('pg');
const fs = require('fs');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });

async function runMigration() {
  // Obtener configuración de la base de datos
  const databaseUrl = process.env.DATABASE_URL;
  
  let client;
  
  if (databaseUrl) {
    client = new Client({ connectionString: databaseUrl });
  } else {
    client = new Client({
      host: process.env.DB_HOST || 'localhost',
      port: parseInt(process.env.DB_PORT || '5432'),
      user: process.env.DB_USERNAME || 'vintage_user',
      password: process.env.DB_PASSWORD || 'vintage_password_2024',
      database: process.env.DB_DATABASE || 'vintage_music',
    });
  }

  try {
    console.log('🔌 Conectando a la base de datos...');
    await client.connect();
    console.log('✅ Conectado exitosamente');

    // Leer el archivo SQL
    const sqlPath = path.join(__dirname, '../src/database/migrations/create-song-uploads-table.sql');
    console.log(`📄 Leyendo archivo: ${sqlPath}`);
    
    if (!fs.existsSync(sqlPath)) {
      throw new Error(`Archivo no encontrado: ${sqlPath}`);
    }

    const sql = fs.readFileSync(sqlPath, 'utf8');
    console.log('📝 Ejecutando migración SQL...\n');

    // Ejecutar el SQL
    await client.query(sql);
    
    console.log('✅ Migración ejecutada exitosamente!');
    console.log('✅ Tabla song_uploads creada con todos sus índices');

    // Verificar que la tabla existe
    const result = await client.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_name = 'song_uploads'
    `);

    if (result.rows.length > 0) {
      console.log('✅ Verificación: La tabla song_uploads existe en la base de datos');
    } else {
      console.log('⚠️ Advertencia: No se pudo verificar la creación de la tabla');
    }

  } catch (error) {
    console.error('❌ Error al ejecutar migración:');
    console.error(error.message);
    
    if (error.code === '42P07') {
      console.log('\n⚠️ Nota: El tipo enum upload_status ya existe. Esto es normal si ejecutaste la migración antes.');
    } else if (error.code === '42P16') {
      console.log('\n⚠️ Nota: La tabla ya existe. Esto es normal si ejecutaste la migración antes.');
    } else {
      process.exit(1);
    }
  } finally {
    await client.end();
    console.log('\n🔌 Conexión cerrada');
  }
}

runMigration();

