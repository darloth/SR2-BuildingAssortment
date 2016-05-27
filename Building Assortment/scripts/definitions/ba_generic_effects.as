import buildings;
from buildings import IBuildingHook;
import resources;
import util.formatting;
import systems;
import saving;
import statuses;
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

//ProtectSystem()
// Protect the system from losing loyalty, and also interdicts any unoccupied planets from being colonized except by the owner.
class ProtectSystemAndInterdict : GenericEffect {
	Document doc("Protect owned planets in the system from losing loyalty in any way, and also prevents unowned planets from being colonized by others.");
	Argument timer(AT_Decimal, "0", doc="Delay timer before the effect starts working after being enabled.");

	bool get_hasEffect() const override {
		return true;
	}

	string formatEffect(Object& obj, array<const IResourceHook@>& hooks) const override {
		return locale::PSIONIC_REAGENTS_EFFECT;
	}

#section server
	void enable(Object& obj, any@ data) const override {
		double timer = 0.0;
		data.store(timer);
	}

	void disable(Object& obj, any@ data) const override {
		if(obj.region !is null)
		{
			obj.region.ProtectedMask &= ~obj.owner.mask;
			obj.region.removeRegionStatus(null, getStatusID("Interdicted"));
		}
	}

	void tick(Object& obj, any@ data, double tick) const override {
		double timer = 0.0;
		data.retrieve(timer);

		if(timer >= arguments[0].decimal) {
			if(obj.region !is null)
			{
				obj.region.ProtectedMask |= obj.owner.mask;
				obj.region.addRegionStatus(null, getStatusID("Interdicted"));
			}
		}
		else {
			timer += tick;
			data.store(timer);
		}
	}

	void save(any@ data, SaveFile& file) const override {
		double timer = 0.0;
		data.retrieve(timer);
		file << timer;
	}

	void load(any@ data, SaveFile& file) const override {
		double timer = 0.0;
		file >> timer;
		data.store(timer);
	}

	void ownerChange(Object& obj, any@ data, Empire@ prevOwner, Empire@ newOwner) const override {
		if(obj.region !is null) {
			double timer = 0.0;
			data.retrieve(timer);

			if(timer >= arguments[0].decimal) {
				obj.region.ProtectedMask &= ~prevOwner.mask;
				obj.region.ProtectedMask |= newOwner.mask;
			}
		}
	}

	void regionChange(Object& obj, any@ data, Region@ fromRegion, Region@ toRegion) const override {
		double timer = 0.0;
		data.retrieve(timer);

		if(timer >= arguments[0].decimal) {
			if(fromRegion !is null)
				fromRegion.ProtectedMask &= ~obj.owner.mask;
			if(toRegion !is null)
				toRegion.ProtectedMask |= obj.owner.mask;
		}
	}
#section all
};
