# -*- mode:ruby; coding:utf-8 -*-

require 'groonga'

module Atig
  module Db
    module GroongaUtil
      def _dump(obj)
        [Marshal.dump(obj)].pack('m')
      end

      def _load(text)
        if text == nil then
          nil
        else
          Marshal.load(text.unpack('m').first)
        end
      end
    end
  end
end
