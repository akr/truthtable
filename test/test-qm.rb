require 'test/unit'
require 'truthtable/qm'

class TestQM < Test::Unit::TestCase
  QM = TruthTable::QM

  def test_intern_tbl
    assert_raise(ArgumentError) { QM.intern_tbl({[0]=>0, []=>1}) }
    assert_raise(ArgumentError) { QM.intern_tbl({[:y]=>0}) }
    assert_raise(ArgumentError) { QM.intern_tbl({[0]=>:y}) }
    assert_raise(ArgumentError) { QM.intern_tbl({[0]=>0, [:x]=>1}) }
    assert_equal({[-1]=>0}, QM.intern_tbl({[0]=>0, [:x]=>0}))
    assert_equal({[0]=>0, [1]=>-1}, QM.intern_tbl({[0]=>0}))
  end

  def test_qm
    assert_equal([], QM.qm({}))
  end

  def test_qm_sample_1
    tbl = {
      [0,0,0,0]=>0,
      [0,0,0,1]=>0,
      [0,0,1,0]=>0,
      [0,0,1,1]=>0,
      [0,1,0,0]=>1,
      [0,1,0,1]=>0,
      [0,1,1,0]=>0,
      [0,1,1,1]=>0,
      [1,0,0,0]=>1,
      [1,0,0,1]=>:x,
      [1,0,1,0]=>1,
      [1,0,1,1]=>1,
      [1,1,0,0]=>1,
      [1,1,0,1]=>0,
      [1,1,1,0]=>:x,
      [1,1,1,1]=>1,
    }
    assert_equal([
      [:x,   true, false, false],
      [true, :x,   :x,    false],
      [true, :x,   true,  :x   ]],
      QM.qm(tbl))
  end

  def test_qm_implication
    tbl = {
      [false,false]=>true,
      [false,true ]=>true,
      [true, false]=>false,
      [true, true ]=>true,
    }
    assert_equal([[:x, true], [false, :x]], QM.qm(tbl))
  end

  def test_qm_shortcut_or
    tbl = {
      [0, 0]=>0,
      [1, :x]=>1,
      [0, 1]=>1
    }
    assert_equal([[:x, true], [true, :x]], QM.qm(tbl))
  end

  def test_qm_3and
    tbl = {
      [false,:x,   :x   ]=>false,
      [:x,   false,:x   ]=>false,
      [:x,   :x,   false]=>false,
      [true, true, true ]=>true,
    }
    assert_equal([[true, true, true]], QM.qm(tbl))
  end

  def test_qm_3or
    tbl = {
      [false,false,false]=>false,
      [true, :x,   :x   ]=>true,
      [:x,   true, :x   ]=>true,
      [:x,   :x,   true ]=>true,
    }
    assert_equal([[:x, :x, true], [:x, true, :x], [true, :x, :x]], QM.qm(tbl))
  end

  def test_qm_majority
    tbl = {
      [0,0,0]=>0,
      [0,0,1]=>0,
      [0,1,0]=>0,
      [0,1,1]=>1,
      [1,0,0]=>0,
      [1,0,1]=>1,
      [1,1,0]=>1,
      [1,1,1]=>1,
    }
    assert_equal([[:x, true, true], [true, :x, true], [true, true, :x]], QM.qm(tbl))
  end

  def test_qm_4bit_fib_predicate
    tbl = {
      [0,0,0,0]=>0,
      [0,0,0,1]=>1,     # 1
      [0,0,1,0]=>1,     # 2
      [0,0,1,1]=>1,     # 3
      [0,1,0,0]=>0,
      [0,1,0,1]=>1,     # 5
      [0,1,1,0]=>0,
      [0,1,1,1]=>0,
      [1,0,0,0]=>1,     # 8
      [1,0,0,1]=>0,
      [1,0,1,0]=>0,
      [1,0,1,1]=>0,
      [1,1,0,0]=>0,
      [1,1,0,1]=>1,     # 13
      [1,1,1,0]=>0,
      [1,1,1,1]=>0,
    }
    assert_equal([
      [:x, true, false, true],
      [false, :x, false, true],
      [false, false, true, :x],
      [true, false, false, false]],
      QM.qm(tbl))
  end

end
