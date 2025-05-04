<script setup lang="ts">
import NavigationComponent from './components/NavigationComponent.vue';

</script>

<template>
  <div class="container">
    <header>
      <h1>Header</h1> 
    </header>
    <nav>
      <NavigationComponent />
    </nav>
    <main class="content">
      <router-view />
    </main>
    <footer>
      <div>Footer</div>
    </footer>
  </div>
</template>

<style scoped>
.container{
  height: 100dvh;
  display: grid;
  grid-template-areas:
  "nav head head"
  "nav content content"
  "footer footer footer";
  grid-template-rows: var(--hight-header) 1fr var(--hight-footer);
  grid-template-columns: var(--width-nav) 1fr;
}

header {
  grid-area: head;
  background-color: var(--color-primary);
}

nav {
  grid-area: nav;
  background-color: var(--color-secondary);
}

.content{
  grid-area: content;
  background-color: var(--color-background);
}

footer{
  grid-area: footer;
  background-color: black;
  color: var(--color-background);
}
</style>

<style>
:root {
  --color-primary: #2f4de4;
  --color-secondary: #8ca0ff;
  --color-accent: #ff4081;
  --color-background: #e7e5e5;
  --color-text: #333333;

  --hight-header: 80px;
  --hight-footer: 60px;
  --width-nav: 200px;
}
</style>