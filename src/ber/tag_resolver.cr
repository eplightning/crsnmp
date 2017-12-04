require "../shared/tags"
require "./types"

include CrSNMP::Shared

module CrSNMP::BER

  class TagResolver
    def initialize(items : Hash(String, DataType) | DataType)
      @map = {} of Tag => Tuple(String, DataType)

      if items.is_a?(DataType)
        items.tags.each do |tag|
          if @map.has_key? tag
            raise "Duplicate tag"
          else
            @map[tag] = {"item",items}
          end
        end
      else
        items.each do |k, v|
          v.tags.each do |tag|
            if @map.has_key? tag
              raise "Duplicate tag"
            else
              @map[tag] = {k,v}
            end
          end
        end
      end
    end

    def resolve?(tag : Tag) : Tuple(String, DataType) | Nil
      @map[tag]?
    end
  end

end
