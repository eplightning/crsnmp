require "./ber/types"
require "./shared/oid"
require "./shared/object_type"

module CrSNMP

  class RootTreeNode
    property children : Array(TreeNode)

    def initialize(@children = [] of TreeNode)
    end

    def flatten : Hash(String, TreeNode)
      map = {} of String => TreeNode

      children.each do |child|
        do_flatten child, map
      end

      map
    end

    private def do_flatten(node : TreeNode, map : Hash(String, TreeNode))
      map[node.oid.to_s] = node

      node.children.each do |child|
        do_flatten child, map
      end
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
