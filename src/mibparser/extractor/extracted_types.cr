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
  end

  struct NumberExtractedSize < ExtractedSize
    property number : Int64

    def initialize(@number)

    end
  end

  # types
  abstract struct ExtractedType
    enum Tag
      Application
      Universal
      ContextSpecific
      Private
    end

    enum TagType
      Default
      Implicit
      Explicit
    end

    property id : Int32 | Nil
    property tag : Tag | Nil
    property tag_type : TagType
    property size : ExtractedSize | Nil
    property range : ExtractedSize | Nil

    def initialize(@id = nil, tag = nil, tag_type = nil, @size = nil, @range = nil)
      @tag = case tag
      when "APPLICATION"
        Tag::Application
      when "UNIVERSAL"
        Tag::Universal
      when "CONTEXT-SPECIFIC"
        Tag::ContextSpecific
      when "PRIVATE"
        Tag::Private
      else
        nil
      end

      @tag_type = case tag_type
      when "IMPLICIT"
        TagType::Implicit
      when "EXPLICIT"
        TagType::Explicit
      else
        TagType::Default
      end
    end
  end

  struct UnknownExtractedType < ExtractedType
    property definition : String

    def initialize(@definition)
      super nil
    end

    def to_s
      @definition
    end
  end

  struct SymbolExtractedType < ExtractedType
    property symbol_name : String

    def initialize(@symbol_name, @id = nil, tag = nil, tag_type = nil, @size = nil, @range = nil)
      super @id, tag, tag_type, @size, @range
    end
  end

  struct PrimitiveExtractedType < ExtractedType
    enum Primitive
      OctetString
      Integer
      ObjectIdentifier
      Null
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
      else
        Primitive::Null
      end
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
