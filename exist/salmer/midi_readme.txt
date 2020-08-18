For at undgå, at .data-filen til MIDI-afspilning (samplingen) skal ligge i serverroden, er

var REMOTE_PACKAGE_BASE="074_recorder.data";

ændret til

var REMOTE_PACKAGE_BASE="https://melodier.dsl.dk/cors.xq?res=/salmer/assets/074_recorder.data";

i 074_recorder.js. Scriptet CORS.xq gør også filen tilgængelig for forespørgsler på tværs af domæner (CORS) 

