import { pool } from "../../conexion.js";
//consultas

//CONSULTAS DEL LOG IN--------------------------------------------------------------------------------------------------------
//obtener y buscar empleados 
export const buscarEmpleado = async (req, res) => {
  const { nombre, contrasena } = req.body;

  if (!nombre || !contrasena) {
    return res.status(400).json({
      message: "Se requiere nombre de usuario y contraseña.",
    });
  }

  try {
    const queryText = `
      SELECT 
        id_usuario,
        nombreusuario,
        nombres,
        apellidopat,
        apellidomat,
        tipoempleado,
        contrasenaue
      FROM usuario_empleado
      WHERE nombreusuario = $1 AND contrasenaue = $2
    `;

    const result = await pool.query(queryText, [nombre, contrasena]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        message: "Usuario o contraseña incorrectos.",
      });
    }

    res.json(result.rows[0]);

  } catch (error) {
    console.error("Error en la búsqueda:", error);
    return res.status(500).json({
      message: "Error interno del servidor al buscar empleado.",
      error: error.message,
    });
  }
};

//PARA DENTISTA-----------------------------------------------------------------------------------------------------------
export const getEmpleados = async (req, res) => {
  try {
    const result = await pool.query("SELECT * FROM Usuario_Empleado");
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};


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
    // 1. Cargar las variables desde req.query (Parámetros de consulta)
    // Los parámetros de consulta son más apropiados para búsquedas.
    const { nombre, apellidoPat, apellidoMat } = req.query; 

    // Opcional: Validar que al menos un campo esté presente para buscar
    if (!nombre && !apellidoPat && !apellidoMat) {
        return res.status(400).json({ 
            message: "Debe proporcionar al menos un campo (nombre, apellidoPat o apellidoMat) para buscar." 
        });
    }

    try {
        // 2. Construir la consulta SQL dinámicamente
        // Se define la consulta base y los filtros
        let query = `
            SELECT id_paciente, nombre_paciente, apellido_pat, apellido_mat, direccion 
            FROM paciente
            WHERE 1 = 1 -- Inicio de la cláusula WHERE
        `;
        const values = []; // Array para los valores seguros ($1, $2, ...)
        let paramIndex = 1;

        // 3. Añadir filtros si existen
        if (nombre) {
            // Usamos ILIKE para búsqueda insensible a mayúsculas/minúsculas y el operador % para coincidencias parciales
            query += ` AND nombre_paciente ILIKE $${paramIndex}`;
            values.push(`%${nombre}%`);
            paramIndex++;
        }
        if (apellidoPat) {
            query += ` AND apellido_pat ILIKE $${paramIndex}`;
            values.push(`%${apellidoPat}%`);
            paramIndex++;
        }
        if (apellidoMat) {
            query += ` AND apellido_mat ILIKE $${paramIndex}`;
            values.push(`%${apellidoMat}%`);
            paramIndex++;
        }
        
        // 4. Ejecutar la consulta
        const result = await pool.query(query, values);

        if (result.rows.length === 0)
            return res.status(404).json({ message: "Paciente no encontrado con esos criterios" });

        res.json(result.rows); // Devuelve todos los resultados que coincidan

    } catch (error) {
        console.error("Error al buscar paciente:", error);
        res.status(500).json({ error: "Error interno del servidor al buscar paciente." });
    }
};

//historial del paciente buscado
export const getHistorial = async (req, res) => {
  const { id } = req.params;

  try {
    const result = await pool.query(`
      SELECT h.id_historial, h.fecha, h.descripcion, 
             t.nombre AS tratamiento
      FROM historial h
      LEFT JOIN tratamiento t ON h.id_tratamiento = t.id_tratamiento
      WHERE h.id_paciente = $1
      ORDER BY h.fecha DESC
    `, [id]);

    res.json(result.rows);

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

//citas:en general
export const getCitas = async (req, res) => {
  const { id } = req.params;

  try {
    const result = await pool.query(`
      SELECT c.id_cita, c.fecha, c.hora, c.estado,
             d.nombres AS dentista
      FROM cita c
      INNER JOIN usuario_empleado d ON c.id_dentista = d.id_usuario
      WHERE c.id_paciente = $1
      ORDER BY c.fecha DESC
    `, [id]);

    res.json(result.rows);

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

//tratamiento:
export const getTratamientos = async (req, res) => {
  const { id } = req.params;

  try {
    const result = await pool.query(`
      SELECT t.id_tratamiento, t.nombre, t.costo, pt.fecha
      FROM paciente_tratamiento pt
      INNER JOIN tratamiento t ON pt.id_tratamiento = t.id_tratamiento
      WHERE pt.id_paciente = $1
      ORDER BY pt.fecha DESC
    `, [id]);

    res.json(result.rows);

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
//