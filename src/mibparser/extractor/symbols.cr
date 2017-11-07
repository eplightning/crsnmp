require "./extracted_types"

module CrSNMP::MIBParser

  abstract class MIBSymbol
    property identifier : String
    getter full_id : String

    def initialize(@identifier, mib : String)
      @full_id = mib + "::" + @identifier
    end
  end

  class TypeDefinitionSymbol < MIBSymbol
    property definition : ExtractedType

    def initialize(@identifier, mib, @definition)
      super @identifier, mib
    end

  end

  class ObjectTypeSymbol < MIBSymbol
    property syntax : ExtractedType
    property access : String
    property status : String
    property description : String
    property oid : ExtractedOID
    property index : String | Nil

    def initialize(@identifier, mib, @syntax, @access, @status, @description, @oid, @index = "")
      super @identifier, mib
    end

  end

  class ObjectIdentifierSymbol < MIBSymbol
    property oid : ExtractedOID

    def initialize(@identifier, mib, @oid)
      super @identifier, mib
    end

  end
end
