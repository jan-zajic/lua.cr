module Lua
    class Callable < Reference
        def to_callable
            data = @ref.as(LuaCallable*)
            return data.value
        end
    end
end