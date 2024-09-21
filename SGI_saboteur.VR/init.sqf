_var = [] execVM "SGI_saboteur\SGI_saboteur.sqf";

waitUntil {scriptDone _var};

[] spawn SGI_sab_init;
