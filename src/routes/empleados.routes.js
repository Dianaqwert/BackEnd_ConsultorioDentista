import { Router } from "express";
import { buscarEmpleado, getEmpleados,getListarEmpleados} from "../controllers/empleados.controller.js";

//rutas - manejo de vistas 
const router = Router();

router.get("/", getEmpleados);
//ruta de bisqueda de empleado para log in ->POST
router.post("/buscar",buscarEmpleado)
//pacientes

//_____________APARTADO DE DENTSTA - SUPER ADMIN 
router.get("/listar", getListarEmpleados);


export default router;
