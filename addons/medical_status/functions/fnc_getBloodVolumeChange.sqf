#include "script_component.hpp"
/*
 * Author: Glowbal
 * Calculates the blood volume change and decreases the IVs given to the unit.
 *
 * Arguments:
 * 0: The Unit <OBJECT>
 * 1: Time since last update <NUMBER>
 * 2: Global Sync Values (bloodbags) <BOOL>
 *
 * Return Value:
 * Blood volume change (liters per second) <NUMBER>
 *
 * Example:
 * [player, 1, true] call ace_medical_status_fnc_getBloodVolumeChange
 *
 * Public: No
 */

params ["_unit", "_deltaT", "_syncValues"];

private _bloodVolumeChange = -_deltaT * GET_BLOOD_LOSS(_unit);
private _bloodO2Portion = GET_BLOOD_O2(_unit) / GET_BLOOD_VOLUME(_unit);
private _bloodO2Change = _bloodVolumeChange * _bloodO2Portion;
TRACE_3("Blood change",_bloodVolumeChange, _bloodO2Portion, _bloodO2Change);

if (!isNil {_unit getVariable QEGVAR(medical,ivBags)}) then {
    private _bloodBags = _unit getVariable [QEGVAR(medical,ivBags), []];
    private _tourniquets = GET_TOURNIQUETS(_unit);

    _bloodBags = _bloodBags apply {
        _x params ["_bagVolumeRemaining", "_type", "_bodyPart", "_oxygenRemaining"];

        if (_tourniquets select _bodyPart == 0) then {
            private _bagChange = (_deltaT * EGVAR(medical,ivFlowRate) * IV_CHANGE_PER_SECOND) min _bagVolumeRemaining; // absolute value of the change in miliLiters
            private _bagO2Change = _bagChange * _oxygenRemaining/_bagVolumeRemaining;
            
            _bagVolumeRemaining = _bagVolumeRemaining - _bagChange;
            _oxygenRemaining = _oxygenRemaining - _bagO2Change;
            
            _bloodVolumeChange = _bloodVolumeChange + (_bagChange / 1000);
            _bloodO2Change = _bloodO2Change + (_bagO2Change / 1000);
            TRACE_2("IV change",_bloodVolumeChange,_bloodO2Change);
        };

        if (_bagVolumeRemaining < 0.01) then {
            []
        } else {
            [_bagVolumeRemaining, _type, _bodyPart, _oxygenRemaining]
        };
    };

    _bloodBags = _bloodBags - [[]]; // remove empty bags

    if (_bloodBags isEqualTo []) then {
        _unit setVariable [QEGVAR(medical,ivBags), nil, true]; // no bags left - clear variable (always globaly sync this)
    } else {
        _unit setVariable [QEGVAR(medical,ivBags), _bloodBags, _syncValues];
    };
};

[_bloodVolumeChange, _bloodO2Change]
