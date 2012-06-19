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
    (reverse ? q.zip(p) : p.zip(q)).inject(0.0) { |sum, (i, j)| sum + (i.zero? ? 0 : i * Math.log(safe_cast(i) / safe_cast(j))) }
  end
  
  alias :kl :kullback_leibler
  
  def jensen_shannon
    0.5 * (kl + kl(:reverse))
  end
  
  alias :js :jensen_shannon
  
  private
  
  def safe_cast(value)
    # Just to make sure we don't go crazy and to_f a Complex, for whatever insane reason that might come up, while still avoiding integer division
    value.class < Integer ? value.to_f : value
  end
end