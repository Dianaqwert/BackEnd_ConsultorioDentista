import { pool } from "../../conexion.js";


export const crearCita = async (req, res) => {
    // AHORA SÍ recibimos id_dentista del body
    const { id_paciente, fecha, hora, descripcion, id_recepcionista, id_dentista } = req.body;

    const client = await pool.connect();
    try {
        await client.query('BEGIN');

        // A. Insertar la Cita
        const resCita = await client.query(`
            INSERT INTO Cita (fecha_hora, hora, descripcion, estado_cita, id_paciente)
            VALUES ($1, $2, $3, 'Pendiente', $4)
            RETURNING id_cita
        `, [fecha, hora, descripcion, id_paciente]);

        const idCita = resCita.rows[0].id_cita;

        // B. Asignar al Recepcionista (Auditoría: Quién creó el registro)
        if (id_recepcionista) {
            await client.query(`
                INSERT INTO Usuario_Empleados_Cita (id_cita, id_usuario, tipo_empleado)
                VALUES ($1, $2, 'Recepcion')
            `, [idCita, id_recepcionista]);
        }

        // C. Asignar al Dentista (Quién atenderá) <--- ESTO FALTABA
        // Al intentar insertar esto, tu TRIGGER 'tr_verificar_disponibilidad_dentista' saltará si está ocupado.
        if (id_dentista) {
            await client.query(`
                INSERT INTO Usuario_Empleados_Cita (id_cita, id_usuario, tipo_empleado)
                VALUES ($1, $2, 'Dentista')
            `, [idCita, id_dentista]);
        }

        await client.query('COMMIT');
        res.status(201).json({ message: 'Cita agendada correctamente', id_cita: idCita });

    } catch (error) {
        await client.query('ROLLBACK');
        console.error("Error al crear cita:", error);

        // ERROR 1: PACIENTE OCUPADO (Índice único en BD)
        if (error.code === '23505') { 
             return res.status(400).json({ 
                 error: "Cruce de horarios: El PACIENTE ya tiene una cita activa a esa misma hora." 
             });
        }
        
        // ERROR 2: DENTISTA OCUPADO (Trigger en BD)
        if (error.message && error.message.includes('El Dentista seleccionado ya tiene una cita')) {
            return res.status(409).json({ 
                error: "Agenda llena: El DENTISTA seleccionado ya está ocupado a esa hora." 
            });
        }

        res.status(500).json({ error: "Error interno al agendar la cita." });
    } finally {
        client.release();
    }
};

