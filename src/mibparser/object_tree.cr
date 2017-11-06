
module CrSNMP::MIBParser

  struct OID
    property index : Int32

    def initialize(@index)
    end
  end

  class TreeNode
    property symbol : MIBSymbol
    property oid : OID
    property children : Array(TreeNode)

    def initialize(@symbol, @oid, @children = [] of TreeNode)
    end
  end

end
