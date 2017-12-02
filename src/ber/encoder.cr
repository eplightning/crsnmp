module CrSNMP::BER

  class Encoder
    def self.encode_tag(tag : Tag, primitive = false) : Array(UInt8)
      [] of UInt8
    end

    def self.encode_length(length : Int32) : Array(UInt8)
      [] of UInt8
    end

    def self.encode_int(number: Int64) : Array(UInt8)
      [] of UInt8
    end

    def self.encode_string(string: String) : Array(UInt8)
      [] of UInt8
    end

    def self.encode_oid(oid: OID) : Array(UInt8)
      [] of UInt8
    end

    def self.encode_bool(bool: Bool) : Array(UInt8)
      [] of UInt8
    end

  end


end
