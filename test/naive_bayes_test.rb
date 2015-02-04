require File.join(File.dirname(__FILE__), '..', 'lib', 'naive_bayes_classifier')
require File.join(File.dirname(__FILE__), 'test_dependencies')


require 'ruby-debug'
class NaiveBayesTest < Test::Unit::TestCase

  def setup
    @string = "Hello World"
    @data_file = File.join(File.dirname(__FILE__),'fixtures','clothing_type_data.yml')
    @data = YAML::load_file(@data_file)
    @model = NaiveBayes.new(@data)
  end

  def test_frequency_table_is_initialized_with_keys
    assert @model.frequency_table.has_key?(:attr_to_cid)
    assert @model.frequency_table.has_key?(:cid_to_attr)
  end

  def test_cleanse_description_removes_non_word_characters_and_downcase_orig_string
    strings = ["Hello World","Who's who?","1234 Boot","PETITE shirts!"]
    expected_strings = [["hello", "world"],["whos", "who"],["1234", "boot"],["petite", "shirts"]]
    strings.each_with_index do |s,i|
      assert_equal expected_strings[i], @model.prepare_attributes(s)
    end
  end

  def test_prepare_attributes_calls_cleanse_description_once
    @model.expects(:cleanse_description).once.with(@string)
    @model.stubs(:exclude_attributes).returns([])
    @model.prepare_attributes(@string)
  end

  def test_exclude_attributes_removes_stop_words_from_original_attribute_list
    attributes = ["hello","world",""]
    assert_equal attributes[0..-2], @model.exclude_attributes(attributes)
  end

  def test_prepare_attributes_calls_exclude_attributes_once
    attributes = ["hello","world"]
    @models.stubs(:cleanse_description).returns(attributes)
    @model.expects(:exclude_attributes).once.with(attributes)
    @model.prepare_attributes(@string)
  end

  def test_increment_count_sets_and_increase_the_counter_in_specified_hash_bucket_and_key
    hash = {:attr_to_cid => {
                              "up" => 1
                            },:cid_to_attr=>{}}
    @model.increment_count(hash[:attr_to_cid],"up")
    assert_equal 2, hash[:attr_to_cid]["up"]
    @model.increment_count(hash[:cid_to_attr],"down")
    assert_equal 1, hash[:cid_to_attr]["down"]
  end


  def test_populate_frequency_table_successfully_populate_the_frequency_table
    local_model = NaiveBayes.new(@data_file)
    local_model.training_data = {
      "hello world" => [1],
      "World hello" => [1,2],
      "Naive Bayes!" => [4],
    }

    local_model.populate_frequency_table
    cid_to_attr = local_model.cid_to_attr
    attr_to_cid = local_model.attr_to_cid
    assert_equal cid_to_attr[1],{"world"=>2, "hello"=>2}
    assert_equal cid_to_attr[2],{"world"=>1, "hello"=>1}
    assert_equal cid_to_attr[4],{"bayes"=>1, "naive"=>1}

    assert_equal attr_to_cid["hello"],{1=>2, 2=>1}
    assert_equal attr_to_cid["world"],{1=>2, 2=>1}
    assert_equal attr_to_cid["naive"],{4=>1}
  end

end

