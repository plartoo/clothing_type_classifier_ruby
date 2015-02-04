class FrequencyBasedClassifier

  UNKNOWN_KLASS = -1
  UNKNOWN = {UNKNOWN_KLASS => 0}

  attr_accessor :frequency_table

  def initialize(training_data, options={})
    @options = options
    @training_data = training_data
    @frequency_table = nil
    @stop_words = nil
  end

  def verbose
    @options[:verbose]
  end

  def create_attributes(description)
    description.split.map{|w| w.gsub(/\W/,'').downcase}
  end

  def exclude_attributes(attributes)
    load_stop_words unless @stop_words

    attributes.reject{|x| @stop_words.include?(x)}
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

  def load_stop_words
    @stop_words = []
    @options[:stop_word_files].each do |f|
      @stop_words.push YAML::load(File.open(f,'r'))
    end
  end

  def populate_frequency_table
    @frequency_table = {}
    @training_data.each do |desc, klasses|
      attributes = prepare_attributes(desc)
      attributes.each do |a|
        @frequency_table[a] ||= {}
        klasses.each do |k|
          @frequency_table[a][k] ||= 0
          @frequency_table[a][k] += 1
        end
      end
    end
  end

  def total_count(hash_of_counts)
    # for Scheme 2 scoring approach (read Brief Explanation of classifiers)
    #total = hash_of_counts.keys.size.to_f
    # for Scheme 3 scoring approach
    total = hash_of_counts.values.inject(0.0){|sum,count| sum+=count.to_f}

    # can't be zero because this will become denominator
    total.eql?(0.0) ? 1.0 : total
  end

  def normalized_frequencies_per_attr(attribute, value_container)
    klass_hash = @frequency_table[attribute] || UNKNOWN

#    # for Scheme 1 scoring approach, use this
#    klass_hash.each do |k,klass_count|
#      value_container[k] ||= 0
#      value_container[k] += klass_count
#    end

    # Scheme 2 and 3 uses code below
    total_frequency_per_attr = total_count(@frequency_table[attribute]) rescue 1.0
    klass_hash.each do |k,klass_count|
      value_container[k] ||= 0
      value_container[k] += klass_count/total_frequency_per_attr
    end
  end

  def noramlized_frequency_scores_per_klass(attributes)
    normalized_frequencies_per_klass = {}
    attributes.each do |attr|
      normalized_frequencies_per_attr(attr, normalized_frequencies_per_klass)
    end
    normalized_frequencies_per_klass
  end

  def predict_by_highest_normalized_frequency_score(attributes)
    attributes.sort_by{|id,count| count}.last.first rescue UNKNOWN_KLASS
  end

  def classify(description)
    populate_frequency_table unless @frequency_table
    normalized_frequency_scores = noramlized_frequency_scores_per_klass(prepare_attributes(description))
    predict_by_highest_normalized_frequency_score(normalized_frequency_scores)
  end

end

