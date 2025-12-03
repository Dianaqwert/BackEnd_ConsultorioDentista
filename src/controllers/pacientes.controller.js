import { pool } from "../../conexion.js";


///_______________________________________________FUNCIONES PARA LA PARTE DE DEENTISTA_________________________________________
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
    const { 
        nombre, 
        apellidoPat, 
        apellidoMat 
    } = req.query; 

    //like
    const criterioBusqueda = `${nombre || ''} ${apellidoPat || ''} ${apellidoMat || ''}`.trim();

    try {
        let query = `
            SELECT *
            FROM vista_reporte_cita_completa 
            WHERE 1 = 1
        `;
        const values = [];
        let paramIndex = 1;

        if (criterioBusqueda.length > 0) {
            query += ` AND paciente_nombre_completo ILIKE $${paramIndex}`;
            values.push(`%${criterioBusqueda.split(' ').join('%')}%`); // Permite buscar "juan perez" en el campo completo
            paramIndex++;
        }
        
        query += ` ORDER BY paciente_nombre_completo, fecha_hora DESC`;
        
        const result = await pool.query(query, values);

        if (result.rows.length === 0)
            return res.status(404).json({ message: "Paciente no encontrado con esos criterios" });

        res.json(result.rows);

    } catch (error) {
        console.error("Error al buscar paciente:", error);
        res.status(500).json({ error: "Error interno del servidor al buscar paciente." });
    }
};

export const getReporteCompletoByPacienteId = async (req, res) => {
    const { id } = req.params; // id_paciente

    try {
        const result = await pool.query(`SELECT * FROM vista_reporte_cita_completa WHERE id_paciente = $1 ORDER BY fecha_hora DESC`, [id]);
        res.json(result.rows);
    } catch (error) {
        console.error("Error al obtener reporte completo:", error);
        res.status(500).json({ error: error.message });
    }
};

//para la vista de derivaciones
// controllers/pacientes.controller.js

export const getDerivaciones = async (req, res) => {
    const { id } = req.params; 

    try {
        let query = `SELECT * FROM vista_derivaciones_externas WHERE 1=1 `;
        const values = [];

        if (id && id !== '0') {
            query += ` AND id_paciente = $1`;
            values.push(id);
        }
        
        query += ` ORDER BY fecha DESC`;

        const result = await pool.query(query, values);
        res.json(result.rows);
    } catch (error) {
        console.error("Error al obtener derivaciones:", error);
        res.status(500).json({ error: error.message });
    }
};

//para la vista de :vista_historial_paciente
export const getHistorialPaciente = async (req, res) => {
    const { id } = req.params; 

    try {
        let query = `SELECT * FROM vista_historial_paciente WHERE 1=1 `;
        const values = [];

        if (id && id !== '0') {
            query += ` AND id_paciente = $1`;
            values.push(id);
        }
        
        query += ` ORDER BY fecha_cita DESC`;

        const result = await pool.query(query, values);
        res.json(result.rows);
    } catch (error) {
        console.error("Error al obtener historiales:", error);
        res.status(500).json({ error: error.message });
    }
};

//vista_tratamientos_realizados
// src/controllers/pacientes.controller.js
// vista_tratamientos_realizados
export const getTratamientoRealizado = async (req, res) => {
    const { id } = req.params;

    try {
        let query = `SELECT * FROM vista_tratamientos_realizados WHERE 1=1 `;
        const values = [];

        // 2. Filtro inteligente para ID 0
        if (id && id !== '0') {
            query += ` AND id_paciente = $1`;
            values.push(id);
        }

        query += ` ORDER BY fecha_tratamiento DESC`;

        const result = await pool.query(query, values);
        res.json(result.rows);

    } catch (error) {
        console.error("Error al obtener tratamientos:", error);
        res.status(500).json({ error: error.message });
    }
};

