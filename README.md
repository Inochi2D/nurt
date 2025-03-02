# NuRT

A minimal D runtime using numem, built around using numem and nulib for memory managment. 
If you need higher level constructs, see [nulib](https://github.com/Inochi2D/nulib)

Having a smaller custom runtime serves the Inochi2D project by being more portable,
and additionally making it easier to link to the Inochi2D SDK.

NuRT has no garbage collector, and never will have one. Numem's lifetime capabilities
are automatically imported; additionally you *may* use `core.attribute` from druntime;
as the dub package prevents it from linking in. Any usage of druntime which generates 
code however, is not supported.

## Known issues
 * Win32 (i386/x86) is known to crash on application exit, root cause unknown as of current.
 * Exceptions have not been implemented yet, application will immediately crash on exception or assert.
 * Some C runtime linker flags may cause `_D_main` being called multiple times.