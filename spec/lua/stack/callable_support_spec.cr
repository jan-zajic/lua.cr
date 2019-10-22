require "../../spec_helper"

module Lua::StackMixin
  describe ClassSupport do
    describe "#pushobject" do
      it "test lua callable instance variables" do
        s = Stack.new
        obj = CallableClass.new
        s.set_global("o", obj)
        res = s.run! %q{
          c = o.w
          o.w = "Lua"
          return c
        }
        res.should eq "Crystal"
        obj.w.should eq "Lua"
      end

      it "test lua callable instance methods" do
        s = Stack.new
        obj = CallableClass.new
        s.set_global("o", obj)
        res = s.run! %q{
          return o.simple_function()
        }
        res.should eq "Hello from CallableClass"
        res = s.run! %q{
          return o.arg_function("Dogs", 4)
        }
        res.should eq "4 Dogs"
      end

      it "test lua callable instance method with callable arg" do
        s = Stack.new
        obj1 = CallableClass.new
        obj1.w = "First"
        obj2 = CallableClass.new
        obj2.w = "Second"
        s.set_global("o1", obj1)
        s.set_global("o2", obj2)
        res = s.run! %q{
          return o1.join_other(o2)
        }
        res.should eq "Second after First"
      end

      it "create new callable instance from Lua" do
        s = Stack.new
        s.set_global("m", CallableClass)
        res = s.run! %q{
          n = m.new()
          n.w = "Lua"
          return n
        }
        res.should be_a(Lua::Callable)
        cc = res.as(Lua::Callable)
        cc.crystal_type_name.should eq CallableClass.name
        c = cc.to_crystal
        c.should be_a(CallableClass)
        c.w.should eq "Lua"
      end
    end
  end

  class CallableClass
    include LuaCallable
    property w : String = "Crystal"

    def simple_function : String
      return "Hello from CallableClass"
    end

    def arg_function(kind, number : Int8) : String
      return "#{number} #{kind}"
    end

    def join_other(other : CallableClass) : String
      return "#{other.w} after #{self.w}"
    end
  end
end
