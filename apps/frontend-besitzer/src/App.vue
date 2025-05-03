<script setup lang="ts">
</script>

<template>
  <div class="content">
    <nav>
      <h1>Besitzer</h1> 
    </nav>
    <main>
      <router-view />
    </main>
    <footer>
      <h1>Footer</h1>
    </footer>
  </div>
</template>

<style scoped>
.content{
  background-color: purple;
  height: 100dvh;
  display: grid;
}
</style>