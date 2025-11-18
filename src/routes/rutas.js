import { Router } from "express";

import empleadosRoutes from "./empleados.routes.js";
import pacientesRoutes from "./pacientes.routes.js";
import historialRoutes from "./historial.routes.js";
import citasRoutes from "./citas.routes.js";
import tratamientosRoutes from "./tratamientos.routes.js";

const router = Router();

// prefijos de las rutas
router.use("/empleados", empleadosRoutes);
router.use("/pacientes", pacientesRoutes);
router.use("/historial", historialRoutes);
router.use("/citas", citasRoutes);
router.use("/tratamientos", tratamientosRoutes);

export default router;
