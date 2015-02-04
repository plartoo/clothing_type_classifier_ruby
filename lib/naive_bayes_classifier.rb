# ref: <http://nlp.stanford.edu/IR-book/html/htmledition/naive-bayes-text-classification-1.html#tab:nbtoy>
# pls refer to Explanation_and_results if the code is confusing

class NaiveBayesClassifier

  UNKNOWN_KLASS = -1

  attr_accessor :frequency_table

  def initialize(training_data, options={})
    @options = options
    @training_data = training_data
  end

  def verbose
    @options[:verbose]
  end

  def load_stop_words
    @stop_words = []
    @options[:stop_word_files].each do |f|
      @stop_words.push YAML::load(File.open(f,'r'))
    end
  end

  def create_attributes(description)
    description.split.map!{|w| w.gsub(/\W/,'').downcase}
  end

  def exclude_attributes(attributes)
    load_stop_words unless @stop_words

    attributes.reject{|x| @stop_words.include?(x) || x.empty?}
  end

  ## create attributes out of an array of word
  ## e.g., "['hello', 'world', 'phyo']" will yield ["hello world", "world phyo"]
  def double_up(attributes)
    temp_attrs = []
    attributes.each_with_index{|a,i| temp_attrs << "#{a} #{attributes[i+1]}".strip}
    temp_attrs.select{|a| a.split.size == 2}
  end

  def prepare_attributes(description)
    attrs = exclude_attributes(create_attributes(description))
    attrs.concat(double_up(attrs)) if attrs.any?
  end

  def change_count(hash,key,amount)
    hash[key] ||= 0
    hash[key] += amount
  end

  def class_to_attr
    @frequency_table[:class_to_attr]
  end

  def class_count
    @frequency_table[:class_count]
  end

  def uniq_attrs
    @frequency_table[:uniq_attrs]
  end

  def populate_frequency_table
    @frequency_table = {:class_to_attr=>{},:class_count=>{},:uniq_attrs=>{}}
    @training_data.each do |description,klasses|
      # read 'data_helper.rb' for why I use this
      description, klasses = DataHelper.handle_array_of_hashes(description,klasses)

      attributes = prepare_attributes(description)
      attributes.each do |a|
        change_count(uniq_attrs,a,1)
        klasses.each do |k|
          class_to_attr[k] ||= {}
          change_count(class_to_attr[k],a,1)
        end
      end
      klasses.each{|k| change_count(class_count,k,1)}
    end
  end

  def sum_of(hash)
    hash.values.inject{|sum,n| sum + n}
  end

  # make sure number used for denominator is not going to be zero
  def check_denominator(num)
    num.eql?(0.0) ? 1.0 : num
  end

  def log_of_prior(klass)
    denominator = sum_of(class_count).to_f rescue 0.0
    Math.log(class_count[klass]/check_denominator(denominator))
  end

  # we'll use Laplace Smoothing as mentioned in "ref"
  def conditional_probability(attr,klass)
    numerator = (class_to_attr[klass][attr].to_f + 1.0) rescue 0.0
    denominator = (sum_of(class_to_attr[klass]) + @laplace_const) rescue 0.0

    numerator/check_denominator(denominator)
  end

  def log_of_likelihood(attributes,klass)
    likelihood = 0.0
    attributes.each do |a|
      likelihood += Math.log(conditional_probability(a,klass))
    end
    likelihood
  end

  # uses 'maximum a posteriori (MAP)' and answers 'Unknown' when given
  def apply_prediction_rule(posteriors_by_class)
    values = posteriors_by_class.values.uniq
    if values.size.eql?(1) && values.first.eql?(0.0)
      UNKNOWN_KLASS
    else
      posteriors_by_class.sort_by{|k,v| v}.last.first
    end
  end

  def klasses
    class_count.keys
  end

  def classify(description)
    populate_frequency_table unless @frequency_table
    @laplace_const = uniq_attrs.select{|k,v| !v.eql?(0)}.size.to_f
    attributes = prepare_attributes(description)

    posteriors_by_class = {}
    klasses.each do |klass|
      posteriors_by_class[klass] = log_of_prior(klass) + log_of_likelihood(attributes,klass)
    end

    puts "#{posteriors_by_class.sort_by{|k,v| v}.inspect}" if verbose
    apply_prediction_rule(posteriors_by_class)
  end
end

