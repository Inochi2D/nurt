module object;
import rt.cast_;
import rt.invariant_;
import rt.finalizer;
import rt.lifetime;
import rt.cmp;
import core.attribute;
import numem.lifetime;
import numem.core.traits;
import core.internal.hash;
import core.internal.array;

//
//          SETUP
//

version(GNU) {
    // Nothing needs to happen here, GDC just doesn't need to handle
    // argtypes.
} else version (X86_64) {

    version (DigitalMars) version = WithArgTypes;
    else version (Windows) { /* no need for Win64 ABI */ }
    else version = WithArgTypes;
} else version (AArch64) {
    
    // Apple uses a trivial varargs implementation
    version (OSX) {}
    else version (iOS) {}
    else version (TVOS) {}
    else version (WatchOS) {}
    else version = WithArgTypes;
}




//
//          BASE TYPES
//
alias size_t = typeof(void.sizeof);
alias ptrdiff_t = typeof(null - null);

/**
    Bottom type.
*/
alias noreturn = typeof(*null);

/**
    A string.
*/
alias string = immutable(char)[];
alias wstring = immutable(wchar)[]; /// ditto
alias dstring = immutable(dchar)[]; /// ditto

bool _xopEquals(const void*, const void*) @nogc nothrow {
    throw nogc_new!Error("TypeInfo.equals is not implemented.");
}

bool _xopCmp(const void*, const void*) @nogc nothrow {
    throw nogc_new!Error("TypeInfo.compare is not implemented.");
}








//
//              OBJECT
//

/**
    Base object type of all objects.
*/
class Object {
@nogc:
public:

    /**
        Compute hash function for Object.

        Returns:
            The hash for this object.
    */
    size_t toHash() @trusted nothrow {
        auto addr = cast(size_t) cast(void*) this;
        return addr ^ (addr >>> 4);
    }

    /**
        Compare against another object.

        Default implementation gets whether the address 
        of the object is lower or greater.

        Returns:
            A negative value if $(D other) is logically "lower" than this object,
            $(D 0) if they're the same, a positive value if $(D other) is
            logcally greater than this object.
    */
    int opCmp(Object other) nothrow const {
        auto selfAddr = cast(size_t) cast(void*) this;
        auto otherAddr = cast(size_t) cast(void*) other;

        return cast(int)(selfAddr - otherAddr);
    }

    /**
        Check equivalence againt another object

        Returns:
            $(D true) if this object is the same as $(D other),
            $(D false) otherwise.
    */
    bool opEquals(Object other) nothrow const {
        return this is other;
    }

    /**
        Gets a string representation of the type.

        Returns:
            A string representation of the object.
    */
    string toString() {
        return Object.stringof;
    }
}

/**
    Implementation for class opEquals override. Calls the class-defined methods after a null check.
    Please note this is not nogc right now, even if your implementation is, because of
    the typeinfo name string compare. This is because of dmd's dll implementation. However,
    it can infer to @safe if your class' opEquals is.
*/
bool opEquals(LHS, RHS)(LHS lhs, RHS rhs) @nogc if (is(LHS == class) && is(RHS == class)) {
    static if (__traits(compiles, lhs.opEquals(rhs)) && __traits(compiles, rhs.opEquals(lhs))) {
        // If aliased to the same object or both null => equal
        if (lhs is rhs) return true;

        // If either is null => non-equal
        if (lhs is null || rhs is null) return false;

        if (!lhs.opEquals(rhs)) return false;

        // If same exact type => one call to method opEquals
        if ((typeid(lhs) is typeid(rhs)) ||
            (!__ctfe && typeid(lhs).opEquals(typeid(rhs)))) {
            
            // NOTE:    CTFE doesn't like typeid much. 'is' works, but opEquals doesn't:
            //          https://issues.dlang.org/show_bug.cgi?id=7147
            //          But CTFE also guarantees that equal TypeInfos are
            //          always identical. So, no opEquals needed during CTFE.
            return true;
        }

        // General case => symmetric calls to method opEquals
        return rhs.opEquals(lhs);
    } else {

        // this is a compatibility hack for the old const cast behavior
        // if none of the new overloads compile, we'll go back plain Object,
        // including casting away const. It does this through the pointer
        // to bypass any opCast that may be present on the original class.
        return .opEquals!(Object, Object)(*cast(Object*) &lhs, *cast(Object*) &rhs);
    }
}









