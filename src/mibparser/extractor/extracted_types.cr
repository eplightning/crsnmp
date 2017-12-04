require "../../shared/oid"
require "../../shared/tags"

include CrSNMP::Shared

module CrSNMP::MIBParser

  # import
  struct ExtractedImport
    property symbol_names : Array(String)
    property mib : String

    def initialize(@mib, @symbol_names)
    end
  end

  # sizes
  abstract struct ExtractedSize
  end

  struct RangeExtractedSize < ExtractedSize
    property left : Int64
    property right : Int64

    def initialize(@left, @right)
    end

    def to_s
      "Range(Left: " + @left.to_s + ", Right: " + @right.to_s + ")"
    end
  end

  struct NumberExtractedSize < ExtractedSize
    property number : Int64

    def initialize(@number)
    end

    def to_s
      "Number(" + @number.to_s + ")"
    end
  end

  # types
  abstract class ExtractedType
    property id : Int32 | Nil
    property tag : TagClass
    property tag_type : TaggingMode | Nil
    property size : ExtractedSize | Nil
    property range : ExtractedSize | Nil

    def initialize(@id = nil, tag = nil, tag_type = nil, @size = nil, @range = nil)
      @tag = case tag
      when "APPLICATION"
        TagClass::Application
      when "UNIVERSAL"
        TagClass::Universal
      when "CONTEXT-SPECIFIC"
        TagClass::ContextSpecific
      when "PRIVATE"
        TagClass::Private
      else
        TagClass::ContextSpecific
      end

      @tag_type = case tag_type
      when "IMPLICIT"
        TaggingMode::Implicit
      when "EXPLICIT"
        TaggingMode::Explicit
      else
        nil
      end
    end
  end

  class UnknownExtractedType < ExtractedType
    property definition : String

    def initialize(@definition)
      super nil
    end

    def to_s
      @definition
    end
  end

  class SymbolExtractedType < ExtractedType
    property symbol_name : String

    def initialize(@symbol_name, @id = nil, tag = nil, tag_type = nil, @size = nil, @range = nil)
      super @id, tag, tag_type, @size, @range
    end
  end

  class PrimitiveExtractedType < ExtractedType
    enum Primitive
      OctetString
      Integer
      ObjectIdentifier
      Null
      Boolean
    end
    property primitive : Primitive

    def initialize(primitive, @id = nil, tag = nil, tag_type = nil, @size = nil, @range = nil)
      super @id, tag, tag_type, @size, @range

      @primitive = case primitive
      when "OCTET STRING"
        Primitive::OctetString
      when "INTEGER"
        Primitive::Integer
      when "OBJECT IDENTIFIER"
        Primitive::ObjectIdentifier
      when "BOOLEAN"
        Primitive::Boolean
      else
        Primitive::Null
      end
    end
  end

  class ChoiceExtractedType < ExtractedType
    property choices : Hash(String, ExtractedType)

    def initialize(@choices, @id = nil, tag = nil, tag_type = nil, @size = nil, @range = nil)
      super @id, tag, tag_type, @size, @range
    end
  end

  class SequenceExtractedType < ExtractedType
    property items : Hash(String, ExtractedType)

    def initialize(@items, @id = nil, tag = nil, tag_type = nil, @size = nil, @range = nil)
      super @id, tag, tag_type, @size, @range
    end
  end

  class SequenceOfExtractedType < ExtractedType
    property item : ExtractedType

    def initialize(@item, @id = nil, tag = nil, tag_type = nil, @size = nil, @range = nil)
      super @id, tag, tag_type, @size, @range
    end
  end

  # OID + fragments
  abstract struct ExtractedOIDFragment
  end

  struct ExtractedOIDNumber < ExtractedOIDFragment
    property number : Int32

    def initialize(@number)
    end
  end

  struct ExtractedOIDSymbol < ExtractedOIDFragment
    property symbol_name : String

    def initialize(@symbol_name)
    end
  end

  struct ExtractedOIDForwardSymbol < ExtractedOIDFragment
    property symbol_name : String
    property number : Int32

    def initialize(@symbol_name, @number)
    end
  end

  struct ExtractedOID
    property fragments : Array(ExtractedOIDFragment)

    def initialize(@fragments = [] of ExtractedOIDFragment)
    end
  end


end
