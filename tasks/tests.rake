$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
$:.unshift File.join(File.dirname(__FILE__), '..', 'helpers')

require 'dependencies'
require 'naive_bayes_classifier'
require 'naive_bayes_classifier_tester'
require 'frequency_based_classifier'
require 'frequency_based_classifier_tester'
require 'classifier_rake_utilities'
require 'test_rake_utilities'
require 'data_helper'


desc <<-EOD
Run k-fold cross validation for the type of classifier definied by CLASSIFIER.
Two available options: 'n' for Naive Bayes and 'f' for Frequency-based (default).

Usage: rake run_k_fold_validation [options..]
  --> available options
      CLASSIFIER=<default:'f'>
      TRAINING_FILE=<default:"./simple_examples.yml">
      FOLDS=<default: 5>
      VERBOSE=<default: nil>

Example: rake run_k_fold_validation CLASSIFIER=n TRAINING_FILE="./input/clothing_type_examples"

EOD
task :run_k_fold_validation do
  folds,training_file,options = TestRakeUtilities.setup
  orig_training_data = ClassifierRakeUtilities.load_training_data(training_file)

  total_size = orig_training_data.size
  test_size = (total_size/folds.to_f).round

  c = nil
  used_as_test = {}
  success_rates = []

  1.upto(folds) do |i|
    puts "\n\nfold: #{i}" if options[:verbose]
    test,cur_training_data = TestRakeUtilities.split_hash(orig_training_data,test_size,used_as_test)

    c = options[:classifier].eql?('n') ? NaiveBayesClassifierTester.new(test, cur_training_data ,options) :
                                    FrequencyBasedClassifierTester.new(test, cur_training_data ,options)
    success_rates.push(c.k_fold_validation)
  end

  TestRakeUtilities.report_summary(success_rates)
  puts "classifying with #{c.class} finished successfully"
end

desc <<-EOD
Run one out validation for the type of classifier definied by CLASSIFIER.
Two available options: 'n' for Naive Bayes and 'f' for Frequency-based (default).

Usage: rake run_x_one_out_validation [options..]
  --> available options
      CLASSIFIER=<default:'f'>
      TRAINING_FILE=<default:"./simple_examples.yml">
      FOLDS=<default: 5>
      VERBOSE=<default: nil>

Example: rake run_x_one_out_validation CLASSIFIER=n TRAINING_FILE="./input/clothing_type_examples"

EOD
task :run_x_one_out_validation do
  folds,training_file,options = TestRakeUtilities.setup
  training_data = ClassifierRakeUtilities.load_training_data(training_file)

  c = options[:classifier].eql?('n') ? NaiveBayesClassifierTester.new({}, training_data ,options) :
                                    FrequencyBasedClassifierTester.new({}, training_data ,options)
  c.populate_frequency_table

  total_size = training_data.size
  used_as_test = {}
  success_count = 0
  iter_count = 0

  training_data.each do |k,v|
    k,v = DataHelper.handle_array_of_hashes(k,v)
    unless used_as_test[k]
      guess = c.x_one_out_run(k,v)
      if options[:verbose]
        puts "\n\niteration: #{iter_count}\tattribute tested: #{k}\t\tattribute guessed as: #{guess}"
        puts "answer: #{v.inspect}\n=========\n\n"
      end

      success_count += 1 if v.include?(guess)
      puts "iter:#{iter_count}\tanswer:#{v.inspect}\tguess:#{guess}\tsuccess_count:#{success_count}"
      used_as_test[k] = v
      iter_count += 1
    end
  end

  success_rates = success_count.to_f/training_data.size
  TestRakeUtilities.report_summary([success_rates])
  puts "classifying with #{c.class} finished successfully"
end

