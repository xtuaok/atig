# -*- mode:ruby; coding:utf-8 -*-
require 'atig/channel/channel'

module Atig
  module Channel
    class Retweet < Atig::Channel::Channel
      def initialize(context, gateway, db)
        super

        db.statuses.find_all(:limit=>50).reverse_each {|entry|
          next if db.mute[:user] and /#{db.mute[:user]}/ =~ entry.status.user.screen_name
          next if db.mute[:text] and /#{db.mute[:text]}/ =~ entry.status.text
          next if db.mute[:client] and /#{db.mute[:client]}/ =~ entry.status.source

          message entry
        }

        db.statuses.listen {|entry|
          next if db.mute[:user] and /#{db.mute[:user]}/ =~ entry.status.user.screen_name
          next if db.mute[:text] and /#{db.mute[:text]}/ =~ entry.status.text
          next if db.mute[:client] and /#{db.mute[:client]}/ =~ entry.status.source

          message entry
        }
      end

      def channel_name; "#retweet" end

      def message(entry)
        if entry.status.retweeted_status then
          @channel.message entry
        end
      end
    end
  end
end
