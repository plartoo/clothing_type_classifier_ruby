module ClassifierRakeUtilities
  DEFAULT_QUERY = "Red Domestic SUV"
  DEFAULT_TRAINING_FILE = "./input/simple_example_1_in_hash_yaml_format.yml"
  DEFAULT_STOP_WORD_FILE = ["./stop_words/stop_words.yml",
                            "./stop_words/one_letter_stop_words.yml",
                            "./stop_words/two_letter_stop_words.yml"]
  DEFAULT_CLOTHING_TYPES = "./input/misc/common_clothing_types.yml"

  def setup
    str = ENV['QUERY'] || DEFAULT_QUERY
    training_file = ENV['TRAINING_FILE'] || DEFAULT_TRAINING_FILE

    options = {}
    if ENV['STOP_WORD_FILE']
      options[:stop_word_files] = DEFAULT_STOP_WORD_FILE.push ENV['STOP_WORD_FILE']
    else
      options[:stop_word_files] = DEFAULT_STOP_WORD_FILE
    end

    options[:verbose] = ENV['VERBOSE']
    options[:frequency_table] = ENV['FREQUENCY_TABLE']
    options[:classifier] = ENV['CLASSIFIER'] || 'f'
    [str,training_file,options]
  end

  def report_classification(input, classification)
    puts "\n\n<#{input}> belongs to class: <#{classification}>\n\n"
  end

  def ask_to_try_again
    puts "want to try another one?(type 'no' if you don't)\ninput query:"
    $stdin.gets.chomp
  end

  def yaml?(str)
    str.match(/\.yml/i)
  end

  def load_training_data(file_name)
    yaml?(file_name) ? YAML::load_file(file_name) :
                       Marshal::load(File.open(file_name,'r'))
  end

  def cache_frequency_table(classifier_object, file_name)
    File.open(file_name, 'w') do |f|
      str = yaml?(file_name) ? classifier_object.frequency_table.to_yaml :
                               Marshal::dump(classifier_object.frequency_table)
      f.puts str
      puts "Frequency table cached successfully at #{f.path}\n\n"
    end
  end

  def load_frequency_table(classifier_object, file_name)
    data = yaml?(file_name) ? YAML::load_file(file_name) :
                              Marshal::load(File.open(file_name,'r'))
    classifier_object.frequency_table = data
    puts "\n\nFrequency table loaded successfully from #{file_name}"
  end

  def load_human_readable_clothing_refs
    if ENV['HUMAN_READABLE']
      ref = YAML.load_file(DEFAULT_CLOTHING_TYPES)
      # remove clothing types that don't have groups assigned yet
      # (because when I collected raw data, these clothing types aren't included)
      ref = ref.reject{|k,v| v[:group].nil?}
      ref = ref.reject{|k,v| v[:group].nil?}.inject({}) do |h,e|
        h[e.last[:bm]]=e.first
        h
      end
      ref.merge({-1=>'Unknown'})
    else
      nil
    end
  end

  module_function :setup, :report_classification, :ask_to_try_again,
                  :yaml?, :load_training_data, :cache_frequency_table,
                  :load_human_readable_clothing_refs, :load_frequency_table

end
