class Diverge
  class << self
    attr_accessor :debug, :method_names

    def method_added(name)
      (@method_names ||= []) << name
    end

    def method_missing(name, *args, &block)
      if (Diverge.public_instance_methods & Diverge.method_names).include?(name)
        new(*args[0..1]).send(name, *args[2..-1])
      else
        super
      end
    end
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
    m = p.zip(q).map { |p_i, q_i| 0.5 * (p_i + q_i) }

    silently do
      0.5 * (Diverge.new(p, m).kl + Diverge.new(q, m).kl)
    end
  end

  alias :js :jensen_shannon

  def j_divergence
    0.5 * (kl + kl(:reverse))
  end

  alias :j :j_divergence

  def total_variation_distance
    0.5 * p.zip(q).inject(0.0) { |sum, (i, j)| sum + (i - j).abs }
  end

  alias :tvd :total_variation_distance

  def correlation
    square = ->(x) { x ** 2 }
    top    = size * p.zip(q).map { |x, y| x * y }.inject(&:+) - p.inject(&:+) * q.inject(&:+)
    bottom = Math.sqrt((size * p.map(&square).inject(&:+) - p.inject(&:+) ** 2) * (size * q.map(&square).inject(&:+) - q.inject(&:+) ** 2))

    bottom.zero? ? 0 : top / bottom
  end

  alias :corr :correlation

  def spearman_correlation
    sum_d_squared = list_ranks(p).zip(list_ranks(q)).inject(0.0) { |sum, (p_data, q_data)| sum + (p_data.rank_order - q_data.rank_order) ** 2 }

    1 - ((6 * sum_d_squared) / (size * (size ** 2 - 1)))
  end

  alias :s_corr :spearman_correlation

  def mean_square_error
    p.zip(q).inject(0.0) { |sum, (i, j)| sum + (i - j) ** 2 } / size
  end

  alias :mse :mean_square_error

  def root_mean_square_deviation
    Math.sqrt(p.zip(q).inject(0.0) { |sum, (i, j)| sum + (i - j) ** 2 } / size)
  end

  alias :rmsd :root_mean_square_deviation

  def debug
    self.class.debug
  end

  def debug=(value)
    self.class.debug = value
  end

  def silently(&block)
    debug_value = debug
    self.debug  = false
    (yield block).tap { self.debug = debug_value }
  end

  private

  def list_ranks(list)
    element = Struct.new(:value, :order, :rank_order)
    list.
      each_with_index.
      map { |x, i| element.new(x, i, nil) }.
      sort_by(&:value).
      each_with_index.
      group_by { |e, i| e.value }.
      values.
      inject([]) { |memo, a| memo + a.map(&:first).map { |e| e.tap { e.rank_order = a.map(&:last).avg + 1 } } }.
      sort_by(&:order)
  end

  def size
    p.length == q.length ? p.length : [p.length, q.length]
  end

  def debugger
    STDERR.puts yield if debug
  end
end