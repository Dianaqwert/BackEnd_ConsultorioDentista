import { Router } from "express";

import empleadosRoutes from "./empleados.routes.js";
import pacientesRoutes from "./pacientes.routes.js";
import tratamientosRoutes from "./tratamientos.routes.js";



const router = Router();

// prefijos de las rutas
router.use("/empleados", empleadosRoutes);
router.use("/pacientes", pacientesRoutes);
router.use("/tratamientos",tratamientosRoutes);



export default router;
