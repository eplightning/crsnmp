module CrSNMP::Shared

  enum TaggingMode
    Implicit
    Explicit
  end

  enum TagClass : UInt8
    Universal
    Application
    ContextSpecific
    Private
  end

  struct Tag
    getter index : Int32
    getter cls : TagClass

    def initialize(@index, @cls)
    end

    def ==(other : Tag) : Bool
      return other.index == @index && other.cls == @cls;
    end

    def !=(other : Tag) : Bool
      return other.index != @index || other.cls != @cls;
    end
  end

end
