import app from './app'; // Importiere die konfigurierte App
import dotenv from 'dotenv';

dotenv.config();

const PORT = process.env.PORT || 3000;

// Server Start
app.listen(PORT, () => {
  console.log(`[server]: Backend-Server läuft auf http://localhost:${PORT}`);
});
