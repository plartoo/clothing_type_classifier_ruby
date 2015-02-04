$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
$:.unshift File.join(File.dirname(__FILE__), '..', 'helpers')

require 'dependencies'
require 'naive_bayes_classifier'
require 'frequency_based_classifier'
require 'classifier_rake_utilities'
require 'data_helper'

desc <<-EOD
Classify a given query using specified classifier (default: Frequency-based)

Usage: rake classify [options..]
  --> available options:
      CLASSIFIER=<use 'n' to use Naive Bayes classifier>
      QUERY=<default:"Red Domestic SUV">
      TRAINING_FILE=<default:"./../input/simple_example_1_in_hash_yaml_format.yml">
      STOP_WORD_FILE=<default files loaded:["./../stop_words/stop_words.yml",
                                     "./../stop_words/one_letter_stop_words.yml",
                                     "./../stop_words/two_letter_stop_words.yml"]>
      [optional options below]
      FREQUENCY_TABLE=<example:"./fb_frequency_table">
      HUMAN_READABLE=<example:'y'>

EXAMPLE: rake classify CLASSIFIER='n' QUERY="dress crazy" TRAINING_FILE="./input/clothing_type_examples_in_marshal_format" HUMAN_READABLE=y

NOTE: * Frequency table will be loaded from FREQUENCY_TABLE if provided.
      * Must provide TRAINING_FILE to build frequency table if FREQUENCY_TABLE is not
        provided.
      * If HUMAN_READABLE is provided, it'll respond you with answers matched
        from what's in './input/misc/common_clothing_types.yml'
      * Default values are defined in the module definied in 'classifier_rake_utilities.rb'
      * Answer 'no' to stop being asked for input again.
EOD
task :classify do
  include ClassifierRakeUtilities

  str,training_file,options = setup
  training_data = load_training_data(training_file)

  c = options[:classifier].eql?('n') ? NaiveBayesClassifier.new(training_data ,options) :
                                      FrequencyBasedClassifier.new(training_data,options)

  if options[:frequency_table]
    load_frequency_table(c, options[:frequency_table])
  end

  references = load_human_readable_clothing_refs
  guess = c.classify(str)
  guess = references[guess.to_i] rescue guess
  report_classification(str,guess)

  str = ask_to_try_again
  while !str.eql?('no')
    guess = c.classify(str)
    guess = references[guess.to_i] rescue guess
    report_classification(str,guess)
    str = ask_to_try_again
  end
end


desc <<-EOD
Generate frequency table file in either Marshal or YAML format so that we don't have to build the frequency table again.

Usage: generate_frequency_table_file [options..]
  --> available options
      CLASSIFIER=<use 'n' to use Naive Bayes classifier>
      STOP_WORD_FILE=<default files:["./stop_words/stop_words.yml",
                                     "./stop_words/one_letter_stop_words.yml",
                                     "./stop_words/two_letter_stop_words.yml"]>
      TRAINING_FILE=<default:"./simple_example_1_in_hash_yaml_format.yml">
      FREQUENCY_TABLE="./nb_table"

EXAMPLE: $ rake generate_frequency_table_file CLASSIFIER='f' TRAINING_FILE="./input/clothing_type_examples_in_marshal_format" FREQUENCY_TABLE="./frequency_based_table"

NOTE: * CLASSIFIER options determine if the output table prepared is for Naive Bayes (option 'n') or Frequency-based classifier
      * FREQUENCY_TABLE is the output file to which the table will be written out.
      * If FREQUENCY_TABLE extension is not 'yml', it'll be written out as Marshal.
      * Must provide names of TRAINING_FILE and the output FREQUENCY_TABLE.
      * Default values are defined in the module definied in 'classifier_rake_utilities.rb'
EOD

task :generate_frequency_table_file do
  include ClassifierRakeUtilities

  str,training_file,options = setup

  if File.exists?(options[:frequency_table])
    puts "Frequency table file already exists.  Please make sure to delete it before you create a new one.\n"
    exit(1)
  end

  training_data = load_training_data(training_file)

  c = options[:classifier].eql?('n') ? NaiveBayesClassifier.new(training_data ,options) :
                                    FrequencyBasedClassifier.new(training_data ,options)
  c.populate_frequency_table
  cache_frequency_table(c, options[:frequency_table])
end
