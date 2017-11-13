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
    enum Access
      ReadOnly
      ReadWrite
      WriteOnly
      NotAccessible
    end

    enum Status
      Mandatory
      Optional
      Obsolete
      Deprecated
    end

    property syntax : ExtractedType
    property access : Access
    property status : Status
    property description : String
    property oid : ExtractedOID
    property index : String | Nil

    def initialize(@identifier, mib, @syntax, access, status, @description, @oid, @index = "")
      super @identifier, mib

      @access = case access
      when "read-only"
        Access::ReadOnly
      when "read-write"
        Access::ReadWrite
      when "write-only"
        Access::WriteOnly
      else
        Access::NotAccessible
      end

      @status = case status
      when "mandatory"
        Status::Mandatory
      when "optional"
        Status::Optional
      when "obsolete"
        Status::Obsolete
      else
        Status::Deprecated
      end
    end

  end

  class ObjectIdentifierSymbol < MIBSymbol
    property oid : ExtractedOID

    def initialize(@identifier, mib, @oid)
      super @identifier, mib
    end

  end
end
