import { Router } from "express";
import { getPacientes, getPacienteByNombres } from "../controllers/empleados.controller.js";

const router = Router();

router.get("/", getPacientes);
//ruta para buscar por nombre y apellidos a clientes
router.get("/buscar", getPacienteByNombres);

export default router;
