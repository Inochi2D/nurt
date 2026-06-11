/**
	Builtin SIMD intrinsics
	
	Source: $(DRUNTIMESRC core/_simd.d)
	
	Copyright: Copyright Digital Mars 2012-2020
	License:   $(HTTP www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
	Source:    $(DRUNTIMESRC core/_simd.d)
	Authors:
		$(HTTP digitalmars.com, Walter Bright),
		Luna Nielsen
*/
module core.simd;

pure:
nothrow:
@safe:
@nogc:

/*******************************
 * Create a vector type.
 *
 * Parameters:
 *      T = one of double[2], float[4], void[16], byte[16], ubyte[16],
 *      short[8], ushort[8], int[4], uint[4], long[2], ulong[2].
 *      For 256 bit vectors,
 *      one of double[4], float[8], void[32], byte[32], ubyte[32],
 *      short[16], ushort[16], int[8], uint[8], long[4], ulong[4]
 */

template Vector(T)
{
    /* __vector is compiler magic, hide it behind a template.
     * The compiler will reject T's that don't work.
     */
    alias __vector(T) Vector;
}
/* Handy aliases
 */
version (LDC)
{
static if (is(Vector!(void[4])))    alias Vector!(void[4])    void4;        ///
static if (is(Vector!(byte[4])))    alias Vector!(byte[4])    byte4;        ///
static if (is(Vector!(ubyte[4])))   alias Vector!(ubyte[4])   ubyte4;       ///
static if (is(Vector!(short[2])))   alias Vector!(short[2])   short2;       ///
static if (is(Vector!(ushort[2])))  alias Vector!(ushort[2])  ushort2;      ///
}
static if (is(Vector!(void[8])))    alias Vector!(void[8])    void8;        ///
static if (is(Vector!(double[1])))  alias Vector!(double[1])  double1;      ///
static if (is(Vector!(float[2])))   alias Vector!(float[2])   float2;       ///
static if (is(Vector!(byte[8])))    alias Vector!(byte[8])    byte8;        ///
static if (is(Vector!(ubyte[8])))   alias Vector!(ubyte[8])   ubyte8;       ///
static if (is(Vector!(short[4])))   alias Vector!(short[4])   short4;       ///
static if (is(Vector!(ushort[4])))  alias Vector!(ushort[4])  ushort4;      ///
static if (is(Vector!(int[2])))     alias Vector!(int[2])     int2;         ///
static if (is(Vector!(uint[2])))    alias Vector!(uint[2])    uint2;        ///
static if (is(Vector!(long[1])))    alias Vector!(long[1])    long1;        ///
static if (is(Vector!(ulong[1])))   alias Vector!(ulong[1])   ulong1;       ///

static if (is(Vector!(void[16])))   alias Vector!(void[16])   void16;       ///
static if (is(Vector!(double[2])))  alias Vector!(double[2])  double2;      ///
static if (is(Vector!(float[4])))   alias Vector!(float[4])   float4;       ///
static if (is(Vector!(byte[16])))   alias Vector!(byte[16])   byte16;       ///
static if (is(Vector!(ubyte[16])))  alias Vector!(ubyte[16])  ubyte16;      ///
static if (is(Vector!(short[8])))   alias Vector!(short[8])   short8;       ///
static if (is(Vector!(ushort[8])))  alias Vector!(ushort[8])  ushort8;      ///
static if (is(Vector!(int[4])))     alias Vector!(int[4])     int4;         ///
static if (is(Vector!(uint[4])))    alias Vector!(uint[4])    uint4;        ///
static if (is(Vector!(long[2])))    alias Vector!(long[2])    long2;        ///
static if (is(Vector!(ulong[2])))   alias Vector!(ulong[2])   ulong2;       ///

static if (is(Vector!(void[32])))   alias Vector!(void[32])   void32;       ///
static if (is(Vector!(double[4])))  alias Vector!(double[4])  double4;      ///
static if (is(Vector!(float[8])))   alias Vector!(float[8])   float8;       ///
static if (is(Vector!(byte[32])))   alias Vector!(byte[32])   byte32;       ///
static if (is(Vector!(ubyte[32])))  alias Vector!(ubyte[32])  ubyte32;      ///
static if (is(Vector!(short[16])))  alias Vector!(short[16])  short16;      ///
static if (is(Vector!(ushort[16]))) alias Vector!(ushort[16]) ushort16;     ///
static if (is(Vector!(int[8])))     alias Vector!(int[8])     int8;         ///
static if (is(Vector!(uint[8])))    alias Vector!(uint[8])    uint8;        ///
static if (is(Vector!(long[4])))    alias Vector!(long[4])    long4;        ///
static if (is(Vector!(ulong[4])))   alias Vector!(ulong[4])   ulong4;       ///

static if (is(Vector!(void[64])))   alias Vector!(void[64])   void64;       ///
static if (is(Vector!(double[8])))  alias Vector!(double[8])  double8;      ///
static if (is(Vector!(float[16])))  alias Vector!(float[16])  float16;      ///
static if (is(Vector!(byte[64])))   alias Vector!(byte[64])   byte64;       ///
static if (is(Vector!(ubyte[64])))  alias Vector!(ubyte[64])  ubyte64;      ///
static if (is(Vector!(short[32])))  alias Vector!(short[32])  short32;      ///
static if (is(Vector!(ushort[32]))) alias Vector!(ushort[32]) ushort32;     ///
static if (is(Vector!(int[16])))    alias Vector!(int[16])    int16;        ///
static if (is(Vector!(uint[16])))   alias Vector!(uint[16])   uint16;       ///
static if (is(Vector!(long[8])))    alias Vector!(long[8])    long8;        ///
static if (is(Vector!(ulong[8])))   alias Vector!(ulong[8])   ulong8;       ///