import { Router } from "express";
const router = Router();
import {obtenerReporteBajoStock,obtenerCategoriasAltoValor,obtenerInventarioAgrupado} from "../controllers/inventario.controller.js"

router.get('/bajo-stock', obtenerReporteBajoStock);//
// GET /api/inventario/alto-valor?monto=X
router.get('/alto-valor', obtenerCategoriasAltoValor);//
// GET /api/inventario/general
router.get('/general', obtenerInventarioAgrupado); //

export default router;
