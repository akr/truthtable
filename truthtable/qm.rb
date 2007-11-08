# Quine-McCluskey algorithm

class TruthTable
  module QM
    module_function

    # implements Quine-McCluskey algorithm.
    # It minimize a boolean function given by <i>tbl</i>.
    #
    # For example, the 3-inputs majority function is given as follows.
    #
    #  tbl = {
    #  #  P      Q      R
    #    [false, false, false] => false,
    #    [false, false, true ] => false,
    #    [false, true,  false] => false,
    #    [false, true,  true ] => true,
    #    [true,  false, false] => false,
    #    [true,  false, true ] => true,
    #    [true,  true,  false] => true,
    #    [true,  true,  true ] => true,
    #  QM.qm(tbl)
    #  #=>
    #  [[:x, true, true], [true, :x, true], [true, true, :x]]  # Q&R | P&R | P&Q
    #  #     Q     R       P         R       P     Q
    #
    # For another example, the implication function is given as follows.
    #
    #  tbl = {
    #  #  P      Q
    #    [false, false] => true,
    #    [false, true ] => true,
    #    [true,  false] => false,
    #    [true,  true ] => true,
    #  }
    #  QM.qm(tbl)
    #  #=>
    #  [[:x, true], [false, :x]]  # Q | ~P
    #  #     Q       ~P
    #
    # <i>tbl</i> is a hash to represent a boolean function.
    # If the function has N variables, 
    # all key of <i>tbl</i> must be an array of N elements.
    #
    # A element of the key array and a value of the hash should be one of follows:
    # - false, 0
    # - true, 1
    # - :x
    #
    # 0 is same as false.
    #
    # 1 is same as false.
    #
    # :x means "don't care".
    #
    # For example, 3-inputs AND function can be given as follows.
    #
    #  tbl = {
    #    [false, :x,    :x   ] => false,
    #    [:x,    false, :x   ] => false,
    #    [:x,    :x,    false] => false,
    #    [true,  true,  true ] => true,
    #  }
    #
    # :x can be used for a value of <i>tbl</i> too.
    # It means that the evaluated result of minimized boolean function is not specified:
    # it may be evaluated to true or false.
    #
    #  tbl = {
    #    [false, false] => false,
    #    [false, true ] => true,
    #    [true,  false] => false,
    #    [true,  true ] => :x
    #  }
    #
    # If <i>tbl</i> doesn't specify some combination of
    # input variables, it assumes :x for such combination.
    # The above function can be specified as follows.
    #
    #  tbl = {
    #    [false, false] => false,
    #    [false, true ] => true,
    #    [true,  false] => false,
    #  }
    #
    # QM.qm returns an array of arrays which represents
    # the minimized boolean function.
    #
    # The minimized boolean function is a
    # disjunction of terms such as "term1 | term2 | term3 | ...".
    #
    # The inner array represents a term.
    # A term is a conjunction of input variables and negated input variables: "P & ~Q & ~R & S & ...".
    #
    def qm(tbl)
      return [] if tbl.empty?
      tbl = intern_tbl(tbl)
      prime_implicants = find_prime_implicants(tbl)
      essential_prime_implicants, chart = make_chart(prime_implicants, tbl)
      additional_prime_implicants = search_minimal_combination(chart)
      (essential_prime_implicants.keys + additional_prime_implicants).sort.map {|t|
        extern_term(t)
      }
    end

    # :stopdoc:

    def has_intersection?(t1, t2)
      [t1,t2].transpose.all? {|v1, v2|
        v1 == -1 || v2 == -1 || v1 == v2
      }
    end

    def implication?(t1, t2)
      [t1,t2].transpose.all? {|v1, v2|
        v2 == -1 || v1 == v2
      }
    end

    INTERN = {
      false => 0,
      true => 1,
      0 => 0,
      1 => 1,
      :x => -1,
    }
    def intern_tbl(tbl)
      result = {}
      num_inputs = nil
      tbl.each {|inputs, output|
        if !num_inputs
          num_inputs = inputs.length
        else
          if inputs.length != num_inputs
            raise ArgumentError, "different number of inputs"
          end
        end
        inputs2 = inputs.map {|v|
          if !INTERN.has_key?(v)
            raise ArgumentError, "unexpected input: #{v.inspect}"
          end
          INTERN[v]
        }
        if !INTERN.has_key?(output)
          raise ArgumentError, "unexpected output: #{output.inspect}"
        end
        result[inputs2] = INTERN[output]
      }
      result_keys = result.keys
      0.upto(result_keys.length-2) {|i|
        ki = result_keys[i]
        next if !result[ki]
        (i+1).upto(result_keys.length-1) {|j|
          kj = result_keys[j]
          next if !result[kj]
          if has_intersection?(ki, kj)
            if result[ki] != result[kj]
              raise ArgumentError, "inconsistent table"
            end
            if implication?(ki, kj)
              result.delete ki
            elsif implication?(kj, ki)
              result.delete kj
            end
          end
        }
      }
      not_specified = []
      0.upto((1 << num_inputs)-1) {|n|
        inputs = (0...num_inputs).map {|i| n[i] }
        if result.all? {|inputs_pat, output| !has_intersection?(inputs, inputs_pat) }
          not_specified << inputs
        end
      }
      not_specified.each {|inputs|
        result[inputs] = -1
      }
      result
    end

    EXTERN = {
      0 => false,
      1 => true,
      -1 => :x
    }
    def extern_term(t)
      t.map {|v| EXTERN[v] }
    end

    def combine(t1, t2)
      num_diffs = 0
      r = [t1,t2].transpose.map {|v1, v2|
        if v1 == v2
          v1
        elsif v1 == 0 && v2 == 1
          num_diffs += 1
          return nil if 1 < num_diffs
          -1
        elsif v1 == 1 && v2 == 0
          num_diffs += 1
          return nil if 1 < num_diffs
          -1
        else
          return nil
        end
      }
      if num_diffs == 1
        r
      else
        nil
      end
    end

    def combine2(t1, t2)
      num_diffs = 0
      r = [t1,t2].transpose.map {|v1, v2|
        if v1 == v2
          v1
        elsif v1 == 0 && v2 == 1
          num_diffs += 1
          return nil if 1 < num_diffs
          -1
        elsif v1 == 1 && v2 == 0
          num_diffs += 1
          return nil if 1 < num_diffs
          -1
        elsif v2 == -1
          v1
        else
          return nil
        end
      }
      if num_diffs == 1
        r
      else
        nil
      end
    end

    def find_prime_implicants(tbl)
      num_inputs = nil
      implicants_sets = []
      tbl.each {|inputs, output|
        next if output == 0
        num_inputs = inputs.length
        num_dontcares = inputs.grep(-1).length
        num_ones = inputs.grep(1).length
        implicants_sets[num_dontcares] ||= []
        implicants_sets[num_dontcares][num_ones] ||= {}
        implicants_sets[num_dontcares][num_ones][inputs] = true
      }
      combined = {}
      0.upto(num_inputs-1) {|num_dontcares|
        isets = implicants_sets[num_dontcares]
        next if !isets
        0.upto(isets.length-2) {|num_ones|
          next if !isets[num_ones] || !isets[num_ones+1]
          isets[num_ones].each_key {|t1|
            isets[num_ones+1].each_key {|t2|
              if t = combine(t1, t2)
                combined[t1] = combined[t2] = true
                implicants_sets[num_dontcares+1] ||= []
                implicants_sets[num_dontcares+1][num_ones] ||= {}
                implicants_sets[num_dontcares+1][num_ones][t] = true
              end
            }
          }
        }
        isets.each {|ts1|
          next if !ts1
          ts1.each_key {|t1|
            (num_dontcares+1).upto(num_inputs-1) {|num_dontcares2|
              isets2 = implicants_sets[num_dontcares2]
              next if !isets2
              isets2.each {|ts2|
                next if !ts2
                ts2.each_key {|t2|
                  if t = combine2(t1, t2)
                    combined[t1] = true
                    num_ones = t1.grep(1).length
                    implicants_sets[num_dontcares+1] ||= []
                    implicants_sets[num_dontcares+1][num_ones] ||= {}
                    implicants_sets[num_dontcares+1][num_ones][t] = true
                  end
                }
              }
            }
          }
        }
      }
      prime_implicants = {}
      implicants_sets.each {|isets|
        next if !isets
        isets.each {|ts|
          next if !ts
          ts.each_key {|t|
            next if combined[t]
            prime_implicants[t] = true
          }
        }
      }
      prime_implicants
    end

    def make_chart(prime_implicants, tbl)
      essential_prime_implicants = {}
      chart = []
      tbl.each {|inputs, output|
        next if output != 1
        pi_list = []
        prime_implicants.each_key {|pi|
          if implication?(inputs, pi)
            pi_list << pi
          end
        }
        if pi_list.length == 1
          essential_prime_implicants[pi_list[0]] = true
        else
          chart << pi_list
        end
      }
      chart.reject! {|pi_list| pi_list.any? {|pi| essential_prime_implicants[pi] } }
      return essential_prime_implicants, chart
    end

    def search_minimal_combination(chart)
      return [] if chart.empty?
      all_pi = {}
      chart.each {|pi_list|
        pi_list.each {|pi|
          all_pi[pi] = true
        }
      }
      q = {}
      all_pi.each_key {|pi|
        q[[pi]] = true
      }
      while true
        next_q = {}
        found = []
        until q.empty?
          pi_set0, _ = q.shift
          pi_set = {}
          pi_set0.each {|pi| pi_set[pi] = true }
          if chart.all? {|pi_list| pi_list.any? {|pi| pi_set[pi] }}
            found << pi_set0
          end
          all_pi.each_key {|pi|
            next if pi_set[pi]
            next_q[(pi_set0 + [pi]).sort] = true
          }
        end
        if !found.empty?
          return found.sort.first
        end
        q = next_q
      end
    end

    # :startdoc:
  end
end
