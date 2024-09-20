


//________________	Author : RevDogma	___________	19.09.24___________


/*
________________	SGI Sabateur Script (AKA: The Israeli Kiss)	_______


//________________	Place this code in the init.sqf	___________________

[] execVM "SGI_saboteur\SGI_saboteur.sqf";

//________________	Place this code in the Description.ext	___________

#include "SGI_saboteur\Control.hpp"

*/

//------------------------Settings------------------------------------------

SGI_sab_time = 5;                                                                                                                                //Sets how long the hold interaction last

SGI_sab_class = ["Land_Laptop_device_F", "Target_0", "Target_1", "Target_2", "Land_MobilePhone_old_F", "Land_WoodenCrate_01_F"];                 //Add classes or vehicleVariable names    

SGI_sab_total = 3;                                                                                                                               //Sets how many objects a player can arm at once

//------------------------ End Settings-------------------------------------


SGI_sab_objs = [];

SGI_sab_acts = [];

SGI_sab_armed = [];

SGI_sab_count = 0;

SGI_sab_ObjPick = "";

SGI_sab_items = {

    params ["_objs"];

    { 
        if !(_x in SGI_sab_objs) then {

            if !(count SGI_sab_armed >= SGI_sab_total) then {

                _act = [
                    _x,														                // Object the action is attached to
                    "Sabotage Item",												        // Title of the action
                    "\a3\ui_f_oldman\data\IGUI\Cfg\holdactions\destroy_ca.paa", 	        // Idle icon shown on screen
                    "\a3\ui_f_oldman\data\IGUI\Cfg\holdactions\destroy_ca.paa",	            // Progress icon shown on screen
                    "_this distance _target < 3",								            // Condition for the action to be shown
                    "_caller distance _target < 3",									        // Condition for the action to progress
                    {},																        // Code executed when action starts
                    {},																        // Code executed on every progress tick
                    {SGI_sab_armed = SGI_sab_armed + [_target]; hint "Explosive planted!";},	// Code executed on completion
                    {},																        // Code executed on interrupted
                    [],																        // Arguments passed to the scripts as _this select 3
                    SGI_sab_time,															// Action duration in seconds
                    0,																        // Priority
                    true,															        // Remove on completion
                    false															        // Show in unconscious state
                ] call BIS_fnc_holdActionAdd;

                SGI_sab_objs = SGI_sab_objs + [_x];

                SGI_sab_acts = SGI_sab_acts +[_act];
            };
        };

    } forEach _objs;
};

SGI_sab_init = {

    _pos = getPos player;

    player addAction
    [
        "Phone",	// title
        {
            params ["_target", "_caller", "_actionId", "_arguments"]; // script

            [] spawn SGI_sab_PhoneScreen;
        },
        nil,		// arguments
        0,		    // priority
        false,		// showWindow
        true,		// hideOnUse
        "",			// shortcut
        "true",		// condition
        5,			// radius
        false,		// unconscious
        "",			// selection
        ""			// memoryPoint
    ];
     
    _con = format ["thisList findIf {(vehicleVarName _x) in %1 or typeOf _x in %1} > -1;", SGI_sab_class];

    _act = format ["
    
        _array = []; 

        {
            _type = typeOf _x;

            _name = vehicleVarName _x;

            if (_type in %1) then {
            
                _array = _array + [_x];
            };

            if (_name in %1) then {
            
                _array = _array + [_x];
            };
            
        } forEach thisList; 
        
       [_array] call SGI_sab_items;
        
    ", SGI_sab_class];

    _end = format ["
    
        {
            _ind = SGI_sab_objs findIf {_x == _x};

            _obj = SGI_sab_objs select _ind;

            _act = SGI_sab_acts select _ind;

            _obj removeAction _act;

            SGI_sab_objs deleteAt _ind;

            SGI_sab_acts deleteAt _ind;

        } forEach SGI_sab_objs"];

    _trig = createTrigger ["EmptyDetector", _pos, false];
    _trig setTriggerArea [1.5, 1.5, 0, false, 1.5];
    _trig setTriggerActivation ["ANY", "PRESENT", true];
    _trig setTriggerStatements [_con, _act, _end];

    while {alive player} do {

       _trig setPos getPos player;

       sleep .25
    };

    waitUntil {!alive player};

    deleteVehicle _trig;
};

SGI_sab_PhoneScreen = {

    closeDialog 2;

    _display = createDialog "SGIPhone";

    _btnClose = displayCtrl 1600;

    _btnPhone = displayCtrl 1601;

    _btnClose ctrlAddEventHandler ["ButtonClick", "closeDialog 2;"];

    _btnPhone ctrlAddEventHandler ["ButtonClick", "

        [] spawn SGI_sab_CallScreen;
    "];
};

SGI_sab_CallScreen = {

    closeDialog 2;

    _display = createDialog "SGIcall";

    _btnCall = displayCtrl 1602;

    _list = displayCtrl 1500;

    {
        _class = typeOf _x;

        _name = getText (configfile >> "CfgVehicles" >> _class >> "displayName");

        _txt = format ["%1", _name];

        _indx = lbAdd [1500, _txt];

        _data = str _x;

        lbSetData [1500, _indx, _data];

    } forEach SGI_sab_armed;

    _btnCall ctrlAddEventHandler ["ButtonClick", "

        if (SGI_sab_ObjPick != '') then {

            _obj = SGI_sab_armed select SGI_sab_index;

            _pos = getPos _obj;

            _explosive = createMine ['APERSMineDispenser_Mine_F', _pos, [], 0];

            _explosive setDamage 1;

            _obj setDamage 1;

            lbDelete [1500, SGI_sab_index];

            _ind= SGI_sab_armed findIf {_x isEqualTo _obj};

            SGI_sab_armed deleteAt _ind;

            SGI_sab_ObjPick = '';
        };
    "];

    _list ctrlAddEventHandler ["LBSelChanged", "

        params ['_control', '_lbCurSel', '_lbSelection'];

        _lbCurSel = _this select 1; 

        SGI_sab_ObjPick = lbData [1500, _lbCurSel];

        SGI_sab_index = _lbCurSel;
    "];
};