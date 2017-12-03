module CrSNMP::BER

  class Decoder

    def self.decode_tag(bytes : Array(UInt8)) : Tuple(Int32, Tag, Bool)
      if bytes.size < 1
        raise "Cannot read empty tag"
      end

      read = 1
      first_byte = bytes[0]
      cls = (first_byte >> 6) & 3
      pc = (first_byte >> 5) & 1
      id = first_byte & 31

      if id == 31
        vid = decode_variable7bit(bytes[1..-1])
        id = vid[1]
        read += vid[0]
      end

      {read, Tag.new(id.to_i32, TagClass.new(cls)), pc != 1}
    end

    def self.decode_length(bytes : Array(UInt8)) : Tuple(Int32, Int32)
      if bytes.size < 1
        raise "Length needs to have at least 1 byte"
      end

      first_byte = bytes[0]

      if first_byte > 127
        first_byte = first_byte & 0x7F

        if first_byte + 1 > bytes.size
          raise "Not enough length bytes to read"
        end

        if first_byte > 4
          raise "Length can be 32-bit at most"
        end

        output = 0_u32

        start = first_byte.to_i32 - 1
        i = start

        while i >= 0
          shift = (start - i) * 8
          output |= bytes[i + 1].to_u32 << shift
          i = i - 1
        end

        {first_byte.to_i32, output.to_i32}
      else
        {1, first_byte.to_i32}
      end
    end

    def self.decode_int(bytes : Array(UInt8)) : Int64
      if bytes.size > 8
        raise "Integers longer than 64-bit are not supported"
      end

      negative = (bytes[0] & 0x80 == 0x80)
      unsigned = negative ? 0xFFFFFFFFFFFFFFFF_u64 : 0_u64;

      8.downto(9 - bytes.size) do |i|
        unsigned = (unsigned << 8) | bytes[8 - i]
      end

      unsigned.to_i64
    end

    def self.decode_string(bytes : Array(UInt8)) : String
      slice = Slice.new bytes.to_unsafe, bytes.size
      String.new slice, "ASCII", :skip
    end

    def self.decode_oid(bytes : Array(UInt8)) : OID
      if bytes.size < 1
        raise "OID needs to have at least one byte"
      end

      fragments = [] of OIDFragment
      numbers = [] of Int32

      while bytes.size > 0
        decoded = decode_variable7bit(bytes)
        bytes = bytes[decoded[0]..-1]
        numbers << decoded[1]
      end

      first = numbers[0]
      fragments << OIDFragment.new (first / 40)
      fragments << OIDFragment.new (first % 40)
      numbers.shift

      other = numbers.map do |i|
        OIDFragment.new i
      end

      fragments.concat other

      OID.new nil, fragments
    end

    def self.decode_bool(bytes : Array(UInt8)) : Bool
      bytes[0] != 0
    end

    private def self.decode_variable7bit(bytes : Array(UInt8)) : Tuple(Int32, Int32)
      if bytes.size < 1
        raise "Cannot read variable 7-bit number from empty array"
      end

      octets = [] of UInt8

      i = 0
      while (bytes[i] & 0x80) == 0x80
        octets << (bytes[i] & 0x7F)
        i += 1

        if bytes.size < 1 + i
          raise "Cannot read enough bytes for variable 7-bit number"
        end
      end

      if bytes.size < 1 + i
        raise "Cannot read final byte for variable 7-bit number"
      end

      if i > 4
        raise "Variable 7bit number with more bytes than 5 is not supported"
      end

      octets << bytes[i]

      output = 0_u32

      (octets.size - 1).downto(0) do |octeti|
        octet = octets[octeti].to_u32

        output |= (octet << ((octets.size - 1 - octeti) * 7))
      end

      {i + 1, output.to_i32}
    end

  end

end
