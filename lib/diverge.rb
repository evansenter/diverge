class Diverge
  attr_reader :p, :q
  
  def initialize(p, q)
    @p, @q = p, q
    
    unless p.length == q.length
      raise ArgumentError.new("The two discrete distributions must have the same number of elements") 
    end
    
    unless (p_sum = p.inject(&:+)) == 1
      STDERR.puts("Warning: the first argument does not sum to 1, the sum is #{p_sum}")
    end
    
    unless (q_sum = q.inject(&:+)) == 1
      STDERR.puts("Warning: the second argument does not sum to 1, the sum is #{q_sum}")
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
    0.5 * p.zip(q).inject(0.0) { |sum, (i, j)| sum + ((i || 0) - (j || 0)).abs }
  end
  
  alias :tvd, :total_variation_distance
end