require "../ber/values"
require "../shared/oid"
require "../shared/tags"

include CrSNMP::Shared

module CrSNMP::DataSources

  class MemoryIntegerDataSource < CrSNMP::DataSource

    def initialize(@oid : OID, @value = 0_i64)
    end

    def get(oid : OID) : BER::DataValue
      BER::IntegerDataValue.new @value
    end

    def set(oid : OID, value : BER::DataValue)
      if value.is_a?(BER::IntegerDataValue)
        puts "Setting value"
        @value = value.val
      end
    end

    def supports?(oid : OID) : Bool
      return oid == @oid
    end

  end

end
