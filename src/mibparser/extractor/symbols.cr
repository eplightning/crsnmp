require "./extracted_types"

module CrSNMP::MIBParser

  abstract class MIBSymbol
    property identifier : String

    def initialize(@identifier)
    end
  end

  class TypeDefinitionSymbol < MIBSymbol
    property definition : ExtractedType

    def initialize(@identifier, @definition)
      super @identifier
    end

  end

  class ObjectTypeSymbol < MIBSymbol
    property syntax : ExtractedType
    property access : String
    property status : String
    property description : String
    property oid : ExtractedOID
    property index : String | Nil

    def initialize(@identifier, @syntax, @access, @status, @description, @oid, @index = "")
      super @identifier
    end

  end

  class ObjectIdentifierSymbol < MIBSymbol
    property oid : ExtractedOID

    def initialize(@identifier, @oid)
      super @identifier
    end

  end
end
