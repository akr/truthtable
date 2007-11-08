require 'test/unit'
require 'truthtable'

class TestTruthTable < Test::Unit::TestCase
  def test_tautology
    assert_equal("true", TruthTable.new {|v| true }.dnf)
    assert_equal("true", TruthTable.new {|v| true }.cnf)
    assert_equal("true", TruthTable.new {|v| true }.formula)
    assert_equal("!v[0] | v[0]", TruthTable.new {|v| v[0] | !v[0] }.dnf)
    assert_equal("true", TruthTable.new {|v| v[0] | !v[0] }.cnf)
    assert_equal("true", TruthTable.new {|v| v[0] | !v[0] }.formula)
  end

  def test_contradiction
    assert_equal("false", TruthTable.new {|v| false }.dnf)
    assert_equal("false", TruthTable.new {|v| false }.cnf)
    assert_equal("false", TruthTable.new {|v| false }.formula)
    assert_equal("false", TruthTable.new {|v| v[0] & !v[0] }.dnf)
    assert_equal("v[0] & !v[0]", TruthTable.new {|v| v[0] & !v[0] }.cnf)
    assert_equal("false", TruthTable.new {|v| v[0] & !v[0] }.formula)
  end
end
