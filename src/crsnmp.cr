require "./mibparser/*"

extractor = CrSNMP::MIBParser::Extractor.new
resolver = CrSNMP::MIBParser::SimpleFileResolver.new "/usr/share/snmp/mibs"
builder = CrSNMP::MIBParser::ObjectTreeBuilder.new extractor, resolver

tree = builder.build ["RFC1213-MIB"]

def recurs(tree : CrSNMP::MIBParser::RootTreeNode | CrSNMP::MIBParser::TreeNode, prefix = "", indent = "")
  if tree.is_a?(CrSNMP::MIBParser::TreeNode)
    puts indent + "| " + prefix + ": " + tree.object.identifier

    puts indent + "| " + tree.object.to_s

    obj = tree.object

    if obj.is_a?(CrSNMP::MIBParser::ObjectTypeSymbol)
      puts indent + "| Access: " + obj.access
      puts indent + "| Status: " + obj.status
      puts indent + "| Description: " + obj.description[0..26] + "..."
      puts indent + "| Syntax: " + obj.syntax.class.name
    end
  end

  puts

  tree.children.each do |child|
    recurs child, prefix + child.oid.index.to_s + ".", indent + "-"
  end
end

recurs tree
