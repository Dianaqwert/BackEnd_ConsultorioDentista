import { Router } from "express";
import {
    obtenerMateriales,
    crearMaterial,
    eliminarMaterial,
    buscarMateriales,
    actualizarMaterial
} from "../controllers/material_tratamiento.controller.js";

const router = Router();

router.get('/', obtenerMateriales);
router.get('/buscar', buscarMateriales);
router.post('/', crearMaterial);
router.delete('/:id', eliminarMaterial);
router.put('/:id', actualizarMaterial);

export default router;
