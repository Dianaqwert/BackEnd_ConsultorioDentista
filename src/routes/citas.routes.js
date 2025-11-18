import { Router } from "express";
import { getCitas } from "../controllers/empleados.controller.js";

const router = Router();

router.get("/:id", getCitas);

export default router;

