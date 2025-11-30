import { Router } from "express";

import empleadosRoutes from "./empleados.routes.js";
import pacientesRoutes from "./pacientes.routes.js";


const router = Router();

// prefijos de las rutas
router.use("/empleados", empleadosRoutes);
router.use("/pacientes", pacientesRoutes);


export default router;
