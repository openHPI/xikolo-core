# frozen_string_literal: true

class TeamCity
  class Log
    def self.running?
      ENV.include? 'TEAMCITY_PROJECT_NAME'
    end

    def self.block(name)
      publish('blockOpened', name:)
      yield
      publish 'blockClosed', name:
    end

    def self.publish(message_name, args)
      return unless running?

      args = [] << message_name << escaped_array_of(args)
      args = args.flatten.compact

      puts "##teamcity[#{args.join(' ')}]"
    end
    private_class_method :publish

    def self.escape(string)
      string.gsub(/(\||'|\r|\n|\u0085|\u2028|\u2029|\[|\])/, '|$1')
    end
    private_class_method :escape

    def self.escaped_array_of(args)
      return [] if args.nil?

      if args.is_a? Hash
        args.map {|key, value| "#{key}='#{escape value.to_s}'" }
      else
        "'#{escape args}'"
      end
    end
    private_class_method :escaped_array_of
  end
end
