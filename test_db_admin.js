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
        const query = `
            SELECT id_reporte, asignado_a, estado
            FROM public.reportes
            WHERE asignado_a = 'admin01' OR asignado_a = 'paae01'
        `;
        const res = await pool.query(query);
        console.log("Admin/PAAE reports:", res.rows);
    } catch (e) {
        console.error(e);
    } finally {
        pool.end();
    }
}
run();