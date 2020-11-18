#include "script_component.hpp"
/*
 * Author: Pterolatypus
 * Get the level of consciousness of the unit.
 *
 * Arguments:
 * 0: The Unit <OBJECT>
 *
 * Return Value:
 * Level of consciousness (0.0-1.0) <NUMBER>
 *
 * Example:
 * [player] call ace_medical_status_fnc_getConsciousness
 *
 * Public: No
 */
params ["_unit"];

_unit getVariable [QEGVAR(medical,bodyPartDamage), [0,0,0,0,0,0]] params ["_headDamage", "_bodyDamage"];
//stun is a kind of temporary damage
private _stun = _unit getVariable [QGVAR(stun),0];

private _brainFunction = 1 - 0.4*(_headDamage min 1) - 0.6*(_stun min 1);

if (_brainFunction == 0) exitWith {0}; //return

private _headBleeding = 0;
private _bodyBleeding = 0;
{
    _x params ["", "_bodyPart", "_amountOf", "_bleeding"];
    switch _bodyPart do {
		case 0: {
       		_headBleeding = _headBleeding + (_amountOf * _bleeding);
		};
		case 1: {
			_bodyBleeding = _bodyBleeding + (_amountOf * _bleeding);
		};
	};
} forEach GET_OPEN_WOUNDS(_unit);

//assume the body can compensate for extremity bleeding; the cumulative blood loss will catch up eventually
private _bloodLoss = (_headBleeding max _bodyBleeding)*EGVAR(medical,bleedingCoefficient);
private _coRatio = ([_unit] call FUNC(getCardiacOutput))/0.1266;
//a small amount of blood loss is manageable, but deteriorates quickly beyond that
private _bloodFlow = linearConversion [0.5, 0.9, (1-_bloodLoss)*_coRatio, 0, 1, true];

if (_bloodFlow == 0) exitWith {0}; //return

private _bpHi = GET_BLOOD_PRESSURE(_unit) select 1;
//blood pressure is important independently of CO because it affects tissue perfusion - below a certain point not enough blood is actually going into the tissue
//systolic bp <100 is reduced loc, <70 is permanent uncon (consciousness < 0.6)
private _bpFactor = linearConversion [50, 100, _bpHi, 0, 1, true];

if (_bpFactor == 0) exitWith {0};

//TODO: consider factoring in body damage (reduced lung function) or some simplified spO2 simulation
//TODO: should pain be factored in

_brainFunction*_bloodFlow*_bpFactor
