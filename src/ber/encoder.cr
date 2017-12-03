module CrSNMP::BER

  class Encoder

    def self.encode_tag(tag : Tag, primitive = false) : Array(UInt8)
      if tag.index < 0
        raise "Invalid tag index"
      end

      first_byte = tag.cls.to_u8 << 6
      first_byte |= (primitive ? 0 : 1 << 5)

      if tag.index <= 30
        first_byte |= tag.index

        [first_byte]
      else
        first_byte |= 31

        [first_byte].concat encode_variable7bit(tag.index)
      end
    end

    def self.encode_length(length : Int32) : Array(UInt8)
      if len < 0
        raise "Invalid length"
      end

      if len <= 127
        [len.to_u8]
      else
        octets = [] of UInt8

        4.times do |i|
          octet = ((len >> (24 - (i * 8))) & 0xFF).to_u8

          if octet != 0 || !octets.empty?
            octets << octet
          end
        end

        [octets.size.to_u8 | 0x80_u8].concat octets
      end
    end

    def self.encode_int(number : Int64) : Array(UInt8)
      negative = int < 0
      uint = int.abs.to_u64

      target_size = 8

      8.times do |i|
        octet = (uint >> (56 - i * 8)) & 0xFF

        if octet == 0
          target_size -= 1
        else
          if (octet & 0x80) == 0x80 && !negative
            target_size += 1
          end

          break
        end
      end

      target_size = target_size > 8 ? 8 : target_size
      octets = [] of UInt8

      (target_size - 1).downto(0) do |i|
        octet = (int >> (i * 8)) & 0xFF

        octets << octet.to_u8
      end


      octets[0] |= (negative ? 1 << 7 : 0)

      octets
    end

    def self.encode_string(string : String) : Array(UInt8)
      string.bytes
    end

    def self.encode_oid(oid : OID) : Array(UInt8)
      if oid.fragments.size < 2
        raise "OID with less than 2 fragments"
      end

      combined = [oid.fragments[0].index * 40 + oid.fragments[1].index]
      combined.concat oid.fragments[2..-1].map { |f| f.index }

      combined.flat_map do |idx|
        encode_variable7bit idx
      end
    end

    def self.encode_bool(bool : Bool) : Array(UInt8)
      bool ? [0xFF_u8] : [0x00_u8]
    end

    private def self.encode_variable7bit(idx : Int32) : Array(UInt8)
      octets = [0_u8, 0_u8, 0_u8, 0_u8, 0_u8]
      remainders = [] of UInt8

      4.times do |ti|
        octet = (idx & 0xFF).to_u8
        idx = idx >> 8

        new_remainders = [] of UInt8

        remainders.each do |v|
          new_remainders << (((octet & 0x80) == 0x80) ? 1_u8 : 0_u8)
          octet = octet << 1
          octet |= v
        end

        new_remainders << (((octet & 0x80) == 0x80) ? 1_u8 : 0_u8)
        octet &= ~0x80
        remainders = new_remainders

        octets[4 - ti] = octet
      end

      remainders.each_index do |i|
        octets[0] |= (remainders[i] << i)
      end

      4.times do
        if octets[0] == 0
          octets.shift
        else
          octets.map_with_index! { |i, index| (index == octets.size - 1) ? i : i | 0x80 }
          break
        end
      end

      octets
    end

  end


end