/*_______________________________ACTUALIZACIONES DE LA CITA______________________________________________
export const registrarAtencionCompleta = async (req, res) => {
    const { 
        id_cita, id_paciente, 
        alergias, enfermedades, avanceTratamiento, // Datos Historial
        tratamientos, // Array de tratamientos
        derivaciones, // Array de derivaciones
        estudios, // Array de estudios
        total_deuda 
    } = req.body;

    const client = await pool.connect();

    try {
        await client.query('BEGIN'); // INICIO DE LA TRANSACCIÓN

        // 1. ACTUALIZAR CITA -> 'Atendida'
        await client.query(
            `UPDATE Cita SET estado_cita = 'Atendida' WHERE id_cita = $1`,
            [id_cita]
        );

        // 2. CREAR HISTORIAL CLÍNICO
        // Usamos la fecha actual del sistema
        await client.query(
            `INSERT INTO Historial_Clinico 
            (alergias, enfermedades, avanceTratamiento, fecha, id_cita)
            VALUES ($1, $2, $3, CURRENT_DATE, $4)`,
            [alergias, enfermedades, avanceTratamiento, id_cita]
        );

        // 3. GENERAR DEUDA (Si hubo tratamientos)
        // Se asume que no se paga en este instante, queda como 'Pendiente a pagar' o 'Abono' si se mandara pago.
        // Tu trigger calculará el estado.
        if (total_deuda > 0) {
            await client.query(
                `INSERT INTO Deuda (monto_total, monto_pagado, id_cita) VALUES ($1, 0, $2)`,
                [total_deuda, id_cita]
            );
        }

        // 4. INSERTAR TRATAMIENTOS (Detalle_Costo)
        // Iteramos sobre el array de tratamientos que viene del form
        if (tratamientos && tratamientos.length > 0) {
            for (const trat of tratamientos) {
                // Obtenemos el costo actual de la BD para asegurar precisión
                const resCosto = await client.query('SELECT costo FROM Tratamiento WHERE id_tipo_tratamiento = $1', [trat.id_tipo_tratamiento]);
                const costoUnitario = resCosto.rows[0].costo;
                const subTotal = costoUnitario * trat.cantidad;

                // Insertar Detalle (Tu trigger de stock se disparará aquí automáticamente)
                await client.query(
                    `INSERT INTO Detalle_Costo 
                    (cantidad, subTotal, id_cita, id_tipo_tratamiento, id_tipo_material, id_pago)
                    VALUES ($1, $2, $3, $4, $5, NULL)`, // id_pago NULL porque es deuda
                    [trat.cantidad, subTotal, id_cita, trat.id_tipo_tratamiento, trat.id_tipo_material]
                );
            }
        }

        // 5. INSERTAR DERIVACIONES (Si hay)
        if (derivaciones && derivaciones.length > 0) {
            for (const der of derivaciones) {
                await client.query(
                    `INSERT INTO Derivacion 
                    (fecha, nombreDentista, motivo, especialidadDentista, id_paciente, fecha_hora)
                    VALUES (CURRENT_DATE, $1, $2, $3, $4, CURRENT_TIMESTAMP)`,
                    [der.nombreDentista, der.motivo, der.especialidadDentista, id_paciente]
                );
            }
        }

        // 6. INSERTAR ESTUDIOS (Si hay)
        if (estudios && estudios.length > 0) {
            for (const est of estudios) {
                await client.query(
                    `INSERT INTO Estudio 
                    (nombre, descripcion, resultados, id_paciente, fecha_hora)
                    VALUES ($1, $2, 'Pendiente', $3, CURRENT_TIMESTAMP)`,
                    [est.nombre, est.descripcion, id_paciente]
                );
            }
        }

        await client.query('COMMIT'); // CONFIRMAR TODO
        res.json({ message: 'Consulta finalizada y registros guardados correctamente.' });

    } catch (error) {
        await client.query('ROLLBACK'); // DESHACER TODO SI ALGO FALLA
        console.error('Error en transacción de atención:', error);
        res.status(500).json({ message: 'Error procesando la atención', error: error.message });
    } finally {
        client.release();
    }
};*/

// src/controllers/pacientes.controller.js

