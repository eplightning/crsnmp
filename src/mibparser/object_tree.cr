
module CrSNMP::MIBParser

  struct OID
    property index : Int32

    def initialize(@index)
    end
  end

  class RootTreeNode
    property children : Array(TreeNode)
    property types : Hash(String, TypeDefinitionSymbol)

    def initialize(@children = [] of TreeNode, @types = {} of String => TypeDefinitionSymbol)
    end
  end

  class TreeNode
    property object : ObjectIdentifierSymbol | ObjectTypeSymbol
    property oid : OID
    property children : Array(TreeNode)

    def initialize(@object, @oid, @children = [] of TreeNode)
    end
  end

end
