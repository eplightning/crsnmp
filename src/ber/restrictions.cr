module CrSNMP::BER

  class Restrictions
    getter size : Restriction | Nil
    getter value : Restriction | Nil

    def initialize(@size = nil, @value = nil)
    end
  end

  abstract class Restriction
  end

  class RangeRestriction < Restriction
    property left : Int64
    property right : Int64

    def initialize(@left, @right)
    end

    def to_s
      "Range(Left: " + @left.to_s + ", Right: " + @right.to_s + ")"
    end
  end

  class NumberRestriction < Restriction
    property number : Int64

    def initialize(@number)
    end

    def to_s
      "Number(" + @number.to_s + ")"
    end
  end

end