// 2. LISTAR CITAS CON FILTROS (FECHA Y ESTADO)
export const getCitasFiltro = async (req, res) => {
    const { fecha, estado } = req.query;

    try {
        let query = `
            SELECT 
                c.id_cita, 
                c.fecha_hora, 
                c.hora, 
                c.estado_cita, 
                c.descripcion,
                p.nombrespaciente || ' ' || p.apellidopat || ' ' || COALESCE(p.apellidomat, '') AS nombre_paciente,
                p.telefono
            FROM Cita c
            JOIN Paciente p ON c.id_paciente = p.id_paciente
            WHERE 1=1
        `;
        
        const values = [];
        let paramIndex = 1;

        if (fecha) {
            query += ` AND c.fecha_hora = $${paramIndex}`;
            values.push(fecha);
            paramIndex++;
        }

        if (estado && estado !== 'Todos') {
            query += ` AND c.estado_cita = $${paramIndex}`;
            values.push(estado);
            paramIndex++;
        }

        query += ` ORDER BY c.hora ASC`;

        const result = await pool.query(query, values);
        res.json(result.rows);

    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

// 3. CAMBIAR ESTADO DE LA CITA
export const cambiarEstadoCita = async (req, res) => {
    const { id_cita } = req.params;
    const { nuevo_estado } = req.body;

    // Validación simple de estados permitidos según tu check constraint
    const estadosPermitidos = ['Agendada','Confirmada','Cancelada','Pendiente','Reprogramada','Atendida','No asistio'];
    if (!estadosPermitidos.includes(nuevo_estado)) {
        return res.status(400).json({ error: "Estado no válido" });
    }

    try {
        const result = await pool.query(`
            UPDATE Cita 
            SET estado_cita = $1 
            WHERE id_cita = $2 
            RETURNING *
        `, [nuevo_estado, id_cita]);

        if (result.rowCount === 0) return res.status(404).json({ message: "Cita no encontrada" });

        res.json({ message: `Estado actualizado a ${nuevo_estado}` });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

// 4. BUSCAR DEUDA PARA COBRAR (Solo Citas Atendidas y con Deuda Pendiente)
export const buscarCitasParaCobro = async (req, res) => {
    const { termino } = req.query; // Puede ser nombre del paciente o fecha

    try {
        // Buscamos citas que estén 'Atendida' Y tengan saldo pendiente en la tabla Deuda
        let query = `
            SELECT 
                c.id_cita,
                c.fecha_hora,
                p.nombrespaciente || ' ' || p.apellidopat || ' ' || p.apellidomat AS nombre_paciente,
                d.monto_total,
                d.monto_pagado,
                d.saldo_pendiente,
                d.estado AS estado_deuda,

                (SELECT fn_obtener_detalle_deudas_historicas(c.id_paciente)) AS detalle_deudas_json

            FROM Cita c
            JOIN Paciente p ON c.id_paciente = p.id_paciente
            JOIN Deuda d ON c.id_cita = d.id_cita
            WHERE c.estado_cita = 'Atendida' 
            AND d.saldo_pendiente > 0
        `;

        const values = [];

        // Si mandan término, filtramos
        if (termino) {
            // Intentamos ver si es fecha (YYYY-MM-DD) o nombre
            const esFecha = /^\d{4}-\d{2}-\d{2}$/.test(termino);
            
            if (esFecha) {
                query += ` AND c.fecha_hora = $1`;
                values.push(termino);
            } else {
                query += ` AND (p.nombrespaciente ILIKE $1 OR p.apellidopat ILIKE $1)`;
                values.push(`%${termino}%`);
            }
        }

        query += ` ORDER BY c.fecha_hora DESC`;

        const result = await pool.query(query, values);
        res.json(result.rows);

    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

// 5. PROCESAR EL COBRO (Insertar Pago y Actualizar Deuda)
export const procesarCobro = async (req, res) => {
    const { id_cita, monto_a_pagar, id_metodo_pago } = req.body;

    const client = await pool.connect();
    try {
        await client.query('BEGIN');

        // A. Registrar el PAGO
        await client.query(`
            INSERT INTO Pago (cantidadPagada, id_cita, metodoPagoid_metodopago)
            VALUES ($1, $2, $3)
        `, [monto_a_pagar, id_cita, id_metodo_pago]);

        // B. Actualizar la DEUDA (Sumar lo pagado)
        // OJO: Tu trigger 'tr_actualizar_deuda' se encargará de calcular saldo_pendiente y el estado.
        await client.query(`
            UPDATE Deuda 
            SET monto_pagado = monto_pagado + $1
            WHERE id_cita = $2
        `, [monto_a_pagar, id_cita]);

        await client.query('COMMIT');
        res.json({ message: 'Cobro registrado exitosamente' });

    } catch (error) {
        await client.query('ROLLBACK');
        // Capturamos el error del trigger (ej: si paga más de lo que debe)
        console.error(error);
        res.status(400).json({ error: error.message });
    } finally {
        client.release();
    }
};

// 6. OBTENER METODOS DE PAGO (Para el select del cobro)
export const getMetodosPago = async (req, res) => {
    const result = await pool.query("SELECT * FROM Metodo_Pago");
    res.json(result.rows);
};

// Verifica si un dentista tiene libre una hora específica
// GET /api/citas/disponibilidad?fecha=2025-10-10&hora=10:00:00&id_dentista=5
export const consultarDisponibilidad = async (req, res) => {
    const { fecha, hora, id_dentista } = req.query;

    try {
        const result = await pool.query(`
            SELECT c.id_cita 
            FROM Cita c
            JOIN Usuario_Empleados_Cita uec ON c.id_cita = uec.id_cita
            WHERE c.fecha_hora = $1 
              AND c.hora = $2
              AND uec.id_usuario = $3
              AND c.estado_cita NOT IN ('Cancelada', 'No asistio')
        `, [fecha, hora, id_dentista]);

        if (result.rows.length > 0) {
            return res.status(200).json({ disponible: false, message: "Horario ocupado" });
        } else {
            return res.status(200).json({ disponible: true, message: "Horario disponible" });
        }

    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

export const getCitasFiltroLISTA = async (req, res) => {
    const { fecha, estado } = req.query;

    try {
        // Base de la consulta
        let query = `
            SELECT 
                c.id_cita, 
                c.fecha_hora, 
                c.hora, 
                c.estado_cita, 
                c.descripcion,
                p.nombrespaciente || ' ' || p.apellidopat || ' ' || COALESCE(p.apellidomat, '') AS nombre_paciente,
                p.telefono
            FROM Cita c
            JOIN Paciente p ON c.id_paciente = p.id_paciente
            WHERE 1=1
              AND c.estado_cita NOT IN ('Atendida')
        `;

        const values = [];
        let paramIndex = 1;

        // 🟦 FORMATEO DE FECHA (para manejar fechas ISO del datepicker)
        if (fecha) {
            const fechaLimpia = fecha.split("T")[0];  // ← SOLUCIÓN
            query += ` AND c.fecha_hora = $${paramIndex}`;
            values.push(fechaLimpia);
            paramIndex++;
        }

        // 🟦 FILTRO OPCIONAL POR ESTADO
        if (estado && estado !== 'Todos') {
            query += ` AND c.estado_cita = $${paramIndex}`;
            values.push(estado);
            paramIndex++;
        }

        query += ` ORDER BY c.hora ASC`;

        const result = await pool.query(query, values);
        res.json(result.rows);

    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

export const reprogramarCita = async (req, res) => {
    const { id_cita } = req.params;
    // id_recepcionista: para saber quién hizo el cambio (si quieres guardarlo)
    const { fecha, hora, id_dentista, id_recepcionista } = req.body; 

    const client = await pool.connect();
    try {
        await client.query('BEGIN');

        // 1. Actualizar Datos de la Cita
        const updateCita = await client.query(`
            UPDATE Cita
            SET fecha_hora = $1, hora = $2, estado_cita = 'Pendiente'
            WHERE id_cita = $3
            RETURNING id_cita
        `, [fecha, hora, id_cita]);

        if (updateCita.rowCount === 0) {
            throw new Error("Cita no encontrada");
        }

        // 2. Actualizar el Dentista asignado en Usuario_Empleados_Cita
        // Nota: Si el trigger 'tr_verificar_disponibilidad_dentista' salta, aquí atrapamos el error.
        await client.query(`
            UPDATE Usuario_Empleados_Cita
            SET id_usuario = $1
            WHERE id_cita = $2 AND tipo_empleado = 'Dentista'
        `, [id_dentista, id_cita]);

        // Opcional: Si quieres registrar qué recepcionista hizo el cambio,
        // podrías actualizar el registro de 'Recepcion' o insertar en una tabla de auditoría.
        // Por ahora, asumimos que se mantiene el recepcionista original o se actualiza si existe:
        if (id_recepcionista) {
             await client.query(`
                UPDATE Usuario_Empleados_Cita
                SET id_usuario = $1
                WHERE id_cita = $2 AND tipo_empleado = 'Recepcion'
            `, [id_recepcionista, id_cita]);
        }

        await client.query('COMMIT');
        res.json({ message: 'Cita reprogramada exitosamente' });

    } catch (error) {
        await client.query('ROLLBACK');
        console.error("Error al reprogramar:", error);

        // Manejo de errores de base de datos (Triggers o Constraints)
        if (error.code === '23505') {
            return res.status(400).json({ error: "El paciente ya tiene cita a esa hora." });
        }
        if (error.message && error.message.includes('El Dentista seleccionado ya tiene una cita')) {
            return res.status(409).json({ error: "El Dentista ya está ocupado en ese horario." });
        }

        res.status(500).json({ error: error.message || "Error al reprogramar" });
    } finally {
        client.release();
    }
};

export const getReporteIngresos = async (req, res) => {
    const { fechaInicio, fechaFin } = req.query;

    try {
        const query = `
            SELECT
                COALESCE(mp.nombre_metodo, 'TOTAL GENERAL') AS metodo_pago,
                COALESCE(t.nombre, 'SUBTOTAL PAGO') AS tratamiento,
                SUM(p.cantidadPagada) AS ingresos_totales
            FROM
                Pago p
            JOIN
                Metodo_Pago mp ON p.metodoPagoid_metodopago = mp.id_metodo_pago
            JOIN
                Detalle_Costo dc ON p.idPago = dc.id_pago
            JOIN
                Tratamiento t ON dc.id_tipo_tratamiento = t.id_tipo_tratamiento
            WHERE
                p.fecha_hora::DATE BETWEEN $1 AND $2
            GROUP BY
                ROLLUP(mp.nombre_metodo, t.nombre)
            ORDER BY
                metodo_pago, tratamiento;
        `;

        const result = await pool.query(query, [fechaInicio, fechaFin]);
        res.json(result.rows);

    } catch (error) {
        console.error("Error en reporte ingresos:", error);
        res.status(500).json({ error: error.message });
    }
};

// 11. REPORTE DE DEUDORES (EN EL RANGO DE FECHAS)
export const getReporteDeudoresRango = async (req, res) => {
    const { fechaInicio, fechaFin } = req.query;

    try {
        const query = `
            SELECT
                p.id_paciente,
                p.nombrespaciente || ' ' || p.apellidopat || ' ' || COALESCE(p.apellidomat, '') AS nombre_paciente,
                p.telefono,
                p.email,
                COUNT(c.id_cita) as citas_con_deuda,
                SUM(d.saldo_pendiente) as total_deuda
            FROM Cita c
            JOIN Paciente p ON c.id_paciente = p.id_paciente
            JOIN Deuda d ON c.id_cita = d.id_cita
            WHERE 
                c.fecha_hora BETWEEN $1 AND $2
                AND d.saldo_pendiente > 0
            GROUP BY 
                p.id_paciente, p.nombrespaciente, p.apellidopat, p.apellidomat, p.telefono, p.email
            ORDER BY 
                total_deuda DESC;
        `;

        const result = await pool.query(query, [fechaInicio, fechaFin]);
        res.json(result.rows);

    } catch (error) {
        console.error("Error en reporte deudores:", error);
        res.status(500).json({ error: error.message });
    }
};