//
//              EXCEPTIONS
//

/**
    Backtrace information.
*/
interface TraceInfo {
@nogc:
    int opApply(scope int delegate(ref const(char[]))) const;
    int opApply(scope int delegate(ref size_t, ref const(char[]))) const;
    string toString() const;
}

/**
    Base class of throwable.
*/
class Throwable : Object {
@nogc:
private:
    Throwable nextInChain;
    uint refcount_;

public:
    ~this() { }

    this(string msg, Throwable nextInChain = null) pure nothrow {
        this.msg = msg;
        this.nextInChain = nextInChain;
        if (nextInChain && nextInChain.refcount_)
            ++nextInChain.refcount_;
    }

    this(string msg, string file, size_t line, Throwable nextInChain = null) pure nothrow {
        this(msg, nextInChain);
        this.file = file;
        this.line = line;
    }

    alias TraceDeallocator = void function(TraceInfo) nothrow;

    /**
        The message of the throwable.
    */
    string msg;

    /**
        The file that the throwable was thrown from.
    */
    string file;

    /**
        The line that the throwable was thrown from.
    */
    size_t line;

    /**
        Backtrace information.
    */
    TraceInfo info;

    /**
        The next throwable in the chain.
    */
    @safe
    @property inout(Throwable) next() inout return scope pure nothrow {
        return nextInChain;
    }

    @safe
    @property void next(Throwable tail) scope pure nothrow { /// ditto.
        nextInChain = tail;
    }

    /**
        Mutable reference count reference.

        Notes:
            Marked as $(D @system) to discourage casual use.
    */
    @system
    final ref refcount() return pure nothrow {
        return refcount_;
    }

    /**
        Gets the message of the exception.
    */
    @__future
    const(char)[] message() @safe const nothrow {
        return this.msg;
    }
}

/**
    An unrecoverable error
*/
class Error : Throwable {
@nogc nothrow: 
    this(string msg) { super(msg); }
}

/**
    An exception
*/
class Exception : Throwable {
@nogc:
public:
    this(string msg, Throwable nextInChain = null) pure nothrow {
        super(msg, nextInChain);
    }

    this(string msg, string file, size_t line, Throwable nextInChain = null) pure nothrow {
        super(msg, file, line, nextInChain);
    }
}












//
//              CLASS INFO
//

/**
    Information about an interface.

    When an object is accessed via an interface, an Interface* appears as
    the first entry in the vtable.
*/
struct Interface {
    TypeInfo_Class classinfo;
    void*[] vtbl;
    size_t offset;
}

/**
    Array of pairs giving the offset and type info
    for each member of an aggregate.
*/
struct OffsetTypeInfo {
    
    /**
        Offset of member from start of object
    */
    size_t offset;
    
    /**
        TypeInfo for this member
    */
    TypeInfo ti;
}

/**
    Class flags
*/
enum ClassFlags : ushort {
    isCOMclass = 0x1,
    noPointers = 0x2,
    hasOffTi = 0x4,
    hasCtor = 0x8,
    hasGetMembers = 0x10,
    hasTypeInfo = 0x20,
    isAbstract = 0x40,
    isCPPclass = 0x80,
    hasDtor = 0x100,
    hasNameSig = 0x200,
}

/**
    Struct flags
*/
enum StructFlags : uint {
    hasPointers = 0x1,
    isDynamicType = 0x2, // built at runtime, needs type info in xdtor
}

class TypeInfo {
@nogc nothrow:
public:

    /**
        Next type in the chain, if any.
    */
    const(TypeInfo) next() pure inout { return null; }

    /**
        Size of the type.
    */
    size_t size() @safe const pure { return 0; }
    const(void)[] initializer() @trusted const pure { return (cast(const(void)*) null)[0 .. typeof(null).sizeof]; }
    const(OffsetTypeInfo)[] offTi() @trusted const { return null; }
    @property uint flags() @safe pure const { return 0; }
    @property size_t talign() @trusted nothrow pure const { return size; }

    /**
        Run the destructor on the object and all its sub-objects
    */
    void destroy(void* p) @trusted const { }

    /**
        Run the postblit on the object and all its sub-objects
    */
    void postblit(void* p) @trusted const { }

    /**
        Compares 2 type infos.
    */
    bool equals(in void* p1, in void* p2) @trusted const {
        return p1 is p2; // TODO: Fix this.
    }

    override
    size_t toHash() @trusted const {
        return 0; // TODO: Fix this.
    }

