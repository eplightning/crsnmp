require "./mibparser/*"

extractor = CrSNMP::MIBParser::Extractor.new
resolver = CrSNMP::MIBParser::SimpleFileResolver.new "/home/eplightning/Projects/crsnmp"
builder = CrSNMP::MIBParser::ObjectTreeBuilder.new extractor, resolver

tree = builder.build ["RFC1213-MIB"]

def size_info(size : CrSNMP::MIBParser::ExtractedSize | Nil) : String
  if size.nil?
    "---"
  else
    if size.is_a? CrSNMP::MIBParser::NumberExtractedSize
      "Number(" + size.number.to_s + ")"
    elsif size.is_a? CrSNMP::MIBParser::RangeExtractedSize
      "Range(Left: " + size.left.to_s + ", Right: " + size.right.to_s + ")"
    else
      "?"
    end
  end
end

def recurs(tree : CrSNMP::MIBParser::RootTreeNode | CrSNMP::MIBParser::TreeNode, prefix = "", indent = "")
  if tree.is_a?(CrSNMP::MIBParser::TreeNode)
    puts indent + "| " + prefix + ": " + tree.object.identifier

    puts indent + "| " + tree.object.to_s

    obj = tree.object

    if obj.is_a?(CrSNMP::MIBParser::ObjectTypeSymbol)
      puts indent + "| Access: " + obj.access.to_s
      puts indent + "| Status: " + obj.status.to_s
      puts indent + "| Description: " + obj.description[0..26] + "..."
      puts indent + "| Syntax: " + obj.syntax.class.name

      syntax = obj.syntax

      puts indent + "| > ID: " + (syntax.id.nil? ? "---" : syntax.id.to_s)
      puts indent + "| > Tag: " + (syntax.tag.nil? ? "---" : syntax.tag.to_s)
      puts indent + "| > Tag type: " + syntax.tag_type.to_s

      puts indent + "| > Przedział wartości: " + size_info(syntax.range)
      puts indent + "| > Rozmiar: " + size_info(syntax.size)

      if syntax.is_a? CrSNMP::MIBParser::PrimitiveExtractedType
        puts indent + "| > Typ prymitywny: " + syntax.primitive.to_s
      elsif syntax.is_a? CrSNMP::MIBParser::SymbolExtractedType
        puts indent + "| > Symbol: " + syntax.symbol_name.to_s
      elsif syntax.is_a? CrSNMP::MIBParser::UnknownExtractedType
        puts syntax.definition.to_s
      end
    end
  end

  puts

  tree.children.each do |child|
    recurs child, prefix + child.oid.index.to_s + ".", indent + "-"
  end
end

recurs tree
