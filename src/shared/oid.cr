module CrSNMP::Shared

  struct OIDFragment
    getter index : Int32

    def ==(other : OIDFragment)
      @index == other.index
    end

    def initialize(@index)
    end
  end

  class OID
    getter fragments : Array(OIDFragment)

    def ==(other : OID)
      if @fragments.size == other.fragments.size
        equal = true
        fragments.each_index do |i|
          equal &= fragments[i] == other.fragments[i]
        end
        equal
      else
        false
      end
    end

    def initialize(parent : OID | Nil, index : Int32 | Array(OIDFragment))
      if !parent.nil?
        @fragments = parent.fragments.dup
      else
        @fragments = [] of OIDFragment
      end

      if index.is_a?(Array(OIDFragment))
        @fragments.concat index
      else
        @fragments << OIDFragment.new(index)
      end
    end

    def self.from_string(input : String) : OID
      fragments = input.split(".").map do |v|
        OIDFragment.new v.to_i32
      end

      OID.new nil, fragments
    end

    def to_s
      @fragments.join(".") do |frag|
        frag.index.to_s
      end
    end

    def to_s(io : IO) : Nil
      inspect(io)
    end
  end

end
