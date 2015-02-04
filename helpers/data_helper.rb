module DataHelper

  ### Friendly warning: use this module only if you're familiar with the input data

  # In our main classification case--clothing types--it's easier to represent
  # raw data in a hash of {description => clothing_type, .... } (just bear with me on that)
  # But in certain situations such as toy examples, we want to load training data
  # as array of hashes such as [{"sunny day"=>yes}, {"cloudy day"=>no}]
  # The function below serves to return just attribute and class regardless of
  # data structure of incoming parameters

  def handle_array_of_hashes(attr,klasses)
    if attr.is_a?(Hash)
      [attr.keys.first,attr.values]
    else
      [attr,klasses]
    end
  end

  module_function :handle_array_of_hashes
end
