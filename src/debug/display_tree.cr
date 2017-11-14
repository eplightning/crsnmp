module CrSNMP::Debug

  def self.print_object_tree(root : CrSNMP::MIBParser::RootTreeNode)
    root.children.each do |child|
      print_recursive child, root, child.oid.index.to_s + ".", "-"
    end
  end

  private def self.print_recursive(tree : CrSNMP::MIBParser::TreeNode, root : CrSNMP::MIBParser::RootTreeNode, prefix, indent)
    puts indent + "| " + prefix + ": " + tree.object.identifier

    puts indent + "| " + tree.object.to_s

    obj = tree.object

    if obj.is_a?(CrSNMP::MIBParser::ObjectTypeSymbol)
      puts indent + "| Access: " + obj.access.to_s
      puts indent + "| Status: " + obj.status.to_s
      puts indent + "| Description: " + obj.description[0..26] + "..."
      puts indent + "| Syntax: (klasa) " + obj.syntax.class.name

      print_type obj.syntax, root, ->(x: String) { puts indent + "| " + x }
    end

    puts

    tree.children.each do |child|
      print_recursive child, root, prefix + child.oid.index.to_s + ".", indent + "-"
    end
  end

  private def self.print_type(
    syntax : CrSNMP::MIBParser::ExtractedType,
    root : CrSNMP::MIBParser::RootTreeNode, printer : Proc(String, Nil))

    printer.call "ID: " + (syntax.id.nil? ? "---" : syntax.id.to_s)
    printer.call "Tag: " + (syntax.tag.nil? ? "---" : syntax.tag.to_s)
    printer.call "Tag type: " + syntax.tag_type.to_s
    printer.call "Przedział wartości: " + (syntax.range.nil? ? "---" : syntax.range.to_s)
    printer.call "Rozmiar: " + (syntax.size.nil? ? "---" : syntax.size.to_s)

    if syntax.is_a? CrSNMP::MIBParser::PrimitiveExtractedType
      printer.call "Typ prymitywny: " + syntax.primitive.to_s
    elsif syntax.is_a? CrSNMP::MIBParser::SymbolExtractedType
      printer.call "Referencja do typu: " + syntax.symbol_name.to_s
      printer.call ">>> REFERENCJA"

      if root.types.has_key? syntax.symbol_name
        symbol = root.types[syntax.symbol_name]

        printer.call "Rozwiązana referencja: " + symbol.full_id
        print_type symbol.definition, root, printer
      else
        printer.call "REFERENCJA NIE ROZWIĄZANA, TYP NIE ZNALEZIONY"
      end
    elsif syntax.is_a? CrSNMP::MIBParser::SequenceExtractedType
      printer.call "Sekwencja => "

      syntax.items.each do |k, subitem|
        printer.call " >>>>>>>>>>>> " + k
        print_type subitem, root, printer
        printer.call " <<<<<<<<<<<< " + k
      end
    elsif syntax.is_a? CrSNMP::MIBParser::ChoiceExtractedType
      printer.call "Union (Choice) => "

      syntax.choices.each do |k, subitem|
        printer.call " >>>>>>>>>>>> " + k
        print_type subitem, root, printer
        printer.call " <<<<<<<<<<<< " + k
      end
    else
      printer.call "Nieznany typ"
    end
  end

end
