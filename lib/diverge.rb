require "gsl"

class Diverge
  class << self
    attr_accessor :debug
  end
  
  @debug = true
  
  attr_reader :p, :q
  
  def initialize(p, q)
    @p, @q = p, q
    
    unless p.length == q.length
      debugger { "The two discrete distributions must have the same number of elements" }
    end
    
    unless (p_sum = p.inject(&:+)) == 1
      debugger { "Warning: the first argument does not sum to 1, the sum is #{p_sum.inspect}" }
    end
    
    unless (q_sum = q.inject(&:+)) == 1
      debugger { "Warning: the second argument does not sum to 1, the sum is #{q_sum.inspect}" }
    end
  end
  
  def kullback_leibler(reverse = false)
    (reverse ? q.zip(p) : p.zip(q)).inject(0.0) do |sum, (i, j)|
      if i > 0 && j.zero?
        raise ArgumentError.new("Kullback-Leibler is not defined when P(i) > 0 and Q(i) = 0")
      end
      
      sum + (i.zero? ? 0 : i * Math.log(i / j))
    end
  end
  
  alias :kl :kullback_leibler
  
  def jensen_shannon
    0.5 * (kl + kl(:reverse))
  end
  
  alias :js :jensen_shannon
  
  def total_variation_distance
    0.5 * p.zip(q).inject(0.0) { |sum, (i, j)| sum + (i - j).abs }
  end
  
  alias :tvd :total_variation_distance
  
  def correlation
    GSL::Stats::correlation(GSL::Vector.alloc(p), GSL::Vector.alloc(q))
  end
  
  alias :corr :correlation

  def spearman_correlation
    p_ranks   = list_ranks(p)
    q_ranks   = list_ranks(q)
    d_squared = p.zip(q).map { |x, y| (p_ranks[x] - q_ranks[y]) ** 2 }

    1 - ((6 * d_squared.inject(&:+)) / (size * (size ** 2 - 1)))
  end

  alias :s_corr :spearman_correlation
  
  def debug
    self.class.debug
  end
  
  def debug=(value)
    self.class.debug = value
  end
  
  private

  def list_ranks(list)
    uniq_list = list.sort.uniq
    Hash[*
      list.
        sort.
        each_with_index.
        group_by { |x, i| x }.
        values.
        map { |a| a.map(&:first).zip([a.map(&:last).avg + 1] * a.length).uniq }.
        flatten
    ]
  end

  def size
    p.length == q.length ? p.length : [p.length, q.length]
  end
  
  def debugger
    STDERR.puts yield if debug
  end
end