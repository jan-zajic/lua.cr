require "../../spec_helper"

module Lua::StackMixin
  describe ErrorHandling do
    it "can catch lua runtime error" do
      expect_error RuntimeError, "attempt to call a nil value (global 'raise')" do
        Lua.run "raise('Blah!')"
      end
    end

    it "can catch lua syntax error" do
      expect_error SyntaxError, %q[unexpected symbol near '"a"'] do
        Lua.run %q{
          "a" * 3
        }
      end
    end

    it "can catch lua stack overflow" do
      expect_error RuntimeError, "stack overflow" do
        Lua.run %q{
          function s()
            s()
          end
          s()
        }
      end
    end

    it "can catch lua file error" do
      tempfile = File.tempfile("foo")
      invalid_file = File.new tempfile.path
      tempfile.delete
      expect_error FileError, "cannot open #{invalid_file.path}" do
        Lua.load.run invalid_file
      end
    end

    it "can give you a lua error message" do
      stack = Stack.new
      expect_error RuntimeError, "attempt to perform arithmetic on a string value" do
        stack.run %q{
          s = "a" + 1
        }
      end
    end

    it "can give you a lua traceback" do
      stack = Stack.new
      expect_error RuntimeError, "attempt to perform arithmetic on a string value" do
        stack.run %q{
          s = function()
            return "a" + 1
          end

          print(s())
        }
      end.traceback.should eq <<-STACK
      stack traceback:
      \t[string "error handler"]:3: in metamethod '__add'
      \t[string "s = function()..."]:3: in function 's'
      \t[string "s = function()..."]:6: in main chunk
      STACK
    end

    it "throws RuntimeError on non-emtpy stack" do
      stack = Stack.new.tap &.<< 1
      sum = stack.run %q{
        return function (x, y)
          return x + y
        end
      }
      expect_error RuntimeError, "attempt to perform arithmetic on a string value (local 'x')" do
        sum.as(Lua::Function).call("a", 3)
      end
    end
  end
end