    size_t getHash(scope const void* p) @trusted const {
        return 0;
    }

    override
    string toString() @safe const {
        return typeid(this).name;
    } 
}

/**
    Type information for classes.
*/
class TypeInfo_Class : TypeInfo {
@nogc:
public:

    /**
        Class static initializer.
    */
    ubyte[]      m_init;

    /**
        Name of class
    */
    string      name;

    /**
        Virtual function pointer table
    */
    void*[]     vtbl;

    /**
        Interfaces this class implements
    */
    Interface[] interfaces;     /// 
    
    /**
        Base class
    */
    TypeInfo_Class   base;

    /**
        The destructor
    */
    void* destructor;

    /**
        The class invariant
    */
    void function(Object) classInvariant;
    
    /**
        Class flags
    */
    ClassFlags m_flags;
    
    /**
        Inheritance distance from Object
    */
    ushort     depth;
    
    /**
        Deallocator
    */
    void*      deallocator;
    
    /**
        Offset type info
    */
    OffsetTypeInfo[] m_offTi;
    
    /**
        Default Constructor
    */
    void function(Object) defaultConstructor;
    
    /**
        Data for precise GC
    */
    immutable(void)* m_RTInfo;
    
    /**
        Unique signature for `name`
    */
    uint[4] nameSig;

    final
    bool isBaseOf(scope const TypeInfo_Class child) @trusted const pure  {
        if (m_init.length) {
            for (auto ti = cast() child; ti !is null; ti = ti.base) {
                if (ti is this)
                    return true;
            }
            return false;
        } else {

            return child !is null && _d_isbaseof(cast() child, this);
        }
    }


    override
    @property size_t size() pure const { return Object.sizeof; }

    override
    string toString() const pure { return name; }

    override 
    @property const(OffsetTypeInfo)[] offTi() pure const { return m_offTi; }

    override
    size_t getHash(scope const void* p) @trusted const {
        auto o = *cast(Object*) p;
        return o ? o.toHash() : 0;
    }

    override
    bool equals(in void* p1, in void* p2) @trusted nothrow const {
        Object o1 = *cast(Object*) p1;
        Object o2 = *cast(Object*) p2;

        return (o1 is o2) || (o1 && o1.opEquals(o2));
    }

    override
    const(void)[] initializer() @safe nothrow const pure {
        return m_init;
    }
}
alias ClassInfo = TypeInfo_Class;

class TypeInfo_Interface : TypeInfo {
@nogc nothrow:
public:
    TypeInfo_Class info;

    override
    bool equals(in void* p1, in void* p2) @trusted const {
        Interface* pi = **cast(Interface***)*cast(void**) p1;
        Object o1 = cast(Object)(*cast(void**) p1 - pi.offset);
        pi = **cast(Interface***)*cast(void**) p2;
        Object o2 = cast(Object)(*cast(void**) p2 - pi.offset);

        return o1 == o2 || (o1 && o1.opCmp(o2) == 0);
    }

    override
    size_t getHash(scope const void* p) @trusted const {
        if (!*cast(void**) p) {
            return 0;
        }
        Interface* pi = **cast(Interface***)*cast(void**) p;
        Object o = cast(Object)(*cast(void**) p - pi.offset);
        assert(o);
        return o.toHash();
    }

    override
    const(void)[] initializer() @trusted const {
        return (cast(void*) null)[0 .. Object.sizeof];
    }

    override
    @property size_t size() @safe pure const {
        return Object.sizeof;
    }
}

/// NOT SUPPORTED.
class TypeInfo_AssociativeArray : TypeInfo { }


class TypeInfo_Pointer : TypeInfo {
@nogc nothrow:
public:
    TypeInfo m_next;

    override
    bool equals(in void* p1, in void* p2) @trusted const {
        return *cast(void**) p1 == *cast(void**) p2;
    }

    override
    size_t getHash(scope const void* p) @trusted const {
        size_t addr = cast(size_t)*cast(const void**) p;
        return addr ^ (addr >> 4);
    }

    override
    @property size_t size() @safe pure const {
        return (void*).sizeof;
    }

    override
    const(void)[] initializer() @trusted const {
        return (cast(void*) null)[0 .. (void*).sizeof];
    }

    override
    const(TypeInfo) next() @safe const {
        return m_next;
    }
}

class TypeInfo_Array : TypeInfo {
@nogc nothrow:
public:
    TypeInfo value;

