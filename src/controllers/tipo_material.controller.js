import { pool } from '../../conexion.js'; // Asegúrate que la ruta a tu pool sea correcta

// 1. CONSULTA (READ) - Endpoint: GET /api/tipo-material
export const obtenerTiposMateriales = async (req, res) => {
    try {
        // SELECT simple para listar todas las categorías
        const result = await pool.query('SELECT id_tipo_material, nombre_tipo FROM Tipo_Material ORDER BY nombre_tipo');

        // La consulta con `pool.query` en algunos entornos devuelve un array [rows, fields].
        const tipos = result[0] || result.rows;

        res.status(200).json(tipos);
    } catch (error) {
        console.error("Error al obtener tipos de material:", error);
        res.status(500).json({ message: "Error interno del servidor al consultar tipos de material" });
    }
};

// 2. ALTA (CREATE) - Endpoint: POST /api/tipo-material
export const crearTipoMaterial = async (req, res) => {
    try {
        const { nombre_tipo } = req.body;

        // Llama a la función PL/pgSQL: fn_crear_tipo_material
        const result = await pool.query('SELECT fn_crear_tipo_material($1)', [nombre_tipo]);

        // Extrae el ID devuelto por la función
        const nuevoId = result[0]?.[0]?.fn_crear_tipo_material || result.rows[0].fn_crear_tipo_material;

        res.status(201).json({
            message: "Tipo de material creado exitosamente",
            id: nuevoId
        });
    } catch (error) {
        console.error("Error al crear tipo de material:", error);
        res.status(500).json({ message: "Error interno del servidor" });
    }
};

// 3. BAJA (DELETE) - Endpoint: DELETE /api/tipo-material/:id
export const eliminarTipoMaterial = async (req, res) => {
    try {
        const { id } = req.params;

        // Llama a la función PL/pgSQL: fn_eliminar_tipo_material (maneja errores de FK)
        const result = await pool.query('SELECT fn_eliminar_tipo_material($1)', [id]);

        // Extrae el mensaje de éxito/error devuelto por la función
        const mensaje = result[0]?.[0]?.fn_eliminar_tipo_material || result.rows[0].fn_eliminar_tipo_material;

        if (mensaje.startsWith('ERROR')) {
            // Error de clave foránea o ID no encontrado (devuelto por la función SQL)
            return res.status(400).json({ message: mensaje });
        }

        res.status(200).json({ message: mensaje });
    } catch (error) {
        // Error de conexión u otro error de servidor
        console.error("Error al eliminar tipo de material:", error);
        res.status(500).json({ message: "Error interno del servidor" });
    }
};

// 4. BÚSQUEDA (READ) - Endpoint: GET /api/tipo-material/buscar?term=valor
export const buscarTiposMateriales = async (req, res) => {
    try {
        const term = req.query.term;

        if (!term) {
            return res.status(400).json({ message: "Falta el término de búsqueda ('term')" });
        }

        // Llama a la función PL/pgSQL: fn_buscar_tipo_material
        const result = await pool.query('SELECT id_tipo_material, nombre_tipo FROM fn_buscar_tipo_material($1)', [term]);

        const tipos = result[0] || result.rows;

        res.status(200).json(tipos);
    } catch (error) {
        console.error("Error al buscar tipos de material:", error);
        res.status(500).json({ message: "Error interno del servidor durante la búsqueda" });
    }
};
