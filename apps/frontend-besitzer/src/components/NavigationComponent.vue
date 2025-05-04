<template>
  <nav class="navigation">
    <ul>
      <li><router-link class="link" to="/">Home</router-link></li>
      <li><router-link class="link" to="/dashboard">Dashboard</router-link></li>
      <li><router-link class="link" to="/settings">Settings</router-link></li>
      <li><router-link class="link" to="/about">About</router-link></li>
    </ul>
  </nav>
</template>

<script lang="ts" setup></script>

<style scoped>
.navigation {
  display: flex;
  align-items: center;
  justify-content: center;
  padding-top: var(--hight-header);
}
ul {
  list-style-type: none;
  padding: 0;
  margin: 0;
  text-align: center;
  width: 100%;
}
li {
  margin-bottom: 25px;
  background-color: var(--color-primary);
  transition: background-color 0.2s ease-in-out;
}
li:hover {
  background-color: var(--color-accent);
}
.link {
  display: block;
  padding: 10px;
  text-decoration: none;
  color: var(--color-background);;
}
</style>