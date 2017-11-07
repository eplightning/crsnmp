
module CrSNMP::MIBParser

  struct OID
    property index : Int32

    def initialize(@index)
    end
  end

  class RootTreeNode
    property children : Array(TreeNode)

    def initialize(@children = [] of TreeNode)
    end
  end

  class TreeNode
    property object : MIBSymbol
    property oid : OID
    property children : Array(TreeNode)

    def initialize(@object, @oid, @children = [] of TreeNode)
    end
  end

end
