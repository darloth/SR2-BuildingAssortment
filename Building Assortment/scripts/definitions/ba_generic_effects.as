import buildings;
from buildings import IBuildingHook;
import resources;
import util.formatting;
import systems;
import saving;
import influence;
from influence import InfluenceStore;
from statuses import IStatusHook, Status, StatusInstance;
from resources import integerSum, decimalSum;
from bonus_effects import BonusEffect;
import orbitals;
from orbitals import IOrbitalEffect;
import attributes;
import hook_globals;
import research;
import empire_effects;
import repeat_hooks;
import planet_types;
#section server
import object_creation;
from components.ObjectManager import getDefenseDesign;
#section all

class GenerateCargoPerSecond : GenericEffect {
	Document doc("Generates a specified amount of cargo per second");
	Argument type(AT_Cargo, doc="Type of cargo to generate.");
	Argument amount(AT_Decimal, doc="Amount of cargo to generate per second.");

#section server
	void tick(Object& obj, any@ data, double time) const override {
		if(type is null || !obj.hasCargo)
			return;
		double cap = obj.cargoCapacity - obj.cargoStored;
		double timeScaledAmount = amount.decimal * time;
		if(cap > timeScaledAmount)
			obj.addCargo(type.integer, timeScaledAmount);
		else
			obj.addCargo(type.integer, cap);
	}
#section all
};