module CrSNMP::BER

  class TagResolver
    def initialize(items : Hash(String, DataType) | DataType)
      @map = {} of Tag => Tuple(String, DataType)

      if items.is_a?(DataType)
        items.tags.each do |tag|
          if @map.has_key? tag
            raise "Duplicate tag"
          else
            @map[tag] = {"item",v}
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

  enum TaggingMode
    Implicit
    Explicit
  end

  enum TagClass : UInt8
    Universal
    Application
    ContextSpecific
    Private
  end

  struct Tag
    getter index : Int32
    getter cls : TagClass

    def initialize(@index, @cls)
    end

    def ==(other : Tag) : Bool
      return other.index == @index && other.cls == @cls;
    end

    def !=(other : Tag) : Bool
      return other.index != @index || other.cls != @cls;
    end
  end

end
