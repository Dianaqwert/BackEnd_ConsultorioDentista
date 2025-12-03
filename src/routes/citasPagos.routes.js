import { Router } from "express";
import { 
    crearCita,
    getCitasFiltro,
    getMetodosPago,
    getCitasFiltroLISTA,      // <-- Agrega esta coma
    consultarDisponibilidad,
    cambiarEstadoCita,
    buscarCitasParaCobro,reprogramarCita,
    procesarCobro,getReporteIngresos,getReporteDeudoresRango
} from "../controllers/citasPagos.controller.js";
const router = Router();

// Rutas generales
router.post('/', crearCita);                   // Crear nueva cita
router.get('/', getCitasFiltro);               // Listar citas (con filtros ?fecha=X&estado=Y)
router.get("/listar",getCitasFiltroLISTA);

// Rutas de cobranza
router.post('/cobranza/pagar', procesarCobro);            // Ejecutar el pago
router.get('/cobranza/metodos', getMetodosPago);
router.get('/disponibilidad', consultarDisponibilidad);
router.get('/cobranza/pendientes', buscarCitasParaCobro);
router.get('/cobranza/metodos', getMetodosPago);
router.patch('/:id_cita/estado', cambiarEstadoCita);
// Nueva Ruta para Reprogramar (PUT es ideal para actualizaciones completas)
router.put('/:id_cita/reprogramar', reprogramarCita);
//reportes
router.get('/reportes/ingresos', getReporteIngresos);
router.get('/reportes/deudores', getReporteDeudoresRango);


export default router;
