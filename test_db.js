const { Pool } = require('pg');
const pool = new Pool({
    user: 'postgres',
    host: 'localhost',
    database: 'udi_connect',
    password: 'Mateo', 
    port: 5432,
});

async function run() {
    try {
        const res = await pool.query('SELECT id_reporte, asignado_a, estado FROM public.reportes ORDER BY id_reporte DESC LIMIT 5');
        console.log(res.rows);
        
        const res2 = await pool.query(`
            WITH todos_usuarios AS (
                SELECT id_usuario, nombres || ' ' || COALESCE(apellido_p, '') AS resuelto_por_nombre, 'Admin' AS resuelto_por_rol FROM admin.perfiles
                UNION ALL SELECT id_usuario, nombres || ' ' || COALESCE(apellido_p, ''), 'Docente' FROM docente.perfiles
                UNION ALL SELECT id_usuario, nombres || ' ' || COALESCE(apellido_p, ''), 'Alumno' FROM alumno.perfiles
                UNION ALL SELECT id_usuario, nombres || ' ' || COALESCE(apellido_p, ''), 'PAAE' FROM paae.perfiles
                UNION ALL SELECT id_usuario, nombres || ' ' || COALESCE(apellido_p, ''), 'Directivo' FROM directivo.perfiles
                UNION ALL SELECT id_usuario, nombres || ' ' || COALESCE(apellido_p, ''), 'Servicio Social' FROM ss.perfiles
            )
            SELECT r.id_reporte, r.asignado_a, u.resuelto_por_nombre, u.id_usuario as join_id
            FROM public.reportes r
            LEFT JOIN todos_usuarios u ON r.asignado_a = u.id_usuario
            ORDER BY r.id_reporte DESC LIMIT 5
        `);
        console.log(res2.rows);
        
    } catch (e) {
        console.error(e);
    } finally {
        pool.end();
    }
}
run();