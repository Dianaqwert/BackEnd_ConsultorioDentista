import { pool } from "../../conexion.js";

//obtener a los pacientes -> dentista
export const getPacientes = async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT id_paciente, nombrespaciente, apellidopat, apellidomat, telefono,email
      FROM paciente
      ORDER BY nombrespaciente
    `);

    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// buscar POR NOMBRES Y APELLIDOS
export const getPacienteByNombres = async (req, res) => {
    const { nombre, apellidoPat, apellidoMat } = req.query; 

    if (!nombre && !apellidoPat && !apellidoMat) {
        return res.status(400).json({ 
            message: "Debe proporcionar al menos un campo (nombre, apellidoPat o apellidoMat) para buscar." 
        });
    }

    try {
        let query = `
            SELECT id_paciente, nombrespaciente, apellidopat, apellidomat, telefono, email
            FROM paciente
            WHERE 1 = 1
        `;
        const values = [];
        let paramIndex = 1;

        if (nombre) {
            query += ` AND nombrespaciente ILIKE $${paramIndex}`;
            values.push(`%${nombre}%`);
            paramIndex++;
        }
        if (apellidoPat) {
            query += ` AND apellidopat ILIKE $${paramIndex}`;
            values.push(`%${apellidoPat}%`);
            paramIndex++;
        }
        if (apellidoMat) {
            query += ` AND apellidomat ILIKE $${paramIndex}`;
            values.push(`%${apellidoMat}%`);
            paramIndex++;
        }

        const result = await pool.query(query, values);

        if (result.rows.length === 0)
            return res.status(404).json({ message: "Paciente no encontrado con esos criterios" });

        res.json(result.rows);

    } catch (error) {
        console.error("Error al buscar paciente:", error);
        res.status(500).json({ error: "Error interno del servidor al buscar paciente." });
    }
};
