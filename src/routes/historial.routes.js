import { Router } from "express";
import { getHistorial } from "../controllers/empleados.controller.js";

const router = Router();

router.get("/:id", getHistorial);

export default router;