export const registrarAtencionCompleta = async (req, res) => {
    // ... (desestructuración igual que antes) ...
    const { 
        id_cita, id_paciente, 
        alergias, enfermedades, avanceTratamiento, 
        tratamientos, derivaciones, estudios, total_deuda 
    } = req.body;

    const client = await pool.connect();

    try {
        await client.query('BEGIN');

        // 1. ACTUALIZAR CITA (No cambia nada si ya estaba atendida)
        await client.query(
            `UPDATE Cita SET estado_cita = 'Atendida' WHERE id_cita = $1`,
            [id_cita]
        );

        // 2. HISTORIAL CLÍNICO: USAR "UPSERT" (Insertar o Actualizar)
        // PostgreSQL permite esto con ON CONFLICT
        await client.query(
            `INSERT INTO Historial_Clinico 
            (alergias, enfermedades, avanceTratamiento, fecha, id_cita)
            VALUES ($1, $2, $3, CURRENT_DATE, $4)
            ON CONFLICT (id_cita) 
            DO UPDATE SET 
                alergias = EXCLUDED.alergias,
                enfermedades = EXCLUDED.enfermedades,
                avanceTratamiento = EXCLUDED.avanceTratamiento`,
            [alergias, enfermedades, avanceTratamiento, id_cita]
        );

        // 3. DEUDA: SUMAR A LA EXISTENTE O CREAR NUEVA
        if (total_deuda > 0) {
            // Verificamos si ya existe deuda
            const resDeuda = await client.query('SELECT id_deuda FROM Deuda WHERE id_cita = $1', [id_cita]);
            
            if (resDeuda.rows.length > 0) {
                // Si ya existe, SUMAMOS el nuevo monto al total
                await client.query(
                    `UPDATE Deuda SET monto_total = monto_total + $1 WHERE id_cita = $2`,
                    [total_deuda, id_cita]
                );
            } else {
                // Si no existe, la creamos
                await client.query(
                    `INSERT INTO Deuda (monto_total, monto_pagado, id_cita) VALUES ($1, 0, $2)`,
                    [total_deuda, id_cita]
                );
            }
        }

        // 4. TRATAMIENTOS: SIEMPRE AGREGAR (Append)
        // Esto permite que el dentista agregue "2 resinas" primero, guarde, y luego agregue "1 limpieza" después.
        if (tratamientos && tratamientos.length > 0) {
            for (const trat of tratamientos) {
                const resCosto = await client.query('SELECT costo FROM Tratamiento WHERE id_tipo_tratamiento = $1', [trat.id_tipo_tratamiento]);
                const costoUnitario = resCosto.rows[0].costo;
                const subTotal = costoUnitario * trat.cantidad;

                await client.query(
                    `INSERT INTO Detalle_Costo 
                    (cantidad, subTotal, id_cita, id_tipo_tratamiento, id_tipo_material, id_pago)
                    VALUES ($1, $2, $3, $4, $5, NULL)`,
                    [trat.cantidad, subTotal, id_cita, trat.id_tipo_tratamiento, trat.id_tipo_material]
                );
            }
        }

        // 5. DERIVACIONES Y ESTUDIOS (Igual, siempre agregan nuevos si se mandan)
        // ... (Tu código actual de derivaciones y estudios está bien, simplemente agregará más filas si el usuario las pone) ...
        // (Copia y pega la parte de derivaciones y estudios que ya tenías)

        await client.query('COMMIT');
        res.json({ message: 'Atención actualizada correctamente.' });

    } catch (error) {
        await client.query('ROLLBACK');
        console.error('Error en transacción:', error);
        res.status(500).json({ message: 'Error procesando la atención', error: error.message });
    } finally {
        client.release();
    }
};
// En pacientes.controller.js

