require "./ber/values"
require "./shared/oid"

include CrSNMP::Shared

module CrSNMP

  abstract class DataSource
    abstract def get(oid : OID) : BER::DataValue | Nil
    abstract def set(oid : OID, value : BER::DataValue) : Bool
  end

  class DataManager

    def get(oid : OID) : BER::DataValue | Nil
      nil
    end

    def set(oid : OID, value : BER::DataValue) : Bool
      true
    end

  end

end
