import { pool } from "../../conexion.js";


export const crearTratamiento = async (req, res) => {
  // Recibimos los datos del frontend (Angular)
  const { nombre, descripcion, costo } = req.body;

  try {
    // NOTA: No enviamos 'activo' porque en la BD pusimos DEFAULT TRUE.
    // Usamos RETURNING * para que el frontend reciba el ID nuevo creado.
    const query = `
      INSERT INTO Tratamiento (nombre, descripcion, costo) 
      VALUES ($1, $2, $3) 
      RETURNING *
    `;
    
    const values = [nombre, descripcion, costo];
    const result = await pool.query(query, values);

    res.status(201).json({
      mensaje: 'Tratamiento creado exitosamente',
      tratamiento: result.rows[0] // Devolvemos el objeto creado
    });

  } catch (error) {
    console.error('Error al crear tratamiento:', error);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
};

// 1. NUEVA FUNCIÓN: OBTENER SOLO LOS INACTIVOS
export const obtenerInactivos = async (req, res) => {
    try {
      const result = await pool.query('SELECT * FROM Tratamiento WHERE activo = FALSE ORDER BY nombre');
      res.status(200).json(result.rows);
    } catch (error) {
      console.error(error);
      res.status(500).json({ error: 'Error al obtener tratamientos inactivos' });
    }
};

// 2. MODIFICACIÓN: ELIMINAR CON MENSAJE INTELIGENTE
export const eliminarTratamiento = async (req, res) => {
  const { id } = req.params; 

  try {
    const idTratamiento = parseInt(id, 10);

    // A. Llamamos al procedimiento (Tu versión actual de 1 parámetro)
    await pool.query(`CALL sp_gestionar_baja_tratamiento($1)`, [idTratamiento]);

    // B. VERIFICACIÓN: ¿El tratamiento sigue existiendo en la BD?
    const checkQuery = 'SELECT activo FROM Tratamiento WHERE id_tipo_tratamiento = $1';
    const checkResult = await pool.query(checkQuery, [idTratamiento]);

    if (checkResult.rows.length > 0) {
        // SI existe todavía, significa que el procedure hizo UPDATE (Baja Lógica)
        res.status(200).json({
            tipo: 'advertencia', // Para usarlo en el front
            mensaje: 'El tratamiento ya no está vigente, pero aún hay pacientes con ese tratamiento (Se ha archivado).'
        });
    } else {
        // NO existe, el procedure hizo DELETE (Baja Física)
        res.status(200).json({
            tipo: 'exito',
            mensaje: 'El tratamiento se eliminó definitivamente (No tenía pacientes asociados).'
        });
    }

  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ error: 'Error al procesar la baja.' });
  }
};

export const obtenerTratamientos = async (req, res) => {
  try {
    // Solo traemos los que tengan activo = TRUE para mostrarlos en el select de Angular
    const result = await pool.query('SELECT * FROM Tratamiento WHERE activo = TRUE ORDER BY nombre');
    
    res.status(200).json(result.rows);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Error al obtener tratamientos' });
  }
};

// 3. VER PACIENTES CON TRATAMIENTOS INACTIVOS
export const obtenerPacientesTratamientosInactivos = async (req, res) => {
    try {
        const query = `
            SELECT 
                p.nombrespaciente || ' ' || p.apellidopat || ' ' || p.apellidomat AS nombre_paciente,
                t.nombre AS nombre_tratamiento,
                c.fecha_hora AS fecha_cita,
                dc.subTotal AS precio_original,
                d.estado AS estado_pago,
                d.saldo_pendiente
            FROM Detalle_Costo dc
            JOIN Tratamiento t ON dc.id_tipo_tratamiento = t.id_tipo_tratamiento
            JOIN Cita c ON dc.id_cita = c.id_cita
            JOIN Paciente p ON c.id_paciente = p.id_paciente
            JOIN Deuda d ON c.id_cita = d.id_cita  -- JOIN estricto, debe tener registro de deuda
            WHERE t.activo = FALSE
              AND d.saldo_pendiente > 0            -- <--- EL FILTRO CLAVE: Solo si deben dinero
            ORDER BY c.fecha_hora DESC;
        `;
        const result = await pool.query(query);
        res.status(200).json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al obtener reporte de deudores.' });
    }
};

// 4. AJUSTAR PRECIO (PORCENTAJE)
export const ajustarPrecio = async (req, res) => {
    const { id } = req.params;
    const { porcentaje } = req.body; // Ej: 10 (para 10%)

    try {
        // 1. Ejecutamos tu procedimiento almacenado
        await pool.query('CALL sp_ajustar_precios_tratamiento($1, $2)', [id, porcentaje]);

        // 2. Contamos a cuántos pacientes se les "respetó" el precio antiguo
        // (Son todos los que ya tenían este tratamiento registrado en Detalle_Costo)
        const countQuery = 'SELECT COUNT(*) as total FROM Detalle_Costo WHERE id_tipo_tratamiento = $1';
        const countResult = await pool.query(countQuery, [id]);
        const afectados = countResult.rows[0].total;

        res.status(200).json({
            mensaje: `Precio actualizado correctamente (+${porcentaje}%).`,
            nota: `Se respetó el precio anterior a ${afectados} pacientes que ya tenían este tratamiento registrado.`
        });

    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al ajustar precios.' });
    }
};

//5. OBTENER EL PROMEDIO DE PRECIOS
//SELECT fn_costo_promedio_tratamientos();
export const obtenerPromedioPrecios = async (req, res) => {
    try {
        // Llamada a la función
        // Usamos "as promedio" para tener un nombre de columna claro en el JSON
        const query = 'SELECT fn_costo_promedio_tratamientos() as promedio';
        
        const result = await pool.query(query);

        // El resultado viene en result.rows[0]
        const promedio = result.rows[0].promedio;

        res.status(200).json({ 
            promedio: promedio 
        });

    } catch (error) {
        console.error('Error al obtener promedio:', error);
        res.status(500).json({ error: 'Error al calcular el promedio.' });
    }
};

//_____________________________________________________________________________________________________________