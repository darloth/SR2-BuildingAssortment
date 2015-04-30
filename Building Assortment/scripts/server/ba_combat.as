import statuses;
import combat;
import generic_effects;
import components.Statuses;

// Currently doesn't work because timed effects don't work. Yet.
void SpawnMicroBlackHole(Event& evt, double Amount, double Radius, double BaselineSize, double MinRatio, double MaxRatio, double DamageType) {
	Object@ targ = evt.target !is null ? evt.target : evt.obj;
	vec3d center = targ.position + evt.impact.normalize(targ.radius);
	playParticleSystem("MicroBlackHole", center, quaterniond(), Radius / 6, targ.visibleMask);
	
    TimedEffect timed(ET_SizeScaledAreaDamage, 3.4);
	timed.effect.value0 = Amount;
	timed.effect.value1 = Radius;
	timed.effect.value2 = BaselineSize;
	timed.effect.value3 = MinRatio;
	timed.effect.value4 = MaxRatio;
	timed.effect.value5 = DamageType;
	
	targ.addTimedEffect(timed);
}

// Copied and modified from ABEM with permission.
void SizeScaledDamage(Event& evt, double Amount, double BaselineSize, double MinRatio, double MaxRatio, double DamageType) {
	DamageEvent dmg;
	dmg.damage = Amount * double(evt.efficiency) * double(evt.partiality);
	dmg.partiality = evt.partiality;
	dmg.impact = evt.impact;
	int dmgType = getDamageType(DamageType);

	@dmg.obj = evt.obj;
	@dmg.target = evt.target;
	dmg.source_index = evt.source_index;
	dmg.flags |= dmgType | ReachedInternals;
	dmg.flags |= DF_IgnoreDR;

	if(evt.obj !is null) { // This particular bit of code is probably unneeded, but better safe than sorry.
		// This whole section is just copy-pasted with renamed variables from RelativeSizeEnergyCost, the AbilityHook.
		double theirScale = sqr(evt.target.radius);
		if(evt.target.isShip)
			theirScale = cast<Ship>(evt.target).blueprint.design.size;

		double ratio = theirScale / BaselineSize;
		dmg.damage *= clamp(ratio, MinRatio, MaxRatio);
	}
	
	evt.target.damage(dmg, -1.0, evt.direction);
}

void SizeScaledAreaDamage(Event& evt, double Amount, double Radius, double BaselineSize, double MinRatio, double MaxRatio, double DamageType) {
	//print("Triggered effect");
	Object@ targ = evt.target !is null ? evt.target : evt.obj;
	vec3d center = targ.position + evt.impact.normalize(targ.radius);
	
	playParticleSystem("MicroBlackHole", center, quaterniond(), Radius / 12, targ.visibleMask);
	
	array<Object@>@ objs = findInBox(center - vec3d(Radius), center + vec3d(Radius), evt.obj.owner.hostileMask);
	

	uint hits = 4;
	double maxDSq = Radius * Radius;
	
	for(uint i = 0, cnt = objs.length; i < cnt; ++i) {
		Object@ target = objs[i];
		vec3d off = target.position - center;
		vec3d revOff = center - target.position;
		double dist = off.length - target.radius;
		if(dist > Radius)
			continue;
		
		double deal = Amount;
		if(dist > 0.0)
			deal *= 1.0 - (dist / (Radius * 2)); // still half damage at full radius, then nothing - no smooth falloff.
		
		//Suck the boat towards us!
		if(target.hasMover) {
			double amplitude = deal * 1.0 / (target.radius * (target.radius * 0.2));
			target.impulse(revOff.normalize(min(amplitude,8.0)));
			target.rotate(quaterniond_fromAxisAngle(off.cross(off.cross(target.rotation * vec3d_front())).normalize(), (randomi(0,1) == 0 ? 1.0 : -1.0) * atan(amplitude * 0.2) * 2.0));
		}
		
		DamageEvent dmg;
		@dmg.obj = evt.obj;
		@dmg.target = target;
		dmg.source_index = evt.source_index;
		int dmgType = getDamageType(DamageType);
		dmg.flags |= dmgType;
		dmg.flags |= DF_IgnoreDR;
		dmg.impact = off.normalized(target.radius);
		dmg.spillable = false;
		
		double theirScale = sqr(evt.target.radius);
		if(evt.target.isShip)
			theirScale = cast<Ship>(evt.target).blueprint.design.size;

		double ratio = theirScale / BaselineSize;
		
		
		vec2d dir = vec2d(off.x, off.z).normalized();

		for(uint n = 0; n < hits; ++n) {
			dmg.partiality = evt.partiality / double(hits);
			dmg.damage = deal * double(evt.efficiency) * double(dmg.partiality);
			dmg.damage *= clamp(ratio, MinRatio, MaxRatio);
			//print("Damage: " + dmg.damage + " Ratio: " + ratio); 

			target.damage(dmg, -1.0, dir);
		}
	}
}

int getDamageType(double type) {
	int iType = int(type);
	switch(iType) {
		case 1: 
			return DT_Projectile;
		case 2: 
			return DT_Energy;
		case 3:
			return DT_Explosive;
		default: return DT_Generic;
	}
	return DT_Generic;
}