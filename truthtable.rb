require 'truthtable/qm'

class TruthTable
  # :stopdoc:
  class TruthTableObject
    def initialize
      @checked = {}
      @plan = {}
      @queue = []
    end
    attr_reader :plan

    def next_plan
      @log = {}
      @plan = @queue.shift
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
        @plan = fplan
        v = false
        if !@checked[fkey]
          tplan = @plan.dup
          tplan[s] = true
          tkey = tplan.keys.sort.map {|k| "#{k}=#{tplan[k]}" }.join(' ')
          @queue.unshift tplan
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
      r << [inputs, result]
    end while o.next_plan
    r
  end

  def initialize(&b)
    table = TruthTable.test(&b)
    @table = table
  end

  # obtains a formula in disjunctive normal form.
  def dnf
    r = []
    @table.each {|inputs, output|
      next if !output
      term = []
      inputs.each {|name, input|
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
      inputs.each {|name, input|
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
    input_names = {}
    input_names_ary = []
    @table.each {|inputs, output|
      inputs.each {|name, input|
        if !input_names[name]
          input_names[name] = input_names.length
          input_names_ary << name
        end
      }
    }
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

