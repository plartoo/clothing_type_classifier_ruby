class FrequencyBasedClassifierTester

  attr_accessor :test_data

  def initialize(test_data, training_data, options={})
    @options = options
    @classifier = FrequencyBasedClassifier.new(training_data, @options)
    @test_data = test_data
  end

  def verbose
    @options[:verbose]
  end

  def k_fold_validation
    success = 0
    @test_data.each do |string,klass|
      guessed = @classifier.classify(string)
      puts "#{string}\ttruth: #{klass.inspect}\tguessed: #{guessed}" if verbose
      success += 1 if klass.include?(guessed)
      puts "success: #{success}" if verbose
    end
    puts "\n\n====\nsuccess ratio for current fold: #{success.to_f/@test_data.size}\n====\n"
    success.to_f/@test_data.size
  end


  def update_frequency_table(description,action)
    words = @classifier.prepare_attributes(description)
    change = action.eql?(:up) ? 1 : -1
    words.each do |w|
      @classifier.frequency_table[w].each do |k,v|
        @classifier.frequency_table[w][k] += change  rescue 0
      end
    end
  end

  def x_one_out_run(description)
    update_frequency_table(description,:down)
    guess = @classifier.classify(description)
    update_frequency_table(description,:up)
    guess
  end

  def method_missing(method_name, *args)
    puts "called #{method_name}"
    @classifier.send(method_name.to_sym)
  end

end

