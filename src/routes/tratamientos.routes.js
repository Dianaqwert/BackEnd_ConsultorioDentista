import { Router } from "express";
import { crearTratamiento, obtenerTratamientos,obtenerPacientesTratamientosInactivos,
  ajustarPrecio,obtenerPromedioPrecios,
  eliminarTratamiento,obtenerInactivos} 
  from "../controllers/tratamientos.controller.js"
const router = Router();

router.get('/',obtenerTratamientos);
// Ruta para dar de ALTA
router.post('/',crearTratamiento);
// Ruta para dar de BAJA (Se pasa el ID en la URL)
router.delete('/:id', eliminarTratamiento);
router.get('/inactivos', obtenerInactivos); // <--- NUEVA RUTA PARA LOS ARCHIVADOS
router.get('/reporte-pacientes-inactivos', obtenerPacientesTratamientosInactivos);
router.get('/promedio', obtenerPromedioPrecios); // <--- NUEVA RUTA PROMEDIO
router.put('/ajustar-precio/:id', ajustarPrecio);


export default router;
