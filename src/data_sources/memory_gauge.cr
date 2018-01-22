require "../ber/values"
require "../shared/oid"
require "../shared/tags"

include CrSNMP::Shared

module CrSNMP::DataSources

  class MemoryGaugeDataSource < CrSNMP::DataSource

    def initialize(@oid : OID, @value = 0_i64)
    end

    def get(oid : OID) : BER::DataValue
      BER::IntegerDataValue.new @value, Tag.new(2, TagClass::Application)
    end

    def set(oid : OID, value : BER::DataValue)
      if value.is_a?(BER::IntegerDataValue)
        @value = value.val
      end
    end

    def supports?(oid : OID) : Bool
      return oid == @oid
    end

  end

end
