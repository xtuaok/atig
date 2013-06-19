
require 'atig/command/command'
require 'atig/command/info'

module Atig
  module Command
    class Mute < Atig::Command::Command
      def command_name
        return %w/mute/
      end

      def action(target, mesg, command, args)
        if args.empty?
          yield  "/me #{command_name} <text|client|user> <REGEXP>"
          return
        end
        mode = args[0]
        regexp = args[1]
        regexp = nil if regexp == ""
        if regexp
          begin
            tmp = Regexp.new(regexp)
          rescue
            gateway[target].notify "Failed to set regexp for #{mode}: #{$!}"
            return
          end
        end
        case mode
        when 'text'
          @db.mute[:text] = regexp
        when 'user'
          @db.mute[:user] = regexp
        when 'client'
	  @db.mute[:client] = regexp
        else
          gateway[target].notify "No such mute mode: #{mode}"
          return
        end
        gateway[target].notify "Set mute[#{mode}] /#{regexp}/"
      end
    end
  end
end
