For at undgå, at .data-filen til MIDI-afspilning skal ligge i serverroden, er

var REMOTE_PACKAGE_BASE="074_recorder.data";

ændret til

var REMOTE_PACKAGE_BASE="/static/074_recorder.data";

i 074_recorder.js

Tilsvarende skal gøres med de andre .js-filer, hvis andre lyde skal bruges.