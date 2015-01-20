# -*- mode:ruby; coding:utf-8 -*-
require 'atig/db/listenable'
require 'atig/db/groonga'
require 'atig/db/roman'
require 'base64'

class OpenStruct
  def id; method_missing(:id) end
end

module Atig
  module Db
    class Statuses
      include Listenable
      include GroongaUtil

      Size = 400

      def initialize(name)
        name.gsub!(/\^/, '@')
        @db = Groonga[name]
        @iddb = Groonga['Id']
        @roman = Roman.new
        @mutex = Mutex.new
        unless @db then
          Groonga::Schema.create_table(name, type: :hash) do |table|
            table.integer64(:id)
            table.text(:status_id)
            table.text(:tid)
            table.text(:sid)
            table.text(:screen_name)
            table.text(:user_id)
            table.integer64(:created_at)
            table.text(:data)
          end
          @db = Groonga[name]
       end
       unless @iddb then
          Groonga::Schema.create_table('Id', type: :hash) do |table|
            table.text(:screen_name)
            table.integer64(:count)
          end
          @iddb = Groonga['Id']
        end
      end

      def add(opt)
          id  = opt[:status].id
          return if @db[id.to_s]

          screen_name = opt[:user].screen_name
          sum = @iddb.records.inject(0) do |sum, r| sum + r.count end
          record = @iddb[screen_name]
          count = record ? record.count : 0
          entry = OpenStruct.new opt.merge(tid: @roman.make(sum),
                                           sid: "#{screen_name}:#{@roman.make(count)}")

          attr = {
           id: id,
           status_id: id.to_s,
           tid: entry.tid,
           sid: entry.sid,
           screen_name: screen_name,
           user_id: opt[:user].id,
           created_at: Time.parse(opt[:status].created_at).to_i,
           data: _dump(entry)
          }
          @db.add(id.to_s, attr)
          @iddb.add(screen_name, screen_name: screen_name, count: count + 1)
          notify entry
      end

      def find_all(opt={})
        @db.sort([['created_at', :desc]], limit: opt.fetch(:limit, 20)).map do |r| _load(r.data) end 
      end

      def find_by_screen_name(name, opt={})
        expr = lambda {|r| r.screen_name == name }
        find expr, opt
      end

      def find_by_user(user, opt={})
        expr = lambda {|r| r.user_id == user.id }
        find expr, opt
      end

      def find_by_tid(tid)
        expr = lambda {|r| r.tid == tid }
        find(expr).first
      end

      def find_by_sid(sid)
        expr = lambda {|r| r.sid == sid }
        find(expr).first
      end

      def find_by_status_id(id)
        expr = lambda {|r| r.status_id == id }
        find(expr).first
      end

      def find_by_id(id)
        @db[id.to_s]
      end

      def remove_by_id(id)
        @db.delete(id.to_s)
      end

      def transaction(&f)
        @mutex.synchronize {
          f.call self
        }
      end

      def cleanup
        return if @db.size < Size - 1
        record = @db.select.sort([['created_at', :desc]], offset: (Size - 1)) .first
        if record
          records = @db.select do |r| r.created_at < record.created_at end
          records.each do |r| @db.delete(r._key) end
        end
      end

      private
      def find(expr,opt={},&f)
        records = @db.select do |r| expr.call(r) end.sort([['created_at',:desc]],limit: opt.fetch(:limit,20))
        records.map do|r| _load(r.data) end
      end

      def xfind(lhs,rhs, opt={},&f)
        records = @db.select do |r|
          r.send(lhs) == rhs
        end.sort([['created_at', :desc]], limit: opt.fetch(:limit, 20)) 
        records.map do |r| _load(r.data) end
      end
    end
  end
end
