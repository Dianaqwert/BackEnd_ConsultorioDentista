import { Router } from "express";
import { getPacientes, getPacienteByNombres,getReporteCompletoByPacienteId,
    getDerivaciones,getHistorialPaciente,getTratamientoRealizado,
    getListaMateriales,getListaTratamientos,registrarAtencionCompleta,getCitasAgendadas,
    getDetalleCitaEspecifica,getUltimoHistorialPaciente,
    getCitasPorFecha,
} from "../controllers/pacientes.controller.js";

const router = Router();


//PACIENTES_______________________________________________________________________________________________
router.get("/", getPacientes);
//ruta para buscar por nombre y apellidos a pácientes
router.get("/buscar", getPacienteByNombres);
//_________________________________________PRUTAS UTILIZADAS PARA EL DOCTOR_________________________________
router.get("/:id/reporte-completo",getReporteCompletoByPacienteId);
router.get("/:id/derivaciones-externas",getDerivaciones)
router.get("/:id/historial-paciente",getHistorialPaciente)
router.get("/:id/tratamiento-paciente",getTratamientoRealizado)

// Estas rutas llenan los "Select" del formulario _____________________PACIENTES PARA ALTAS
router.get("/catalogos/tratamientos", getListaTratamientos);
router.get("/catalogos/materiales", getListaMateriales);
// Esta es la que recibe el JSON gigante con historial, tratamientos, etc.
router.post("/atencion-cita", registrarAtencionCompleta);
router.get("/citas/agendadas", getCitasAgendadas);
router.get("/citas/filtro", getCitasPorFecha);
//edita una cita
router.get("/cita/:id_cita/detalles", getDetalleCitaEspecifica);
router.get("/paciente/:id_paciente/ultimo-historial", getUltimoHistorialPaciente);
//_________________________________________APARTADO DE RECEPCIONISTA___________________________________________________________________________________
//_______________________________________

export default router;

