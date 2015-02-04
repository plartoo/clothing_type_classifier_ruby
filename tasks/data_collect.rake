$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'dependencies'
require 'data_collector'

desc <<-EOD
Collect item attributes from fetchers.
Usage: rake collect MACHINE=phyo M_OR_Y="yaml"
Parameters:
  MACHINE = machine that will dictate where brand and fetcher result files are located (optional)
  MORY = dump results in marshal or yaml format (optional, default to marshal)
  I18N = will determine if we're on US or UK box/machine (optional)

EOD

task :collect do
  machine = (ENV['MACHINE'] || 'staging').to_sym
  i18n = (ENV['I18N'] || 'us').to_sym
  marshal_or_yaml = (ENV['MORY'] || 'marshal').to_sym

  data_collector = DataCollector.new({:machine=>machine,
                      :i18n=>i18n,
                      :marshal_or_yaml=>marshal_or_yaml})
  data_collector.run
end
