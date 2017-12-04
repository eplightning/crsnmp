require "./extracted_types"
require "../../shared/oid"

include CrSNMP::Shared

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
    property object_type : ObjectType
    property syntax : ExtractedType
    property oid : ExtractedOID
    property index : String | Nil

    def initialize(@identifier, mib, @syntax, access, status, description, @oid, @index = "")
      super @identifier, mib

      access_val = case access
      when "read-only"
        ObjectType::Access::ReadOnly
      when "read-write"
        ObjectType::Access::ReadWrite
      when "write-only"
        ObjectType::Access::WriteOnly
      else
        ObjectType::Access::NotAccessible
      end

      status_val = case status
      when "mandatory"
        ObjectType::Status::Mandatory
      when "optional"
        ObjectType::Status::Optional
      when "obsolete"
        ObjectType::Status::Obsolete
      else
        ObjectType::Status::Deprecated
      end

      @object_type = ObjectType.new access_val, status_val, description
    end

  end

  class ObjectIdentifierSymbol < MIBSymbol
    property oid : ExtractedOID

    def initialize(@identifier, mib, @oid)
      super @identifier, mib
    end

  end
end
