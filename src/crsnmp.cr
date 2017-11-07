require "./mibparser/*"

extractor = CrSNMP::MIBParser::Extractor.new
resolver = CrSNMP::MIBParser::SimpleFileResolver.new "/usr/share/snmp/mibs"
builder = CrSNMP::MIBParser::ObjectTreeBuilder.new extractor, resolver

tree = builder.build ["RFC1213-MIB"]

def recurs(tree : CrSNMP::MIBParser::RootTreeNode | CrSNMP::MIBParser::TreeNode, prefix = "")
  if tree.is_a?(CrSNMP::MIBParser::TreeNode)
    puts prefix + ": " + tree.object.identifier
  end

  tree.children.each do |child|
    recurs child, prefix + "." + child.oid.index.to_s
  end
end

recurs tree
