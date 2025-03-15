/**
    Implementation of finalizers.

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
module rt.finalizer;
import numem.core.lifetime : destruct;

@nogc nothrow:

alias fp_t = extern(D) void function(Object) nothrow;

extern(C)
void rt_finalize2(void* p, bool det = true, bool resetMemory = true) nothrow {
    auto ppv = cast(void**) p;
    if (!p || !*ppv)
        return;

    auto pc = cast(TypeInfo_Class*)*ppv;
    if (det) {
        auto c = *pc;
        do {
            if (c.destructor)
                (cast(fp_t) c.destructor)(cast(Object) p); // call destructor
        }
        while ((c = c.base) !is null);
    }

    if (resetMemory) {
        auto w = (*pc).m_init;
        p[0 .. w.length] = w[];
    }

    *ppv = null; // zero vptr even if `resetMemory` is false
}

extern (C)
void _d_callfinalizer(void* p) {
    rt_finalize2(p);
}