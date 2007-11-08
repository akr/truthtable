# = truthtable
#
# == Feature
#
# - generate a truth table from a given block which contains logical formula written in Ruby.
# - generate a formula from the table:
#   - minimal one (obtained by Quine-McCluskey algorithm)
#   - disjunctive normal form
#   - conjunctive normal form
#
# == Example
#
# - simple operators
#
#    p TruthTable.new {|v| !v[0] }.formula        #=> "!v[0]"
#    p TruthTable.new {|v| v[0] & v[1] }.formula  #=> "v[0]&v[1]"
#    p TruthTable.new {|v| v[0] | v[1] }.formula  #=> "v[0] | v[1]"
#    p TruthTable.new {|v| v[0] ^ v[1] }.formula  #=> "!v[0]&v[1] | v[0]&!v[1]"
#    p TruthTable.new {|v| v[0] == v[1] }.formula #=> "!v[0]&!v[1] | v[0]&v[1]"
#
# - shortcuts, && and ||, are also usable but converted to & and |
#
#    p TruthTable.new {|v| v[0] && v[1] }.formula #=> "v[0]&v[1]"
#    p TruthTable.new {|v| v[0] || v[1] }.formula #=> "v[0] | v[1]"
#
# - actually any expression (without side effect)
#
#    p TruthTable.new {|v| v[0] ? !v[1] : v[1] }.formula #=> "!v[0]&v[1] | v[0]&!v[1]"
#
# - any number of inputs
#
#    p TruthTable.new {|v| [v[0], v[1], v[2], v[3]].grep(true).length <= 3 }.formula
#    #=> "!v[0] | !v[1] | !v[2] | !v[3]"
#

require 'truthtable/qm'

class TruthTable
  # :stopdoc:
  class TruthTableObject
    def initialize
      @checked = {}
      @plan = {}
      @order = []
      @queue = []
    end
    attr_reader :plan, :order

    def next_plan
      @log = {}
      @plan, @order = @queue.shift
      @plan
    end

    def [](index)
      s = "v[#{index}]"
      if @plan.has_key?(s)
        v = @plan[s]
      else
        fplan = @plan.dup
        fplan[s] = false
        fkey = fplan.keys.sort.map {|k| "#{k}=#{fplan[k]}" }.join(' ')
        @order += [s]
        @plan = fplan
        v = false
        if !@checked[fkey]
          tplan = @plan.dup
          tplan[s] = true
          tkey = tplan.keys.sort.map {|k| "#{k}=#{tplan[k]}" }.join(' ')
          torder = @order.dup
          torder[-1] = s
          @queue.unshift [tplan, torder]
          @checked[tkey] = true
          @checked[fkey] = true
        end
      end
      v
    end
  end
  # :startdoc:

  def self.test(&b)
    r = []
    o = TruthTableObject.new
    begin
      result = b.call(o)
      inputs = o.plan
      order = o.order
      r << [inputs, result, order]
    end while o.next_plan
    r
  end

  def initialize(&b)
    table = TruthTable.test(&b)
    @table = table
  end

  # :stopdoc:
  def all_names
    return @all_names if defined? @all_names
    @all_names = {}
    @table.each {|inputs, output, order|
      order.each {|name|
        if !@all_names.has_key?(name)
          @all_names[name] = @all_names.size
        end
      }
    }
    @all_names
  end

  def sort_names(names)
    total_order = all_names
    names.sort_by {|n| total_order[n] }
  end
  # :startdoc:

  # obtains a formula in disjunctive normal form.
  def dnf
    r = []
    @table.each {|inputs, output|
      next if !output
      term = []
      sort_names(inputs.keys).each {|name|
        input = inputs[name]
        if input
          term << name
        else
          term << "!#{name}"
        end
      }
      r << term.join('&')
    }
    r.join(' | ')
  end

  # obtains a formula in conjunctive normal form.
  def cnf
    r = []
    @table.each {|inputs, output|
      next if output
      term = []
      sort_names(inputs.keys).each {|name|
        input = inputs[name]
        if input
          term << "!#{name}"
        else
          term << name
        end
      }
      if term.length == 1
        r << term.join('|')
      else
        r << "(#{term.join('|')})"
      end
    }
    r.join(' & ')
  end

  # obtains a minimal formula using Quine-McCluskey algorithm.
  def formula
    input_names = all_names
    input_names_ary = sort_names(input_names.keys)
    tbl = {}
    @table.each {|inputs, output|
      inputs2 = [:x] * input_names.length
      inputs.each {|name, input|
        inputs2[input_names[name]] = input ? 1 : 0
      }
      tbl[inputs2] = output ? 1 : 0
    }
    qm = QM.qm(tbl)
    r = []
    qm.each {|term|
      t = []
      term.each_with_index {|v, i|
        if v == false
          t << ("!" + input_names_ary[i])
        elsif v == true
          t << input_names_ary[i]
        end
      }
      r << t.join('&')
    }
    r.join(' | ')
  end
end

if __FILE__ == $0
p TruthTable.new {|v| v[0] & v[1] }.formula
p TruthTable.new {|v| v[0] && v[1] }.formula
p TruthTable.new {|v| v[0] | v[1] }.formula
p TruthTable.new {|v| v[0] || v[1] }.formula
p TruthTable.new {|v| v[0] ^ !v[1] }.formula
p TruthTable.new {|v| v[0] == v[1] }.formula
p TruthTable.new {|v| v[0] == v[1] && v[1] != v[2] || v[3] == v[1] }.formula
end

