# -*- mode:ruby; coding:utf-8 -*-

require 'atig/db/listenable'
require 'atig/db/groonga'

module Atig
  module Db
    class Followings
      include Listenable
      include GroongaUtil

      def initialize(name)
        name.gsub!(/\^/, '@')
        @db = Groonga[name]
        @mutex = Mutex.new

        unless @db then
          Groonga::Schema.create_table(name, type: :hash) do |table|
            table.integer64(:user_id)
            table.text(:screen_name)
            table.bool(:protected)
            table.bool(:only)
            table.text(:data)
          end
          @db = Groonga[name]
        end

        @users = []
        @on_invalidated = lambda{}
      end

      def size
        @db.size
      end

      def empty?
        @db.size == 0
      end

      def invalidate
        @on_invalidated.call
      end

      def on_invalidated(&f)
        @on_invalidated = f
      end

      def users
        @db.records.map do |row|
          _load row.data
        end
      end

      def may_notify(mode, xs)
        unless xs.empty? then
          notify mode, xs
        end
      end

      def update(users)
        may_notify :join, users.select{ |u|
          @db.select do |r| r.screen_name == u.screen_name end.empty?
        }

        # TODO: refactor this
        names = users.map{ |u| u.screen_name }
        part = @db.records.reject do |r|
          names.include?(r.screen_name)
        end
        arr = part.map do |r| _load(r.data) end
        may_notify :part, arr
        part.each do |r| @db.delete(r._key) end

        may_notify :mode, users.select{|u|
          @db.select do |r|
            (r.screen_name == u.screen_name) & (
            (r.protected != u.protected) | (r.only != u.only))
          end.empty?
        }

        users.each do |user|
          row = @db.select do |r| r.user_id == user.id end.first
          if row then
            row.screen_name = user.screen_name
            row.protected   = user.protected
            row.only        = user.only
            row.data        = _dump(user)
          else
            @db.add(user.id.to_s, user_id: user.id,
              screen_name: user.screen_name,
              protected:   user.protected,
              only:        user.only,
              data:        _dump(user)
            )
          end
        end
      end

      def find_by_screen_name(name)
        row = @db.select do |r| r.screen_name == name end.records.first
        _load(row.data)
      end

      def include?(user)
        ! @db[user.id.to_s].nil?
      end

      def transaction(&f)
        @mutex.synchronize {
          f.call self
        }
      end

    end
  end
end
