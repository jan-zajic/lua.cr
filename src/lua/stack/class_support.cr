module Lua
  class Object
    macro methods
          {{ @type.methods.map &.name.stringify }}
        end
  end

  module StackMixin::ClassSupport
    def pushobject(a : LuaCallable)
      # pushes onto the stack a new full userdata with the block address, and returns this address
      p = LibLua.newuserdata(@state, sizeof(Pointer(UInt64))) # address of user data
      userData = p.as(Pointer(UInt64))
      userData.value = a.object_id
      LibLua.l_newmetatable(@state, a.class.name) # returns 1 if new
      # Set __index
      proc = ->LuaCallable.__index(LibLua::State)
      self << "__index"                    # push method name on stack
      LibLua.pushcclosure(@state, proc, 0) # pointer to function on stack
      LibLua.settable(@state, -3)
      # Set __gc
      proc = ->LuaCallable.__gc(LibLua::State)
      self << "__gc"                       # push method name on stack
      LibLua.pushcclosure(@state, proc, 0) # pointer to function on stack
      LibLua.settable(@state, -3)
      # set __newindex
      proc = ->LuaCallable.__newindex(LibLua::State)
      self << "__newindex"                 # push method name on stack
      LibLua.pushcclosure(@state, proc, 0) # pointer to function on stack
      LibLua.settable(@state, -3)
      # Set metatable
      LibLua.setmetatable(@state, -2)
    end
  end
end
