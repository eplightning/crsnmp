
module CrSNMP



  class RootTreeNode
    property children : Array(TreeNode)
    property global_types : Hash(String, TypeDefinitionSymbol)

    def initialize(@children = [] of TreeNode, @types = {} of String => TypeDefinitionSymbol)
    end
  end

  class TreeNode
    property object : ObjectIdentifierSymbol | ObjectTypeSymbol
    property oid : OID
    property children : Array(TreeNode)
    property resolved_type : Nil

    def initialize(@object, @oid, @children = [] of TreeNode)
      @resolved_type = nil
    end
  end

end
