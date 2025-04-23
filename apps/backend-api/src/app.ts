import express, { Express, Request, Response, NextFunction } from 'express';
import cors from 'cors';
// Importiere deine Routen
// import besitzerRoutes from './modules/besitzer/besitzer.routes';

const app: Express = express();

// Middleware
app.use(cors(/* Optionen */));
app.use(express.json());

// Routen
app.get('/api', (req: Request, res: Response) => {
  res.json({ message: 'Hallo von mypet Backend! (aus app.ts)' });
});
// app.use('/api/besitzer', besitzerRoutes);
// ... andere Routen

// Fehlerbehandlung (optional hier oder in server.ts)
app.use((req: Request, res: Response, next: NextFunction) => {
   res.status(404).json({ message: 'Route nicht gefunden' });
});
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
   console.error(err.stack);
   res.status(500).json({ message: 'Interner Serverfehler', error: err.message });
});


export default app; // Exportiere die konfigurierte App
