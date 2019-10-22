require "../../spec_helper"

module Lua::StackMixin
  describe Util do
    describe "#version" do
      it "returns the lua version number stored in the lua core" do
        v = Stack.new.version
        v.should be_a Float64
        (v > 0).should be_true
      end
    end

    describe "#set_global" do
      it "returns the string concated from global strings" do
        s = Stack.new
        s.set_global("h", "Hello")
        s.set_global("w", "world")
        r = s.run "return h .. ' ' .. w"
        r.to_s.should eq "Hello world"
      end

      it "returns the string concated from global Hash" do
        s = Stack.new
        obj = {"h" => "Hello", "w" => "world"}
        s.set_global("o", obj)
        r = s.run "return o['h'] .. ' ' .. o['w']"
        r.to_s.should eq "Hello world"
      end

      it "cannot modify passed global Hash" do
        s = Stack.new
        obj = {"h" => "Hello", "w" => "Crystal"}
        s.set_global("o", obj)
        s.run "o['w']='Lua'"
        obj["w"].should eq "Crystal"
      end

      it "read modified global string" do
        s = Stack.new
        g = "Crystal"
        s.set_global("g", g)
        r = s.run "l = g; g = 'Lua';return l"
        g.should eq "Crystal"
        r.to_s.should eq "Crystal"
        g = s.get_global("g")
        g.should eq "Lua"
      end

      it "read modified global hash" do
        s = Stack.new
        obj = {"h" => "Hello", "w" => "Crystal"}
        s.set_global("o", obj)
        s.run "o['w']='Lua'"
        obj["w"].should eq "Crystal"
        obj = s.get_global("o").as(Table).to_h
        obj["w"].should eq "Lua"
      end

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
