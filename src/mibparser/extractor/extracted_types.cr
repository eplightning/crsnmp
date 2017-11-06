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

    property attributes : Array(String)
    property implicit : Bool
    property size : Size | Nil
    property range : Size | Nil

    def initialize(@attributes = [] of String, @implicit = false, @size = nil, @range = nil)
    end
  end

  struct UnknownExtractedType < ExtractedType
    property definition : String

    def initialize(@definition)
      super [] of String
    end

    def to_s
      @definition
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

    def initialize(@fragments)
    end
  end


end
