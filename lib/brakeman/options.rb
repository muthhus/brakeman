require 'optparse'
require 'set'

#Parses command line arguments for Brakeman
module Brakeman::Options

  class << self

    #Parse argument array
    def parse args
      get_options args
    end

    #Parse arguments and remove them from the array as they are matched
    def parse! args
      get_options args, true
    end

    #Return hash of options and the parser
    def get_options args, destructive = false
      options = {}

      parser = OptionParser.new do |opts|
        opts.banner = "Usage: brakeman [options] rails/root/path"

        opts.on "-n", "--no-threads", "Run checks sequentially" do
          options[:parallel_checks] = false
        end

        opts.on "--no-progress", "Do not show progress reports" do
          options[:report_progress] = false
        end

        opts.on "-p", "--path PATH", "Specify path to Rails application" do |path|
          options[:app_path] = File.expand_path path
        end

        opts.on "-q", "--quiet", "Suppress informational messages" do
          options[:quiet] = true
        end

        opts.on( "-z", "--exit-on-warn", "Exit code is non-zero if warnings found") do |s|
          options[:exit_on_warn] = s
        end

        opts.on "-3", "--rails3", "Force Rails 3 mode" do
          options[:rails3] = true
        end

        opts.separator ""
        opts.separator "Scanning options:"

        opts.on "-a", "--assume-routes", "Assume all controller methods are actions" do
          options[:assume_all_routes] = true
        end

        opts.on "--ignore-model-output", "Consider model attributes XSS-safe" do
          options[:ignore_model_output] = true
        end

        opts.on "-e", "--escape-html", "Escape HTML by default" do
          options[:escape_html] = true
        end

        opts.on "--faster", "Faster, but less accurate scan" do
          options[:ignore_ifs] = true
          options[:skip_libs] = true
        end

        opts.on "--no-branching", "Disable flow sensitivity on conditionals" do
          options[:ignore_ifs] = true
        end

        opts.on "-r", "--report-direct", "Only report direct use of untrusted data" do |option|
          options[:check_arguments] = !option
        end

        opts.on "-s", "--safe-methods meth1,meth2,etc", Array, "Consider the specified methods safe" do |methods|
          options[:safe_methods] ||= Set.new
          options[:safe_methods].merge methods.map {|e| e.to_sym }
        end

        opts.on "--skip-libs", "Skip processing lib directory" do
          options[:skip_libs] = true
        end

        opts.on "-t", "--test Check1,Check2,etc", Array, "Only run the specified checks" do |checks|
          checks.each_with_index do |s, index|
            if s[0,5] != "Check"
              checks[index] = "Check" << s
            end
          end

          options[:run_checks] ||= Set.new
          options[:run_checks].merge checks
        end

        opts.on "-x", "--except Check1,Check2,etc", Array, "Skip the specified checks" do |skip|
          skip.each do |s|
            if s[0,5] != "Check"
              s = "Check" << s
            end

            options[:skip_checks] ||= Set.new
            options[:skip_checks] << s
          end
        end

        opts.separator ""
        opts.separator "Output options:"

        opts.on "-d", "--debug", "Lots of output" do
          options[:debug] = true 
        end

        opts.on "-f", 
          "--format TYPE", 
          [:pdf, :text, :html, :csv, :tabs], 
          "Specify output format. Default is text" do |type|

          type = "s" if type == :text
          options[:output_format] = ("to_" << type.to_s).to_sym
          end

        opts.on "--css-file CSSFile", "Specify CSS to use for HTML output" do |file|
          options[:html_style] = File.expand_path file
        end

        opts.on "-l", "--[no]-combine-locations", "Combine warning locations (Default)" do |combine|
          options[:combine_locations] = combine
        end

        opts.on "-m", "--routes", "Report controller information" do
          options[:report_routes] = true
        end

        opts.on "--message-limit LENGTH", "Limit message length in HTML report" do |limit|
          options[:message_limit] = limit.to_i
        end

        opts.on "-o", "--output FILE", "Specify file for output. Defaults to stdout" do |file|
          options[:output_file] = file
        end

        opts.on "--separate-models", "Warn on each model without attr_accessible" do
          options[:collapse_mass_assignment] = false
        end

        opts.on "-w", 
          "--confidence-level LEVEL", 
          ["1", "2", "3"], 
          "Set minimal confidence level (1 - 3)" do |level|

          options[:min_confidence] =  3 - level.to_i
        end

        opts.separator ""
        opts.separator "Configuration files:"

        opts.on "-c", "--config-file FILE", "Use specified configuration file" do |file|
          options[:config_file] = File.expand_path(file)
        end

        opts.on "-C", "--create-config [FILE]", "Output configuration file based on options" do |file|
          if file
            options[:create_config] = file
          else
            options[:create_config] = true
          end
        end

        opts.separator ""

        opts.on "-k", "--checks", "List all available vulnerability checks" do
          options[:list_checks] = true
        end

        opts.on "-v", "--version", "Show Brakeman version" do
          options[:show_version] = true
        end

        opts.on_tail "-h", "--help", "Display this message" do
          options[:show_help] = true
        end
      end

      if destructive
        parser.parse! args
      else
        parser.parse args
      end

      return options, parser
    end
  end
end
