/**
    This module contains all functions related to an object's lifetime:
    allocation, resizing, deallocation, and finalization.

    Copyright:
        Copyright © Digital Mars, 2000-2025.
    
    License: Distributed under the
       $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0).
       (See accompanying file LICENSE)

    Authors:
        Walter Bright, 
        Sean Kelly, 
        Steven Schveighoffer,
        Luna Nielsen
*/
module rt.lifetime;
import core.attribute;
import numem.core.hooks;

import numem.core.memory;
nothrow:

private
size_t structTypeInfoSize(const TypeInfo ti) @trusted pure {
    if (ti && typeid(ti) is typeid(TypeInfo_Struct)) {
        auto sti = cast(TypeInfo_Struct) cast(void*) ti;
        if (sti.xdtor)
            return size_t.sizeof;
    }
    return 0;
}

// for closures
extern(C)
void* _d_allocmemory(size_t sz) {
    return nu_malloc(sz);
}

///For POD structures
extern(C)
void* _d_allocmemoryT(TypeInfo ti) {
    return nu_malloc(ti.size);
}

extern(C)
Object _d_allocclass(TypeInfo_Class ti) {
    auto ptr = nu_malloc(ti.m_init.length);
    nu_memcpy(ptr, ti.m_init.ptr, ti.m_init.length);
    return cast(Object) ptr;
}

extern(C)
Object _d_newclass(const(ClassInfo) ci) @weak {
    void* p;
    auto init = ci.initializer;

    // initialize it
    p = nu_malloc(init.length);
    p[0 .. init.length] = cast(void[]) init[];
    return cast(Object) p;
}

extern (C)
void* _d_newitemU(scope const TypeInfo _ti) @trusted pure {
    auto ti = cast() _ti;
    immutable tiSize = structTypeInfoSize(ti);
    immutable itemSize = ti.size;
    immutable size = itemSize + tiSize;
    auto p = nu_malloc(size);

    return p;
}

static if(__VERSION__ < 2105) {
    extern(C)
    void* _d_newitemT(in TypeInfo _ti) @trusted pure {
        auto p = _d_newitemU(_ti);
        nu_memset(p, 0, _ti.size);
        return cast(void*) p;
    }
} else {
    T* _d_newitemT(T)() @trusted pure {
        TypeInfo _ti = typeid(T);
        auto p = _d_newitemU(_ti);
        nu_memset(p, 0, _ti.size);
        return cast(T*) p;
    }
}

version (LDC) 
extern(C)
void _d_array_slice_copy(void* dst, size_t dstlen, void* src, size_t srclen, size_t elemsz) @trusted nothrow {
    import ldc.intrinsics : llvm_memcpy;
    llvm_memcpy!size_t(dst, src, dstlen * elemsz, 0);
}


bool __has_postblit(in TypeInfo ti) nothrow pure {
    return (&ti.postblit).funcptr !is &TypeInfo.postblit;
}

void __ti_postblit(T)(T[] target, const TypeInfo ti) {
    if (!__has_postblit(ti))
        return;

    if (auto tis = cast(TypeInfo_Struct)ti) {

        auto pb = tis.xpostblit;
        if (!pb)
            return;
        
        foreach(i; 0..target.length)
            pb(&target[i]);
    } else {
        foreach(i; 0..target.length)
            ti.postblit(&target[i]);
    }
}