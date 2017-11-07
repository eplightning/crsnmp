module CrSNMP::MIBParser

  # import
  struct ExtractedImport
    property symbol_names : Array(String)
    property mib : String

    def initialize(@mib, @symbol_names)
    end
  end

  # types
  abstract struct ExtractedType
    abstract struct Size
    end

    property attribute : String | Nil
    property implicit : Bool
    property size : Size | Nil
    property range : Size | Nil

    def initialize(@attribute = nil, @implicit = false, @size = nil, @range = nil)
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

    def initialize(@symbol_name, @attribute = nil, @implicit = false, @size = nil, @range = nil)
      super @attribute, @implicit, @size, @range
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

    def initialize(@primitive, @attribute = nil, @implicit = false, @size = nil, @range = nil)
      super @attribute, @implicit, @size, @range
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
