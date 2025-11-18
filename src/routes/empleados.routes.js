import { Router } from "express";
import { buscarEmpleado, getEmpleados } from "../controllers/empleados.controller.js";

//rutas - manejo de vistas 
const router = Router();

router.get("/", getEmpleados);
//ruta de bisqueda de empleado para log in ->POST
router.post("/buscar",buscarEmpleado)
//pacientes



export default router;
