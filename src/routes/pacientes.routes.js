import { Router } from "express";
import { getPacientes, getPacienteByNombres } from "../controllers/pacientes.controller.js";

const router = Router();

//PACIENTES_______________________________________________________________________________________________
router.get("/", getPacientes);
//ruta para buscar por nombre y apellidos a pácientes
router.get("/buscar", getPacienteByNombres);

export default router;
