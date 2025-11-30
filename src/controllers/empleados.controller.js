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
      contrasenaue,
      superadmin
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


/*historial del paciente buscado
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
*/

//-------------------DENTISTA APARTADO DE ADMINISTRACION-----------------------------------
//crear empleado:
export const crearUsuario = async (req, res) => {
  try {
    const {
      nombreUsuario,
      nombres,
      apellidoPat,
      apellidoMat,
      tipoEmpleado,
      contrasenaUE,
      superAdmin
    } = req.body;

    // --- VALIDACIÓN 1: ¿Ya existe el nombre de usuario (login)? ---
    const checkUser = await pool.query(
      "SELECT * FROM Usuario_Empleado WHERE LOWER(nombreUsuario) = LOWER($1)",
      [nombreUsuario]
    );

    if (checkUser.rows.length > 0) {
      return res.status(400).json({ message: "El nombre de usuario ya está ocupado. Elige otro." });
    }

    // --- VALIDACIÓN 2: ¿Ya existe la persona física (Nombre completo)? ---
    // Usamos LOWER para comparar sin importar mayúsculas/minúsculas
    const checkPersona = await pool.query(
      "SELECT * FROM Usuario_Empleado WHERE LOWER(nombres) = LOWER($1) AND LOWER(apellidoPat) = LOWER($2) AND LOWER(apellidoMat) = LOWER($3)",
      [nombres, apellidoPat, apellidoMat]
    );

    if (checkPersona.rows.length > 0) {
      return res.status(400).json({ message: "Esta persona ya está registrada en el sistema." });
    }

    // --- SI PASA LAS VALIDACIONES, INSERTAMOS ---
    const query = `
      INSERT INTO Usuario_Empleado
      (nombreUsuario, nombres, apellidoPat, apellidoMat, tipoEmpleado, contrasenaUE, superAdmin)
      VALUES ($1, $2, $3, $4, $5, $6, $7)
      RETURNING *;
    `;

    const values = [
      nombreUsuario,
      nombres,
      apellidoPat,
      apellidoMat,
      tipoEmpleado,
      contrasenaUE,
      superAdmin || false
    ];

    const result = await pool.query(query, values);

    res.json({
      message: "Usuario registrado correctamente",
      usuario: result.rows[0]
    });

  } catch (error) {
    console.error(error);
    // Si falla por la restricción de base de datos (plan B)
    if (error.code === '23505') {
        return res.status(400).json({ message: "Error: Datos duplicados (usuario o persona ya existe)." });
    }
    res.status(500).json({ message: "Error interno al registrar usuario" });
  }
};


//listar empleados
export const getEmpleadosActivos = async (req, res) => {
  const { id } = req.params;

  try {
    const query = `
      SELECT * 
      FROM vista_empleados_activos
      ORDER BY fecha_hora DESC
    `;

    const result = await pool.query(query);

    res.json(result.rows);

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};


/**
 * 
 * --vista para mostar empleados activos sin el superadmin
CREATE OR REPLACE VIEW vista_empleados_activos AS
SELECT 
    id_usuario,
    nombres || ' ' || apellidoPat || ' ' || apellidoMat AS nombre_completo,
    tipoEmpleado,
    fecha_hora
FROM Usuario_Empleado
WHERE superAdmin = false;

select * from vista_empleados_activos


CREATE OR REPLACE FUNCTION fn_listar_empleados_por_tipo(p_tipo VARCHAR)
RETURNS TABLE(
    id_empleado INT,
    nombre_completo VARCHAR,
    tipo VARCHAR
) AS $$
DECLARE
    cur_empleados CURSOR FOR
        SELECT id_usuario, nombres || ' ' || apellidoPat || ' ' || apellidoMat, tipoEmpleado
        FROM Usuario_Empleado
        WHERE tipoEmpleado = p_tipo;

    reg RECORD;
BEGIN
    OPEN cur_empleados;
    LOOP
        FETCH cur_empleados INTO reg;
        EXIT WHEN NOT FOUND;

        id_empleado := reg.id_usuario;
        nombre_completo := reg.column2;--  nombre_completo := reg.?column2;
        tipo := reg.tipoEmpleado;

        RETURN NEXT;
    END LOOP;

    CLOSE cur_empleados;
END;
$$ LANGUAGE plpgsql;
 */

export const getEmpleadosVista = async (req, res) => {
  try {
    const result = await pool.query("SELECT * FROM vista_empleados_activos");
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// 2. Filtrar por Tipo (Usando la FUNCIÓN)
export const getEmpleadosPorTipo = async (req, res) => {
  const { tipo } = req.params; // Ejemplo: 'Dentista'
  try {
    // Llamamos a la función SQL
    const result = await pool.query("SELECT * FROM fn_listar_empleados_por_tipo($1)", [tipo]);
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// 3. Eliminar Empleado
export const eliminarEmpleado = async (req, res) => {
  const { id } = req.params;
  try {
    // Opción A: Borrado físico (desaparece de la BD)
    const result = await pool.query("DELETE FROM Usuario_Empleado WHERE id_usuario = $1", [id]);
    
    if (result.rowCount === 0) {
        return res.status(404).json({ message: "Empleado no encontrado" });
    }
    res.json({ message: "Empleado eliminado correctamente" });

  } catch (error) {
    // Si falla por llaves foráneas (ya tiene citas asignadas), mejor maneja errores
    res.status(500).json({ error: "No se puede eliminar: El empleado tiene citas o registros asociados." });
  }
};

// 4. Buscador por nombre (Query directo para tu buscador)
export const buscarEmpleadoPorNombre = async (req, res) => {
    const { termino } = req.params;
    try {
        const query = `
            SELECT * FROM vista_empleados_activos 
            WHERE LOWER(nombre_completo) LIKE LOWER($1)
        `;
        const result = await pool.query(query, [`%${termino}%`]);
        res.json(result.rows);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
}