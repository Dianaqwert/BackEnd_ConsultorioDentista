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
    WHERE LOWER(nombreusuario) = LOWER($1) AND contrasenaue = $2
  `;

    const result = await pool.query(queryText, [nombre, contrasena]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        message: "Usuario no encontrado.",
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
