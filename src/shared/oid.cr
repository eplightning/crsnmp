module CrSNMP::Shared

  struct OIDFragment
    getter index : Int32

    def initialize(@index)
    end
  end

  class OID
    getter fragments : Array(OIDFragment)

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

    def to_s
      @fragments.join(".") do |frag|
        frag.index.to_s
      end
    end
  end

end