// Obtener lista simple para el Select de Tratamientos
export const getListaTratamientos = async (req, res) => {
    try {
        const result = await pool.query("SELECT id_tipo_tratamiento, nombre, costo FROM Tratamiento ORDER BY nombre");
        res.json(result.rows);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

// Obtener lista simple para el Select de Materiales
// src/controllers/pacientes.controller.js

export const getListaMateriales = async (req, res) => {
    try {

        const result = await pool.query(`
            SELECT 
                id_tipo_material, 
                nombre AS nombre_material, -- Alias para el frontend
                stock 
            FROM Material_Tratamiento 
            WHERE stock > 0 
            ORDER BY nombre
        `);
        
        res.json(result.rows);
    } catch (error) {
        console.error("Error cargando materiales:", error); // Agrega log para ver el error en consola
        res.status(500).json({ error: error.message });
    }
};

export const getCitasAgendadas = async (req, res) => {
    try {
        // Usamos la vista completa para tener el nombre del paciente y detalles
        const query = `
            SELECT * FROM vista_reporte_cita_completa 
            WHERE estado_cita = 'Agendada'
            ORDER BY fecha_hora ASC -- Las más próximas primero
        `;
        
        const result = await pool.query(query);
        res.json(result.rows);

    } catch (error) {
        console.error("Error al obtener citas agendadas:", error);
        res.status(500).json({ error: error.message });
    }
};

export const getCitasPorFecha = async (req, res) => {
    // 1. Recibimos los parámetros
    const { fecha, estado, idDentista } = req.query; 

    try {
        if (!fecha) {
            return res.status(400).json({ message: "La fecha es obligatoria" });
        }

        // 2. Construimos la consulta BASE con tus JOINs solicitados
        // Nota: Agregué el JOIN con Paciente para que la tabla muestre el nombre del paciente,
        // y concatené el nombre del dentista para que se vea bien.
        let query = `
            SELECT 
                c.id_cita,
                c.fecha_hora,
                c.hora,
                c.descripcion AS motivo_principal_cita, -- Alias compatible con tu frontend
                c.estado_cita,
                c.id_paciente,
                -- Datos del Dentista
                ue.nombres || ' ' || ue.apellidoPat AS dentistas_involucrados,
                -- Datos del Paciente (Necesario para la tabla visual)
                p.nombrespaciente || ' ' || p.apellidoPat ||' '||p.apellidoMat AS paciente_nombre_completo
            FROM 
                Cita c
            -- 1. Unir Cita con la tabla intermedia
            JOIN 
                Usuario_Empleados_Cita uec ON c.id_cita = uec.id_cita
            -- 2. Unir la intermedia con la tabla de Empleados
            JOIN 
                Usuario_Empleado ue ON uec.id_usuario = ue.id_usuario
            -- 3. Unir con Paciente (Para saber de quién es la cita)
            JOIN
                Paciente p ON c.id_paciente = p.id_paciente
            
            -- 4. FILTROS BASE
            WHERE 
                uec.tipo_empleado = 'Dentista'
                AND DATE(c.fecha_hora) = $1
        `;
        
        const values = [fecha];
        let paramIndex = 2; // El $1 ya está ocupado por la fecha

        // 3. Filtro Dinámico por ESTADO
        if (estado && estado !== 'Todos') {
            query += ` AND c.estado_cita = $${paramIndex}`;
            values.push(estado);
            paramIndex++;
        }

        // 4. Filtro Dinámico por ID DENTISTA (Si se logueó un dentista específico)
        if (idDentista) {
            query += ` AND ue.id_usuario = $${paramIndex}`;
            values.push(idDentista);
            paramIndex++;
        }

        // 5. Ordenamiento
        query += ` ORDER BY c.hora ASC`;

        const result = await pool.query(query, values);
        res.json(result.rows);

    } catch (error) {
        console.error("Error buscando citas por fecha:", error);
        res.status(500).json({ error: error.message });
    }
};

// Obtener los detalles (tratamientos/materiales) de una cita específica para editar
export const getDetalleCitaEspecifica = async (req, res) => {
    const { id_cita } = req.params;
    try {
        // 1. Obtener Tratamientos registrados en esa cita
        const tratamientos = await pool.query(`
            SELECT dc.id_tipo_tratamiento, dc.id_tipo_material, dc.cantidad
            FROM Detalle_Costo dc
            WHERE dc.id_cita = $1
        `, [id_cita]);

        // 2. Obtener Historial (para asegurar que tenemos el texto completo)
        const historial = await pool.query(`
            SELECT alergias, enfermedades, avanceTratamiento 
            FROM Historial_Clinico WHERE id_cita = $1
        `, [id_cita]);

        res.json({
            tratamientos: tratamientos.rows,
            historial: historial.rows[0] || {}
        });

    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

// Obtener el último registro de historial (alergias/enfermedades) de un paciente
export const getUltimoHistorialPaciente = async (req, res) => {
    const { id_paciente } = req.params;
    try {
        // Buscamos el historial de la cita más reciente que tenga historial
        const query = `
            SELECT hc.alergias, hc.enfermedades
            FROM Historial_Clinico hc
            JOIN Cita c ON hc.id_cita = c.id_cita
            WHERE c.id_paciente = $1
            ORDER BY c.fecha_hora DESC
            LIMIT 1
        `;
        
        const result = await pool.query(query, [id_paciente]);
        
        // Si tiene historial previo, devolvemos la fila. Si no, objeto vacío.
        res.json(result.rows[0] || {});

    } catch (error) {
        console.error("Error obteniendo último historial:", error);
        res.status(500).json({ error: error.message });
    }
};

//_