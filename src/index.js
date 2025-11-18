import express from "express";
import cors from "cors";

// Importar TODAS las rutas (nombres deben coincidir con los archivos)
import empleadosRoutes from "./routes/empleados.routes.js";
import pacientesRoutes from "./routes/pacientes.routes.js";   // <--- plural 'pacientes'
import historialRoutes from "./routes/historial.routes.js";
import citasRoutes from "./routes/citas.routes.js";
// si tienes tratamientosRoutes:
// import tratamientoRoutes from "./routes/tratamientos.routes.js";

const app = express();
app.use(cors());
app.use(express.json());

// Usar TODAS las rutas
app.use("/api/empleados", empleadosRoutes);
app.use("/api/pacientes", pacientesRoutes);
app.use("/api/historial", historialRoutes);
app.use("/api/citas", citasRoutes);
// app.use("/api/tratamientos", tratamientoRoutes);

const PORT = 3000;
app.listen(PORT, () => console.log(`Servidor corriendo en puerto ${PORT}`));

