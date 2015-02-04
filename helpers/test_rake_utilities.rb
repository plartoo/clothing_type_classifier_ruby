module TestRakeUtilities
  include ClassifierRakeUtilities

  DEFAULT_FOLDS = 5

  def setup
    query, training_file, options = ClassifierRakeUtilities.setup
    folds = (ENV['FOLDS'] || DEFAULT_FOLDS).to_i

    [folds,training_file,options]
  end

  def split_hash(orig_training_data, test_hash_size, used_as_test)
    test = {}
    puts "all training data size: #{orig_training_data.size}"
    training = Marshal.load(Marshal.dump(orig_training_data))

    orig_training_data.each do |k,v|
      k,v = DataHelper.handle_array_of_hashes(k,v)
      break if test.size.eql?(test_hash_size)
      unless used_as_test[k]
        test[k] = v
        used_as_test[k] = v
        training.delete(k)
      end
    end
    [test,training]
  end

  def report_summary(success_rates)
    total = 0.0
    success_rates.each_with_index do |r,i|
      total += r
      puts "iter:\t#{i} ==> #{r}"
    end

    puts "\n======\naverage: #{total/success_rates.size}"
  end

  module_function :setup, :split_hash, :report_summary
end