    override
    string toString() @safe const {
        return value.toString();
    }

    override
    size_t size() @safe const {
        return (void[]).sizeof;
    }

    override
    const(TypeInfo) next() @safe const {
        return value;
    }

    override
    bool equals(in void* p1, in void* p2) @trusted const {
        void[] a1 = *cast(void[]*) p1;
        void[] a2 = *cast(void[]*) p2;
        if (a1.length != a2.length)
            return false;
        size_t sz = value.size;
        for (size_t i = 0; i < a1.length; i++) {
            if (!value.equals(a1.ptr + i * sz, a2.ptr + i * sz))
                return false;
        }
        return true;
    }

    override
    @property size_t talign() @safe pure const {
        return (void[]).alignof;
    }

    override
    const(void)[] initializer() @trusted const {
        return (cast(void*) null)[0 .. (void[]).sizeof];
    }
}

class TypeInfo_Tuple : TypeInfo {
@nogc nothrow:
public:

    TypeInfo[] elements;
}

class TypeInfo_StaticArray : TypeInfo {
@nogc nothrow:
public:
    TypeInfo value;
    size_t len;

    override
    size_t size() @safe const {
        return value.size * len;
    }

    override
    const(TypeInfo) next() @safe const {
        return value;
    }

    override
    bool equals(in void* p1, in void* p2) @trusted const {
        size_t sz = value.size;

        for (size_t u = 0; u < len; u++) {
            if (!value.equals(p1 + u * sz, p2 + u * sz)) {
                return false;
            }
        }
        return true;
    }

    override
    @property size_t talign() @safe pure const {
        return value.talign;
    }

}

class TypeInfo_Enum : TypeInfo {
@nogc nothrow:
public:
    TypeInfo base;
    string name;
    void[] m_init;

    override
    size_t size() @safe const {
        return base.size;
    }

    override
    const(TypeInfo) next() @trusted const {
        return base.next;
    }

    override
    bool equals(in void* p1, in void* p2) @safe const {
        return base.equals(p1, p2);
    }

    override
    @property size_t talign() @safe const {
        return base.talign;
    }

    override
    void destroy(void* p) @safe const {
        return base.destroy(p);
    }

    override
    void postblit(void* p) @safe const {
        return base.postblit(p);
    }

    override
    const(void)[] initializer() @safe const {
        return m_init.length ? m_init : base.initializer();
    }
}

/// typeof(null)
class TypeInfo_n : TypeInfo {
@nogc nothrow:
public:
    override
    string toString() @safe const pure {
        return "typeof(null)";
    }

    override
    size_t getHash(scope const void*) @safe const pure {
        return 0;
    }

    override
    bool equals(in void*, in void*) @safe const pure {
        return true;
    }

    override
    @property size_t size() @safe const pure {
        return typeof(null).sizeof;
    }

    override
    const(void)[] initializer() @trusted const pure {
        return (cast(void*) null)[0 .. size_t.sizeof];
    }
}

class TypeInfo_Const : TypeInfo {
@nogc nothrow:
public:
    TypeInfo base;

    override
    size_t getHash(scope const(void*) p) @trusted const nothrow {
        return base.getHash(p);
    }

    override
    size_t size() const {
        return base.size;
    }

    override
    const(TypeInfo) next() const {
        return base.next;
    }

    override
    const(void)[] initializer() nothrow pure const {
        return base.initializer();
    }

    override
    @property size_t talign() nothrow pure const {
        return base.talign;
    }

    override
    bool equals(in void* p1, in void* p2) const {
        return base.equals(p1, p2);
    }
}
class TypeInfo_Invariant : TypeInfo {
@nogc nothrow:
public:
    TypeInfo base;

    override
    size_t getHash(scope const(void*) p) @trusted const nothrow {
        return base.getHash(p);
    }

    override
    size_t size() const {
        return base.size;
    }

    override
    const(TypeInfo) next() const {
        return base;
    }
}

class TypeInfo_Shared : TypeInfo {
@nogc nothrow:
public:
    TypeInfo base;

    override
    size_t getHash(scope const(void*) p) @trusted const nothrow {
        return base.getHash(p);
    }

    override
    size_t size() const {
        return base.size;
    }

    override
    const(TypeInfo) next() const {
        return base;
    }
}

class TypeInfo_Inout : TypeInfo {
@nogc nothrow:
public:
    TypeInfo base;

