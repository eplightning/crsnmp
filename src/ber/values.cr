require "../shared/oid"
require "../shared/tags"
require "./restrictions"
require "./types"

include CrSNMP::Shared

module CrSNMP::BER

  abstract struct DataValue
    property tag : Tag

    def initialize(@tag)
    end

    abstract def passes_restrictions(restrictions : Restrictions) : String | Nil
  end

  struct SequenceDataValue < DataValue
    struct Item
      getter data : DataValue
      getter name : String | Nil

      def initialize(@data, @name = nil)
      end

      def to_s
        @name
      end
    end

    getter items : Array(Item)

    def initialize(@items, tag : Tag | Nil = nil)
      super tag.nil? ? SequenceDataType.universal_tag : tag
    end

    def passes_restrictions(restrictions : Restrictions) : String | Nil
      nil
    end
  end

  struct IntegerDataValue < DataValue
    getter val : Int64

    def initialize(val : Int32 | Int64, tag : Tag | Nil = nil)
      super tag.nil? ? IntegerDataType.universal_tag : tag
      @val = val.to_i64
    end

    def passes_restrictions(restrictions : Restrictions) : String | Nil
      valuer = restrictions.value

      if !valuer.nil?
        if valuer.is_a?(RangeRestriction)
          if valuer.left > @val || valuer.right < @val
            return "Int range restriction not passed"
          end
        elsif valuer.is_a?(NumberRestriction)
          if valuer.number != @val
            return "Int num restriction not passed"
          end
        end
      end

      nil
    end
  end

  struct NullDataValue < DataValue
    def initialize(tag : Tag | Nil = nil)
      super tag.nil? ? NullDataType.universal_tag : tag
    end

    def passes_restrictions(restrictions : Restrictions) : String | Nil
      nil
    end
  end

  struct OctetStringDataValue < DataValue
    getter val : Array(UInt8)

    def initialize(@val, tag : Tag | Nil = nil)
      super tag.nil? ? OctetStringDataType.universal_tag : tag
    end

    def to_s
      slice = Slice.new val.to_unsafe, val.size
      String.new slice, "ASCII", :skip
    end

    def passes_restrictions(restrictions : Restrictions) : String | Nil
      sizer = restrictions.size

      if !sizer.nil?
        if sizer.is_a?(RangeRestriction)
          if sizer.left > @val.size || sizer.right < @val.size
            return "Size range restriction not passed"
          end
        elsif sizer.is_a?(NumberRestriction)
          if sizer.number != @val.size
            return "Size num restriction not passed"
          end
        end
      end

      nil
    end
  end

  struct BooleanDataValue < DataValue
    getter val : Bool

    def initialize(@val, tag : Tag | Nil = nil)
      super tag.nil? ? BooleanDataType.universal_tag : tag
    end

    def passes_restrictions(restrictions : Restrictions) : String | Nil
      nil
    end
  end

  struct OIDDataValue < DataValue
    getter val : OID

    def initialize(@val, tag : Tag | Nil = nil)
      super tag.nil? ? OIDDataType.universal_tag : tag
    end

    def passes_restrictions(restrictions : Restrictions) : String | Nil
      nil
    end
  end

end
