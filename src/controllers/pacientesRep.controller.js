import { pool } from "../../conexion.js";


// buscar POR NOMBRES Y APELLIDOS (CORREGIDO)
export const getPacienteByNombres = async (req, res) => {
    const { nombre, apellidoPat, apellidoMat } = req.query; 

    // Concatenamos todo lo que llegue para buscar libremente
    // Ejemplo: Si escriben "Juan Perez", buscamos eso en toda la cadena de nombre
    const criterioBusqueda = `${nombre || ''} ${apellidoPat || ''} ${apellidoMat || ''}`.trim();

    try {
        // 1. CAMBIO IMPORTANTE: Consultamos la tabla 'Paciente' directamente, no la vista.
        // Usamos CONCAT para simular una columna de nombre completo y buscar sobre ella.
        let query = `
            SELECT *
            FROM Paciente 
            WHERE 
                (nombresPaciente || ' ' || apellidoPat || ' ' || apellidoMat) ILIKE $1
            ORDER BY nombresPaciente
        `;
        
        // El ILIKE con % permite buscar partes del nombre
        // .split(' ').join('%') convierte "Juan Perez" en "%Juan%Perez%" para búsquedas flexibles
        const values = [`%${criterioBusqueda.split(' ').join('%')}%`];

        const result = await pool.query(query, values);

        if (result.rows.length === 0)
            return res.status(404).json({ message: "Paciente no encontrado con esos criterios" });

        // Postgres devuelve los nombres de columnas en minúsculas por defecto
        // (nombrespaciente, apellidopat, etc.), lo cual COINCIDE con tu interfaz de Angular.
        res.json(result.rows);

    } catch (error) {
        console.error("Error al buscar paciente:", error);
        res.status(500).json({ error: "Error interno del servidor al buscar paciente." });
    }
};

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

export const crearPaciente = async (req, res) => {
    const { nombresPaciente, apellidoPat, apellidoMat, telefono, email } = req.body;

    if (!nombresPaciente || !apellidoPat || !telefono || !email) {
        return res.status(400).json({ error: 'Faltan campos obligatorios.' });
    }

    try {
        // PASO 1: VERIFICAR SI YA EXISTE (NUEVO CÓDIGO)
        // Usamos ILIKE para que no importe si escribieron "JUAN" o "Juan"
        const duplicado = await pool.query(`
            SELECT id_paciente 
            FROM Paciente 
            WHERE nombrespaciente ILIKE $1 
            AND apellidopat ILIKE $2 
            AND apellidomat ILIKE $3
        `, [nombresPaciente, apellidoPat, apellidoMat]);

        if (duplicado.rows.length > 0) {
            // Código 409 = Conflicto
            return res.status(409).json({ 
                error: 'Ya existe un paciente registrado con ese Nombre y Apellidos.' 
            });
        }

        // PASO 2: SI NO EXISTE, LO CREAMOS (TU CÓDIGO ORIGINAL)
        const query = `
            INSERT INTO Paciente (nombresPaciente, apellidoPat, apellidoMat, telefono, email)
            VALUES ($1, $2, $3, $4, $5)
            RETURNING * `;
        
        const values = [nombresPaciente, apellidoPat, apellidoMat, telefono, email];
        const result = await pool.query(query, values);

        res.status(201).json({
            mensaje: 'Paciente registrado exitosamente',
            paciente: result.rows[0]
        });

    } catch (error) {
        console.error('Error al crear paciente:', error);

        // Mantenemos la protección de correo por si acaso
        if (error.code === '23505') {
            return res.status(400).json({ 
                error: 'El correo electrónico o teléfono ya está registrado.' 
            });
        }

        res.status(500).json({ error: 'Error interno al registrar el paciente.' });
    }
};

export const crearDireccion = async (req, res) => {
    const { cp, calle, colonia, municipio, numeroInt, numeroExt, id_paciente } = req.body;

    if (!calle || !colonia || !municipio || !id_paciente) {
        return res.status(400).json({ error: 'Faltan campos obligatorios para la dirección.' });
    }

    try {
        const query = `
            INSERT INTO Direccion (CP, calle, colonia, municipio, numeroInt, numeroExt, id_paciente)
            VALUES ($1, $2, $3, $4, $5, $6, $7)
            RETURNING *
        `;
        const values = [cp, calle, colonia, municipio, numeroInt, numeroExt, id_paciente];
        
        await pool.query(query, values);
        
        res.status(201).json({ mensaje: 'Dirección guardada correctamente' });

    } catch (error) {
        console.error(error);
        if (error.code === '23505') { // Unique violation
            return res.status(400).json({ error: 'Este paciente ya tiene una dirección asignada.' });
        }
        res.status(500).json({ error: 'Error al guardar dirección' });
    }
};


// Actualizar datos básicos del paciente
export const actualizarPaciente = async (req, res) => {
    const { id } = req.params; // Viene de la URL /:id
    const { nombresPaciente, apellidoPat, apellidoMat, telefono, email } = req.body;

    // Validación básica
    if (!nombresPaciente || !apellidoPat || !telefono || !email) {
        return res.status(400).json({ error: 'Todos los campos son obligatorios.' });
    }

    try {
        const query = `
            UPDATE Paciente
            SET 
                nombresPaciente = $1,
                apellidoPat = $2,
                apellidoMat = $3,
                telefono = $4,
                email = $5
            WHERE id_paciente = $6
            RETURNING * -- Para devolver el registro actualizado
        `;

        const values = [nombresPaciente, apellidoPat, apellidoMat, telefono, email, id];
        
        const result = await pool.query(query, values);

        if (result.rows.length === 0) {
            return res.status(404).json({ message: "Paciente no encontrado" });
        }

        res.json({
            mensaje: "Paciente actualizado correctamente",
            paciente: result.rows[0]
        });

    } catch (error) {
        console.error("Error al actualizar paciente:", error);

        // Si intenta poner un email/teléfono que YA usa otro paciente
        if (error.code === '23505') {
            return res.status(409).json({ 
                error: 'El correo electrónico o teléfono ya pertenece a otro paciente.' 
            });
        }

        res.status(500).json({ error: "Error interno al actualizar." });
    }
};