    override
    size_t getHash(scope const(void*) p) @trusted const nothrow {
        return base.getHash(p);
    }

    override
    size_t size() const {
        return base.size;
    }

    override
    const(TypeInfo) next() const {
        return base;
    }
}

class TypeInfo_Struct : TypeInfo {
@nogc nothrow:
public:
    string name;
    void[] m_init;
    size_t  function(in void*) @safe pure           xtoHash;
    bool    function(in void*, in void*) @safe pure xopEquals;
    int     function(in void*, in void*) @safe pure xopCmp;
    string  function(in void*) @safe pure           xtoString;
    StructFlags m_flags;
    union {
        void function(void*) xdtor;
        void function(void*, const TypeInfo_Struct) xdtorti;
    }
    void function(void*) xpostblit;
    uint m_align;
    immutable(void)* m_RTInfo;
    version(WithArgTypes) {
        TypeInfo m_arg1;
        TypeInfo m_arg2;
    }

    override
    string toString() const {
        return name;
    }

    override
    size_t size() const {
        return m_init.length;
    }

    override
    @property uint flags() nothrow pure const @safe @nogc {
        return m_flags;
    }

    override
    size_t toHash() const {
        return hashOf(this.name);
    }

    override
    bool opEquals(Object o) const {
        if (this is o)
            return true;
        auto s = cast(const TypeInfo_Struct) o;
        return s && this.name == s.name;
    }

    override
    size_t getHash(scope const void* p) @trusted pure nothrow const {
        assert(p);
        if (xtoHash) {
            return (*xtoHash)(p);
        } else {
            return hashOf(p[0 .. initializer().length]);
        }
    }

    override
    bool equals(in void* p1, in void* p2) @trusted const {
        import core.stdc.string : memcmp;
        if (!p1 || !p2)
            return false;
        else if (xopEquals)
            return (*xopEquals)(p1, p2);
        else if (p1 == p2)
            return true;
        else // BUG: relies on the GC not moving objects
            return memcmp(p1, p2, m_init.length) == 0;
    }

    override
    @property size_t talign() nothrow pure const {
        return m_align;
    }

    final
    override void destroy(void* p) @trusted const {
        if (xdtor) {
            if (m_flags & StructFlags.isDynamicType)
                (*xdtorti)(p, this);
            else
                (*xdtor)(p);
        }
    }

    override
    void postblit(void* p) @trusted const {
        if (xpostblit)
            (*xpostblit)(p);
    }

    override
    const(void)[] initializer() nothrow pure const @safe {
        return m_init;
    }
}

// BASIC TYPES
import numem.core.meta : AliasSeq;
static foreach (type; AliasSeq!(bool, byte, char, dchar, double, float, int, long, short, ubyte, uint, ulong, ushort, void, wchar)) {
    mixin(q{
		class TypeInfo_}
            ~ type.mangleof ~ q{ : TypeInfo {
            override string toString() const pure nothrow @safe { return type.stringof; }
			override size_t size() const { return type.sizeof; }
            override @property size_t talign() const pure nothrow
            {
                return type.alignof;
            }

			override bool equals(in void* a, in void* b) @trusted const {
				static if(is(type == void))
					return false;
				else
				return (*(cast(type*) a) == (*(cast(type*) b)));
			}
            static if(!is(type == void))
            override size_t getHash(scope const void* p) @trusted const nothrow
            {
                return hashOf(*cast(const type *)p);
            }
			override const(void)[] initializer() pure nothrow @trusted const
			{
				static if(__traits(isZeroInit, type))
					return (cast(void*)null)[0 .. type.sizeof];
				else
				{
					static immutable type[1] c;
					return c;
				}
			}
		}
		class TypeInfo_A}
            ~ type.mangleof ~ q{ : TypeInfo_Array {
            override string toString() const { return (type[]).stringof; }
			override @property const(TypeInfo) next() @trusted const { return cast(inout)typeid(type); }
            override size_t getHash(scope const void* p) @trusted const nothrow
            {
                return hashOf(*cast(const type[]*) p);
            }

			override bool equals(in void* av, in void* bv) @trusted const {
				type[] a = *(cast(type[]*) av);
				type[] b = *(cast(type[]*) bv);

				static if(is(type == void))
					return false;
				else {
					foreach(idx, item; a)
						if(item != b[idx])
							return false;
					return true;
				}
			}
		}
	});
}