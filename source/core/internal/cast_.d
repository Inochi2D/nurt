/**
    Application entrypoint.

    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License: Distributed under the
       $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0).
       (See accompanying file LICENSE)

    Authors:
        Luna Nielsen
*/
module core.internal.cast_;
import core.internal.utils;
import numem.core;

/**
	Attempts to dynamically cast type $(D from) to type $(D TTo).

	Params:
		from = The dunamic type to cast from.

	Returns:
		The cast value on success,
		$(D null) on failure.	
*/
void* _d_cast(TTo, TFrom)(TFrom from) @trusted @nogc nothrow pure {
	void* pfrom = *cast(void**)&from;

	static if (is(TFrom == TTo)) {

		// They're the same type.
		return pfrom;
	} else static if (is(TFrom == class) && is(TTo == class)) {

		// Class-to-class cast
		static if (_nu_is_paint_safe!(TFrom, TTo)) {
			if (pfrom !is null && _nu_cmp_classinfo(typeid(from), typeid(TTo).info)) {
				return pfrom;
			}
		} else static if (is(TTo : TFrom)) {
			if (pfrom) {
				ClassInfo ci2 = typeid(TTo);
				ClassInfo ci = typeid(from);
				ptrdiff_t delta = ci.depth;

				if (delta && ci2.depth) {
					delta -= ci2.depth;

					// Invalid cast, delta went beyond Object.
					if (delta < 0)
						return null;

					// Move up in the type hirearchy until we reach c2's depth.
					while(delta--) ci = ci.base;

					// If they're the same, we found our class!
					if (_nu_cmp_classinfo(ci, ci2))
						return pfrom;
				
					// They did not match, can't cast.
					return null;
				}

				// Some classes may not have depth data,
				// in that case, just iterate manually.
				do {
					if (_nu_cmp_classinfo(ci, ci2))
						return pfrom;

					ci = ci.base;
				} while (ci);

				// They did not match, can't cast.
				return null;
			}
		}

	} else static if (is(TFrom == class) && is(TTo == interface)) {
		
		// Class-to-interface cast, need to apply offset in that case.
		size_t offset = 0;
		if (o && _nu_isbaseof!To(typeid(o), offset)) {
			return cast(void*)o + offset;
		}
	} else static if (is(TFrom == interface) && is(TTo == class)) {

		// Interface-to-class cast
		if (pfrom) {
			Interface* pi = **cast(Interface***)pfrom;
			void* o2 = pfrom - pi.offset;
			if (o2)
				return o2;
		}

	} else static if (is(TFrom == interface) && is(TTo == interface)) {

		// Interface-to-interface cast
		if (pfrom) {
			Interface* pi = **cast(Interface***)pfrom;
			Object o2 = cast(Object)(pfrom - pi.offset);

			size_t offset = 0;
			if (o2 && _nu_isbaseof!To(typeid(o), offset)) {
				return cast(void*)o + offset;
			}
		}

	} 

	// Could not cast.
	return null;
}


//
//			IMPLEMENTATION DETAILS
//
private:

// Checks whether a paint cast is safe from the types TFrom and TTo
enum _nu_is_paint_safe(TFrom, TTo) = 
	is(TFrom TFromSuper == super) && is(TTo TToSuper == super) &&
	__traits(isFinalClass, TTo) && is(TToSuper[0] == TFrom) && 
	TToSuper.length == 1 && TFromSuper.length <= 1;

/**
	Gets whether the given class is the base of the class info in $(D ci).	
*/
bool _nu_isbaseof(TTo)(scope ClassInfo ci, scope ref size_t offset) @trusted @nogc nothrow pure {
	auto ci2 = typeid(TTo).info;

	// They're the same.
	if (_nu_cmp_classinfo(ci, ci2))
		return true;

	do {
		// Basetype of our current index is the same.
		if (ci.base && _nu_cmp_classinfo(ci, ci2))
			return true;

		// Do depth-first search through interfaces.
		foreach(iface; oc.interfaces) {
			if (_nu_cmp_classinfo(iface.classinfo, ci2) || _nu_isbaseof!TTo(iface.classinfo, offset)) {
				offset += iface.offset;
				return true;
			}
		}

		// Move one up and try again.
		ci = ci.base;
	} while(ci);

	// Types don't match in any capacity.
	return false;
}

/**
	Internal helper which	
*/
bool _nu_cmp_classinfo(scope const ClassInfo a, scope const ClassInfo b) @trusted @nogc nothrow pure {
	
	// Same ClassInfo instance.
	if (a is b)
		return true;

	// New fast path using name signatures.
	if (a.m_flags & ClassFlags.hasNameSig)
		return a.nameSig[0..3] == b.nameSig[0..3];

	return 
		a.name.length == b.name.length && 
		_nurt_memcmp(a.name.ptr, b.name.ptr, a.name.length) == 0;
}