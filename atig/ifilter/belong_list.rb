#! /opt/local/bin/ruby -w
# -*- mode:ruby; coding:utf-8 -*-

module Atig
  module IFilter
    module BelongList
      def self.call(status)
        if status.belongs == nil || status.belongs.empty? then
          status
        else
          status.merge :text => "#{status.text} \x0310[#{status.belongs.join(",")}]\x0F"
        end
      end
    end
  end
end
