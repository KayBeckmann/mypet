<template>
    <h1>Meine Tiere</h1>
    <table>
        <thead>
            <tr>
                <th>Tier</th>
                <th>Rasse</th>
                <th>Alter</th>
            </tr>
        </thead>
        <tbody>
            <tr v-for="tier in tiere" :key="tier.id">
                <td>{{ tier.name }}</td>
                <td>{{ tier.rasse }}</td>
                <td>{{ tier.alter }}</td>
            </tr>
        </tbody>
    </table>
    <div class="tasks">
        <h2>Tägliche Aufgaben:</h2>
        <ul>
            <li>Füttern</li>
            <li>Gassi gehen</li>
            <li>Tierarztbesuch</li>
            <li>Pflegen</li>
            <li>Spielen</li>
            <li>Sauber machen</li>
        </ul>
    </div>
</template>

<script lang="ts" setup>
import { defineComponent, ref } from 'vue';

let tiere = ref([
    { id: 1, name: 'Bello', rasse: 'Labrador', alter: 5 },
    { id: 2, name: 'Miau', rasse: 'Siamkatze', alter: 3 },
    { id: 3, name: 'Fido', rasse: 'Beagle', alter: 4 },
]);

</script>

<style scoped>
</style>