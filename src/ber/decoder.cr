module CrSNMP::BER

  class Decoder

    def self.decode_tag(bytes : Array(UInt8)) : Tuple(Int32, Tag, Bool)
      {0, Tag.new(0, TagClass::Application), true}
    end

    def self.decode_length(bytes : Array(UInt8)) : Tuple(Int32, Int32)
      {0, 0}
    end

    def self.decode_int(bytes : Array(UInt8)) : Int64
      0
    end

    def self.decode_string(bytes : Array(UInt8)) : String
      ""
    end

    def self.decode_oid(bytes : Array(UInt8)) : OID
      OID.new nil, 0
    end

    def self.decode_bool(bytes : Array(UInt8)) : Bool
      bytes[0] != 0
    end

  end

end
