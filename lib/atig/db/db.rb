# -*- mode:ruby; coding:utf-8 -*-

require 'atig/db/groonga'
require 'atig/db/followings'
require 'atig/db/statuses'
require 'atig/db/lists'
require 'atig/util'
require 'thread'
require 'set'
require 'fileutils'

module Atig
  module Db
    class Db
      include Util
      attr_reader :followings, :statuses, :dms, :lists, :noretweets
      attr_accessor :me
      VERSION = 4

      def initialize(context, opt={})
        @log        = context.log
        @me         = opt[:me]
        @tmpdir     = opt[:tmpdir]

        Groonga::Database.open dir rescue Groonga::Database.create(path: dir)
        @followings = Followings.new 'Following'
        @statuses   = Statuses.new   'Status'
        @dms        = Statuses.new   'DirectMessage'
        @lists      = Lists.new      'Lists@%s'
        @noretweets = Array.new

        log :info, "initialize"
      end

      def dir
        dir = File.expand_path "~/.atig/db/#{@me.screen_name}/"
        log :debug, "db(groonga) = #{dir}"
        FileUtils.mkdir_p dir
        File.expand_path "atig.#{VERSION}.db", dir
      end

      def transaction(&f)
        f.call self
      end

      def cleanup
        @statuses.transaction do |d| d.cleanup end
        @dms.transcation do |d| d.cleanup end
      end
    end
  end
end
