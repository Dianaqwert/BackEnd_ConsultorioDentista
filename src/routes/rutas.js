import { Router } from "express";

import empleadosRoutes from "./empleados.routes.js";
import pacientesRoutes from "./pacientes.routes.js";
import tratamientosRoutes from "./tratamientos.routes.js";
import inventarioRoutes from "./inventario.routes.js"


const router = Router();

// prefijos de las rutas
router.use("/empleados", empleadosRoutes);
router.use("/pacientes", pacientesRoutes);
router.use("/tratamientos",tratamientosRoutes);
router.use("/inventario",inventarioRoutes)


export default router;
