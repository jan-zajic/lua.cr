module Lua
  class Callable < Reference
    def to_crystal
      data = @ref.as(LuaCallable*)
      return data.value
    end
  end
end
