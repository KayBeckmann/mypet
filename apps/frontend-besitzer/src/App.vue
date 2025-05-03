<script setup lang="ts">
</script>

<template>
  <div class="content">
    <header>
      <h1>Header</h1> 
    </header>
    <nav>
      <h1>Navigation</h1>
    </nav>
    <main class="content">
      <!-- <router-view /> -->
       <h1>content</h1>
    </main>
    <footer>
      <h1>Footer</h1>
    </footer>
  </div>
</template>

<style scoped>
.content{
  height: 100dvh;
  display: grid;
  grid-template-areas:
  "nav head head"
  "nav content content"
  "footer footer footer";
  grid-template-rows: 50px 1fr 30px;
  grid-template-columns: 150px 1fr;
}

header {
  grid-area: head;
  background-color: #8ca0ff;
}

nav {
  grid-area: nav;
  background-color: lightgreen;
}

.content{
  grid-area: content;
  background-color: yellow;
}

footer{
  grid-area: footer;
  background-color: black;
  color: white;
}
</style>