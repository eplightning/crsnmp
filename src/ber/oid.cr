module CrSNMP::BER

  struct OIDFragment
    getter index : Int32

    def initialize(@index)
    end
  end

  class OID
    getter fragments : Array(OIDFragment)

    def initialize(parent : OID | Nil, index : Int32)
      if !parent.nil?
        @fragments = parent.fragments.dup
      else
        @fragments = [] of OIDFragment
      end

      fragments << OIDFragment.new(index)
    end

    def to_s
      @fragments.join(".") do |frag|
        frag.index.to_s
      end
    end
  end

end
