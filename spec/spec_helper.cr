require "spec"
require "../src/lua"

def expect_error(klass : T.class, message = nil, file = __FILE__, line = __LINE__) forall T
  val = yield
  if val.class != klass
    fail "Expected #{klass}, got #<#{val.class}: #{val.to_s}>"
  else
    ex_to_s = val.to_s
    ex = val.as(Exception)
    case message
    when Regex
      unless (ex_to_s =~ message)
        backtrace = ex.backtrace.join('\n') { |f| "  # #{f}" }
        fail "Expected #{klass} with message matching #{message.inspect}, " \
             "got #<#{ex.class}: #{ex_to_s}> with backtrace:\n#{backtrace}", file, line
      end
    when String
      unless ex_to_s.includes?(message)
        backtrace = ex.backtrace.join('\n') { |f| "  # #{f}" }
        fail "Expected #{klass} with #{message.inspect}, got #<#{ex.class}: " \
             "#{ex_to_s}> with backtrace:\n#{backtrace}", file, line
      end
    end
  end
  return val.as(Exception)
end
