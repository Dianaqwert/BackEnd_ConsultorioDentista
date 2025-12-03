import { Router } from "express";
import { actualizarPaciente, crearDireccion,crearPaciente,getPacienteByNombres,getPacientes } from "../controllers/pacientesRep.controller.js";
const router = Router();

// 1. BUSCAR (GET)
// URL final: /api/pacientes-rep/buscar?nombre=Juan
router.get('/buscar', getPacienteByNombres);
router.get('/', getPacientes); // <--- ESTA ES LA CLAVE
// 2. CREAR (POST)
// URL final: /api/pacientes-rep/
router.post('/', crearPaciente); 

// 3. CREAR DIRECCIÓN (POST)
// URL final: /api/pacientes-rep/direccion
router.post('/direccion', crearDireccion);

// 4. ACTUALIZAR (PUT)
// URL final: /api/pacientes-rep/:id (El :id es dinámico, ej: 15)
router.put('/:id', actualizarPaciente);
export default router;
