class DataCollector
  attr_reader :marshal_or_yaml, :feed_dir, :scraped_dates, :data_file
  attr_accessor :data

  DATE = /\/(\d+)\.yml/
  @@config_file = "./config/config.yml"
  @@scraped_dates_record = "./output/misc/scraped_dates.yml"

  def initialize(options={})
    machine = options[:machine]
    i18n = options[:i18n]
    config = YAML.load_file(@@config_file)[machine][i18n]

    @marshal_or_yaml = options[:marshal_or_yaml]
    @scraped_dates = YAML.load_file(@@scraped_dates_record) rescue {}
    @feed_dir = config[:feed_dir]
    @data_file = marshal? ? config[:data_file] : "#{config[:data_file]}.yml"
  end

  def marshal?
    marshal_or_yaml.eql?(:marshal)
  end

  def extract_attributes(items)
    items.each do |item|
      description = item[:description]##.downcase#parse_description(item[:description])
      clothing_type_bm = item[:clothing_type][:bm] rescue next
      if data.has_key?(description)
        unless data[description].include?(clothing_type_bm)
          data[description].push(clothing_type_bm)
        end
      else
        data[description] = [clothing_type_bm]
      end
    end
  end

  def load_data
    if marshal?
      @data = Marshal::load(File.open(data_file,'r')) rescue {}
    else
      @data = YAML::load_file(data_file) rescue {}
    end
  end

  def data_files
    Dir.glob(File.join(feed_dir+"*/*")).reject do |f|
      scraped_dates.has_key?((f.match(DATE)[1] rescue 'not_a_valid_file'))
    end
  end

  def update_data(file)
    # 'rescue' is for some yaml files which are corrupted
    items = (YAML.load_file(file) || []) rescue []
    extract_attributes(items)
  end

  def record_date(file_name)
    date = file_name.match(DATE)[1]
    scraped_dates[date] = nil
  end

  def run
    load_data

    data_files.sort.each do |f|
      puts "processing\t#{f}"
      if f.match(/\.gz/)
        no_gz = f.gsub(/\.gz$/i,'')
        `gunzip #{f}`
        update_data(no_gz)
        `gzip #{no_gz}`
      else
        update_data(f)
      end
      record_date(f)
    end

    write_dates
    write_data
  end

  def write_dates
    f = File.open(@@scraped_dates_record, 'w')
    f.puts YAML::dump(scraped_dates)
    f.close
    puts "dates successfully written to\t#{f.path}\n"
  end

  def write_data
    str = marshal? ? Marshal::dump(data) : YAML::dump(data)
    File.open(data_file, 'w') do |f|
      f.puts str
    end
    puts "attribute data successfully written to\t#{data_file}\n"
  end
end
