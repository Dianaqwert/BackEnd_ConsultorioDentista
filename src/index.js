import express from "express";
import cors from "cors";

// Importar TODAS las rutas (nombres deben coincidir con los archivos)
import empleadosRoutes from "./routes/empleados.routes.js";
import pacientesRoutes from "./routes/pacientes.routes.js";   // <--- plural 'pacientes'
import tratamientosRoutes from "./routes/tratamientos.routes.js";
import inventarioRoutes from "./routes/inventario.routes.js"
import pacientesRepRoutes from "./routes/pacientesRep.routes.js"
import citasPagosRoutes from "./routes/citasPagos.routes.js"
// si tienes tratamientosRoutes:
// import tratamientoRoutes from "./routes/tratamientos.routes.js";

const app = express();
app.use(cors());
app.use(express.json());

// Usar TODAS las rutas
app.use("/api/empleados", empleadosRoutes);
app.use("/api/pacientes", pacientesRoutes);
app.use("/api/tratamientos",tratamientosRoutes);
app.use("/api/inventario",inventarioRoutes);
app.use("/api/pacientesRep",pacientesRepRoutes);
app.use("/api/citasPagos",citasPagosRoutes);



// app.use("/api/tratamientos", tratamientoRoutes);

const PORT = 3000;
app.listen(PORT, () => console.log(`Servidor corriendo en puerto ${PORT}`));

