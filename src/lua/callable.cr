module LuaCallable
  struct LuaConvert(T)
    def self.convert(val : Lua::Type) : T
        {% for i in (1..1) %}
            {% type = @type.type_vars[0].resolve %}
            {% if type <= Nil %}
            return nil
            {% elsif type <= String %}
            return val.as(String)
            {% elsif type <= Bool %}
            return val.as(Bool)
            {% elsif type <= Int8 %}
            return val.as(Float64).to_i8
            {% elsif type <= Int16 %}
            return val.as(Float64).to_i16
            {% elsif type <= Int32 %}
            return val.as(Float64).to_i32
            {% elsif type <= Int64 %}
            return val.as(Float64).to_i64
            {% elsif type <= UInt8 %}
            return val.as(Float64).to_u8
            {% elsif type <= UInt16 %}
            return val.as(Float64).to_u16
            {% elsif type <= UInt32 %}
            return val.as(Float64).to_u32
            {% elsif type <= UInt64 %}
            return val.as(Float64).to_u64
            {% elsif type <= Float32 %}
            return val.as(Float64).to_f32
            {% elsif type <= Float64 %}
            return val.as(Float64)
            {% elsif type <= LuaCallable %}
            return val.as(Lua::Callable).to_callable.as(T)
            {% else %}
            return val.as(T)
            {% end %}
        {% end %}
    end
  end

  macro included    
    macro finished
        {% verbatim do %}
        {% for m in @type.methods %}
        def {{m.name}}(state : LibLua::State) : Int32
            stack = Lua::Stack.new(state, :all)
            {% reverseArgs = [] of Arg %}
            {% for a, index in m.args %}
            {% reverseArgs = [a] + reverseArgs %}
            {% end %}
            {% for a, index in reverseArgs %}
                {% if a.restriction.is_a?(Nop) %}  
                    {{a.name}} = stack[-{{index+1}}]                
                {% else %}
                    {{a.name}} = LuaConvert({{a.restriction}}).convert(stack[-{{index+1}}])
                {% end %}  
            {% end %}
            {% if m.args.empty? %}           
            res = self.{{m.name}}()
            {% else %}
            res = self.{{m.name}}({{(m.args.map &.name).join(",").id}})
            {% end %}
            stack << res            
            return 1
        end 
        {% end %}
        def _call(key)
            {% for m in @type.methods %}
                if key == "{{m.name}}"
                    return ->self.{{m.name}}(LibLua::State)
                end
            {% end %}   
        end
        {% end %}
    end
  end

  def _index(key : String)        
    {% for m in @type.instance_vars %}       
        if key == "{{m.name}}"
            return self.{{m.name}}
        end
    {% end %}
    return self._call(key)
  end

  def _newindex(key, val)
    {% for m in @type.instance_vars %}
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

  def self.__call(state : LibLua::State) : Int32
    data = LibLua.topointer(state, Lua::REGISTRYINDEX-1); #lua_upvalueindex(1)
    ptr = LibLua.topointer(state, Lua::REGISTRYINDEX-2); #lua_upvalueindex(2)
    proc = Proc(LibLua::State,Int32).new(ptr, data)
    return proc.call(state)
  end
end
