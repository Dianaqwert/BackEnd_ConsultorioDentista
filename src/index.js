import express from "express";
import cors from "cors";

import empleadosRoutes from "./routes/empleados.routes.js";
import pacientesRoutes from "./routes/pacientes.routes.js";  
import tratamientosRoutes from "./routes/tratamientos.routes.js";
import inventarioRoutes from "./routes/inventario.routes.js"
import pacientesRepRoutes from "./routes/pacientesRep.routes.js"
import citasPagosRoutes from "./routes/citasPagos.routes.js"
import tipoMaterialRoutes from "./routes/tipo_material.routes.js";
import materialTratamientoRoutes from "./routes/material_tratamiento.routes.js";


const app = express();
app.use(cors());
app.use(express.json());

app.use("/api/empleados", empleadosRoutes);
app.use("/api/pacientes", pacientesRoutes);
app.use("/api/tratamientos",tratamientosRoutes);
app.use("/api/inventario",inventarioRoutes);
app.use("/api/pacientesRep",pacientesRepRoutes);
app.use("/api/citasPagos",citasPagosRoutes);
app.use("/api/tipo-material", tipoMaterialRoutes);
app.use("/api/material-tratamiento", materialTratamientoRoutes);


const PORT = 3000;
app.listen(PORT, () => console.log(`Servidor corriendo en puerto ${PORT}`));
