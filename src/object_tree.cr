require "./ber/types"
require "./shared/oid"
require "./shared/object_type"

module CrSNMP

  class RootTreeNode
    property children : Array(TreeNode)

    def initialize(@children = [] of TreeNode)
    end
  end

  class TreeNode
    property object_type : ObjectType | Nil
    property syntax : DataType | Nil
    property identifier : String
    property oid : OID
    property children : Array(TreeNode)

    def initialize(@object_type, @syntax, @oid, @identifier, @children = [] of TreeNode)
    end
  end

end
