module LuaCallable
  def instance_vars_names
    # {{ @type.instance_vars.map &.name.stringify }}
  end

  def print_methods
    # puts {{@type.name}}
    {% for m in @type.methods %}
            {% puts m.name %}
        {% end %}
  end

  def _index(key)
    {% for m in @type.instance_vars %} #methods
            if key == "{{m.name}}"
                str = self.{{m.name}}
                return str
            end
        {% end %}
    return Nil
  end

  def _newindex(key, val)
    {% for m in @type.instance_vars %} #methods
            if key == "{{m.name}}"
                self.{{m.name}} = val.as({{m.type}})
            end
        {% end %}
  end

  def self.__index(state : LibLua::State) : Int32 # __index(t,k)
    stack = Lua::Stack.new(state, :all)
    key = String.new LibLua.tolstring(state, -1, nil)
    data = LibLua.touserdata(state, -2).as(LuaCallable*)
    pointer = data.value
    val = pointer._index(key)
    stack << val
    return 1
  end

  def self.__newindex(state : LibLua::State) : Int32
    stack = Lua::Stack.new(state, :all)
    data = LibLua.touserdata(state, -3).as(LuaCallable*)
    val = stack[-1]
    key = stack[-2]
    pointer = data.value
    pointer._newindex(key, val)
    return 0
  end

  def self.__gc(state : LibLua::State) : Int32
    data = LibLua.touserdata(state, -2).as(Pointer(Pointer(Void))).value
    STDERR.puts "GC pointer: #{data}"
    return 0
  end
end
