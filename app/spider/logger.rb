module Spider
  class Logger < ActiveSupport::Logger
    def initialize
      file = File.open("#{Rails.root}/log/spider.log", 'a')
      super file
    end
    def info(*arg)
      super arg.join(' ')
    end
    def format_message(severity, timestamp, progname, msg)
      "#{timestamp.to_formatted_s(:db)} #{severity} #{progname} #{msg}\n"
    end      
  end
end
