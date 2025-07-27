module rt.deh.deh;
import core.internal.exception : _d_throw_exception;

    
export extern(C):

void _d_throwdwarf(Throwable o) {
    _d_throw_exception(o);
}