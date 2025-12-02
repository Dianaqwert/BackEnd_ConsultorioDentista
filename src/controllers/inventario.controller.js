import { pool } from "../../conexion.js";

export const obtenerInventarioAgrupado = async (req, res) => {
    try {
        // 1. Obtenemos la tabla plana de la Súper Vista
        const result = await pool.query('SELECT * FROM vista_inventario_detallado_kpi');
        const filas = result.rows;

        // 2. Procesamos en JS para agrupar por categoría (Transformación de datos)
        const inventarioAgrupado = filas.reduce((acc, row) => {
            // Buscamos si ya existe la categoría en el acumulador
            let categoria = acc.find(c => c.nombre === row.categoria);
            
            if (!categoria) {
                // Si no existe, la creamos con sus KPIs generales
                categoria = {
                    nombre: row.categoria,
                    id_tipo: row.id_tipo_material,
                    kpis: {
                        stock_total: row.stock_total_categoria,
                        valor_total: row.valor_total_categoria,
                        costo_promedio: row.costo_promedio_categoria
                    },
                    materiales: [] // Aquí meteremos el desglose
                };
                acc.push(categoria);
            }

            // Agregamos el material a la lista de esa categoría
            categoria.materiales.push({
                id: row.id_material,
                nombre: row.material,
                stock: row.stock_individual,
                costo: row.costo_unitario,
                valor: row.valor_material_individual,
                comparativa: row.comparativa_precio
            });

            return acc;
        }, []);

        res.json(inventarioAgrupado);

    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

// 1. REPORTE STOCK BAJO (Recibe parámetro dinámico)
export const obtenerReporteBajoStock = async (req, res) => {
    // Leemos el número desde la URL (?limite=10)
    const { limite } = req.query;

    try {
        // Si no mandan nada, ponemos 10 por defecto
        const valorLimite = limite ? parseInt(limite) : 10;

        // Llamamos a tu función SQL pasando el parámetro
        const query = 'SELECT * FROM fn_reporte_bajo_stock($1)';
        const result = await pool.query(query, [valorLimite]);

        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al obtener reporte de stock.' });
    }
};

// 2. CATEGORÍAS ALTO VALOR (Recibe parámetro dinámico)
export const obtenerCategoriasAltoValor = async (req, res) => {
    // Leemos el número desde la URL (?monto=500)
    const { monto } = req.query;

    try {
        const valorMinimo = monto ? parseFloat(monto) : 0;

        const query = 'SELECT * FROM fn_categorias_alto_valor($1)';
        const result = await pool.query(query, [valorMinimo]);

        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al obtener reporte financiero.' });
    }
};
