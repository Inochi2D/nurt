/**
    Implementation of casting support routines.

    Copyright:
        Copyright © Digital Mars, 2000-2025.
    
    License: Distributed under the
       $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0).
       (See accompanying file LICENSE)

    Authors:
        Walter Bright,
        Sean Kelly, 
        Luna Nielsen
*/
module rt.cast_;
@nogc nothrow:

/**
    Dynamic cast.
*/
extern(C)
void* _d_dynamic_cast(Object o, TypeInfo_Class c) {
    void* res = null;
    size_t offset = 0;
    if (o && _d_isbaseof2(typeid(o), c, offset)) {
        res = cast(void*) o + offset;
    }
    return res;
}

extern(C)
void* _d_class_cast(Object o, TypeInfo_Class c) {
    return _d_dynamic_cast(o, c);
}

/**
    Interface cast.
*/
extern(C)
void* _d_interface_cast(void* p, TypeInfo_Class c) {
    if (!p)
        return null;

    Interface* pi = **cast(Interface***) p;
    return _d_dynamic_cast(cast(Object)(p - pi.offset), c);
}

/**
    Gets whether oc is an instance of c.
*/
extern(C)
int _d_isbaseof(scope TypeInfo_Class oc, scope const TypeInfo_Class c) @safe pure {
    size_t offset = 0;
    return _d_isbaseof2(oc, c, offset);
}

/**
    Gets whether oc is an instance of c.
*/
extern(C)
int _d_isbaseof2(scope TypeInfo_Class oc, scope const TypeInfo_Class c, scope ref size_t offset) @safe pure {
    if (oc is c)
        return true;

    do {
        if (oc.base is c)
            return true;

        // Bugzilla 2013: Use depth-first search to calculate offset
        // from the derived (oc) to the base (c).
        foreach (iface; oc.interfaces) {
            if (iface.classinfo is c || _d_isbaseof2(iface.classinfo, c, offset)) {
                offset += iface.offset;
                return true;
            }
        }

        oc = oc.base;
    } while (oc);

    return false;
}
