// Importiere Laufzeit-Funktionen normal
import { createRouter, createWebHistory } from 'vue-router';
// Importiere Typen explizit mit 'import type'
import type { RouteRecordRaw } from 'vue-router';

// import { defineComponent } from 'vue'; // Wird für diese Route nicht mehr benötigt

const routes: RouteRecordRaw[] = [
  {
    path: '/',
    name: 'home', // Du kannst den Namen auch in 'dashboard' ändern, wenn es besser passt
    // Ersetze die alte Komponente durch einen dynamischen Import
    component: () => import('../views/DashboardView.vue')
    // Annahme: '@' ist in deiner vite.config.ts als Alias für '/src' konfiguriert.
    // Falls nicht, verwende den relativen Pfad, z.B.:
    // component: () => import('../views/DashboardView.vue')
  },
  // ... hier könnten weitere Routen folgen
];

const router = createRouter({
  history: createWebHistory(),
  routes,
});

export default router;