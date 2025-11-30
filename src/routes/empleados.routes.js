import { Router } from "express";
import { buscarEmpleado, getEmpleados,getEmpleadosActivos,crearUsuario,
    getEmpleadosVista,getEmpleadosPorTipo,eliminarEmpleado,buscarEmpleadoPorNombre
} from "../controllers/empleados.controller.js";

//rutas - manejo de vistas 
const router = Router();

router.get("/", getEmpleados);
//ruta de bisqueda de empleado para log in ->POST
router.post("/buscar",buscarEmpleado);
//pacientes

//_____________APARTADO DE DENTSTA - SUPER ADMIN 
router.get("/getEmpleados",getEmpleadosActivos);
router.post("/usuarios", crearUsuario);
router.get("/activos", getEmpleadosVista);           // Cargar tabla inicial
router.get("/filtro/:tipo", getEmpleadosPorTipo);    // Filtrar con la función
router.get("/busqueda/:termino", buscarEmpleadoPorNombre); // Buscador
router.delete("/eliminar/:id", eliminarEmpleado);    // Dar de baja

export default router;
