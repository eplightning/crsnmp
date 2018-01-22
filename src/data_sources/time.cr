require "../ber/values"
require "../shared/oid"
require "../shared/tags"

include CrSNMP::Shared

module CrSNMP::DataSources

  class TimeDataSource < CrSNMP::DataSource

    def initialize(@oid : OID)
    end

    def get(oid : OID) : BER::DataValue
      BER::IntegerDataValue.new Time.new.epoch, Tag.new(2, TagClass::Application)
    end

    def set(oid : OID, value : BER::DataValue)
      puts "not setting time"
    end

    def supports?(oid : OID) : Bool
      return oid == @oid
    end

  end

end
