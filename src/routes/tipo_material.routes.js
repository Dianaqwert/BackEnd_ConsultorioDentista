import { Router } from "express";
import {
    obtenerTiposMateriales,
    crearTipoMaterial,
    eliminarTipoMaterial,
    buscarTiposMateriales // Nuevo controlador importado
} from "../controllers/tipo_material.controller.js";

const router = Router();

// 1. CONSULTA: GET /api/tipo-material
router.get('/', obtenerTiposMateriales);

// 4. BÚSQUEDA: GET /api/tipo-material/buscar?term=valor
// Es crucial que esta ruta vaya antes de la ruta DELETE /:id
router.get('/buscar', buscarTiposMateriales);

// 2. ALTA: POST /api/tipo-material
router.post('/', crearTipoMaterial);

// 3. BAJA: DELETE /api/tipo-material/:id
router.delete('/:id', eliminarTipoMaterial);

export default router;
