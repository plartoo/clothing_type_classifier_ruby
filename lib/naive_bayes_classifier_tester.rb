class NaiveBayesClassifierTester

  attr_accessor :test_data, :classifier

  def initialize(test_data, training_data, options={})
    @options = options
    @classifier = NaiveBayesClassifier.new(training_data, @options)
    @test_data = test_data
  end

  def verbose
    @options[:verbose]
  end

  def k_fold_validation
    @classifier.populate_frequency_table

    success = 0
    @test_data.each do |string,klass|
      guessed = @classifier.classify(string)
      puts "\n\n#{string}\ttruth: #{klass.inspect}\tguessed: #{guessed}" if verbose
      success += 1 if klass.include?(guessed)
      puts "success: #{success}" if verbose
    end
    puts "\n\n====\nsuccess ratio for current fold: #{success.to_f/@test_data.size}\n====\n"
    success.to_f/@test_data.size
  end

  def update_frequency_table(description,answer_classes,action)
    attrs = @classifier.prepare_attributes(description)
    change = action.eql?(:up) ? 1 : -1

    attrs.each do |a|
      @classifier.change_count(@classifier.uniq_attrs,a,change)
      answer_classes.each do |k|
        @classifier.change_count(@classifier.class_to_attr[k],a,change)
      end
    end

    answer_classes.each do |k|
      @classifier.change_count(@classifier.class_count,k,change)
    end
  end

  def x_one_out_run(description,answers)
    update_frequency_table(description,answers,:down)
    guess = @classifier.classify(description)
    update_frequency_table(description,answers,:up)
    guess
  end

  def method_missing(method_name, *args)
    puts "called #{method_name}"
    @classifier.send(method_name.to_sym)
  end

end

