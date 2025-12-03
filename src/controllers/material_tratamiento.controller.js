import { pool } from '../../conexion.js';

export const obtenerMateriales = async (req, res) => {
    try {
        const result = await pool.query('SELECT * FROM Material_Tratamiento ORDER BY nombre');
        const materiales = result[0] || result.rows;
        res.status(200).json(materiales);
    } catch (error) {
        console.error("Error al obtener materiales:", error);
        res.status(500).json({ message: "Error interno del servidor" });
    }
};

export const crearMaterial = async (req, res) => {
    try {
        const { nombre, costounitario, stock, cantidad, id_tipo_material } = req.body;

        const result = await pool.query('SELECT fn_crear_material($1, $2, $3, $4, $5)',
            [nombre, costounitario, stock, cantidad, id_tipo_material]
        );

        const nuevoId = result.rows[0].fn_crear_material;

        res.status(201).json({
            message: "Material creado exitosamente",
            id_material: nuevoId
        });
    } catch (error) {
        console.error("Error al crear material:", error);
        res.status(500).json({ message: "Error al crear el material, verifique la clave foránea (Tipo Material)" });
    }
};

export const eliminarMaterial = async (req, res) => {
    try {
        const { id } = req.params;

        const result = await pool.query('SELECT fn_eliminar_material($1)', [id]);
        const mensaje = result.rows[0].fn_eliminar_material;

        if (mensaje.startsWith('ERROR')) {
            return res.status(404).json({ message: mensaje });
        }

        res.status(200).json({ message: mensaje });
    } catch (error) {
        console.error("Error al eliminar material:", error);
        res.status(500).json({ message: "Error interno del servidor" });
    }
};

export const buscarMateriales = async (req, res) => {
    try {
        const term = req.query.term;

        if (!term) {
            return obtenerMateriales(req, res);
        }

        // Usando SELECT * en la función interna de búsqueda
        const result = await pool.query('SELECT * FROM fn_buscar_material($1)', [term]);
        const materiales = result[0] || result.rows;

        res.status(200).json(materiales);
    } catch (error) {
        console.error("Error al buscar materiales:", error);
        res.status(500).json({ message: "Error interno del servidor durante la búsqueda" });
    }
};

export const actualizarMaterial = async (req, res) => {
    try {
        const { id } = req.params;
        const { nombre, costounitario, stock, cantidad, id_tipo_material } = req.body;

        const result = await pool.query('SELECT fn_actualizar_material($1, $2, $3, $4, $5, $6)',
            [id, nombre, costounitario, stock, cantidad, id_tipo_material]
        );

        const mensaje = result.rows[0].fn_actualizar_material;

        if (mensaje.startsWith('ERROR')) {
            return res.status(400).json({ message: mensaje });
        }

        res.status(200).json({ message: mensaje });
    } catch (error) {
        console.error("Error al actualizar material:", error);
        res.status(500).json({ message: "Error interno del servidor al actualizar material" });
    }
};
