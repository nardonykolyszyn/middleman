require "guard"
require "guard/guard"
require "rbconfig"

if RbConfig::CONFIG['host_os'].downcase =~ %r{mingw}
  require "win32/process"
end
  
module Middleman
  module Guard
    def self.add_guard(&block)
      @additional_guards ||= []
      @additional_guards << block
    end
  
    def self.start(options={}, livereload={})
      options_hash = ""
      options.each do |k,v|
        options_hash << ", :#{k} => '#{v}'"
      end
    
      guardfile_contents = %Q{
        guard 'middleman'#{options_hash} do 
          watch("config.rb")
          watch(%r{^lib/^[^\.](.*)\.rb$})
        end
      }
    
      (@additional_guards || []).each do |block|
        result = block.call(options, livereload)
        guardfile_contents << result unless result.nil?
      end
    
      begin
        ::Guard.start({ :guardfile_contents => guardfile_contents })
      rescue Interrupt
        ::Guard.stop
      end
    end
  end
end

module Guard
  class Middleman < Guard
    def initialize(watchers = [], options = {})
      super
      @options = options
    end
    
    def start
      server_start
    end
  
    def run_on_changes(paths)
      server_stop
      server_start
    end

  private
    def server_start
      @server_job = fork do
        ::Middleman.start_server(@options)
      end
    end
  
    def server_stop
      puts "== The Middleman is shutting down"
      Process.kill("KILL", @server_job)
      Process.wait @server_job
      @server_job = nil
      # @server_options[:app] = nil
    end
  end
end