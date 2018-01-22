require "./ber/values"
require "./shared/oid"

include CrSNMP::Shared

module CrSNMP

  abstract class DataSource
    abstract def get(oid : OID) : BER::DataValue
    abstract def set(oid : OID, value : BER::DataValue)
    abstract def supports?(oid : OID) : Bool
  end

  class DataManager

    def initialize
      @sources = [] of DataSource
    end

    def register_source(src : DataSource)
      @sources << src
    end

    def get(oid : OID) : BER::DataValue | Nil
      source = first_supported oid

      if !source.nil?
        source.get oid
      else
        nil
      end
    end

    def set(oid : OID, value : BER::DataValue) : Bool
      source = first_supported oid

      if !source.nil?
        source.set oid, value
        true
      else
        false
      end
    end

    private def first_supported(oid : OID) : DataSource | Nil
      @sources.find do |v|
        v.supports? oid
      end
    end

  end

end
