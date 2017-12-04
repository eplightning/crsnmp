module CrSNMP::Debug

  def self.print_object_tree(root : CrSNMP::MIBParser::RootTreeNode)
    root.children.each do |child|
      print_recursive child, root, "-"
    end
  end

  private def self.print_recursive(tree : CrSNMP::MIBParser::TreeNode, root : CrSNMP::MIBParser::RootTreeNode, indent)
    puts indent + "| " + tree.oid.to_s + ": " + tree.identifier

    puts indent + "| " + tree.syntax.to_s

    obj_type = tree.object_type
    syntax = tree.syntax

    if !obj_type.nil? && !syntax.nil?
      puts indent + "| Access: " + obj_type.access.to_s
      puts indent + "| Status: " + obj_type.status.to_s
      puts indent + "| Description: " + obj_type.description[0..26] + "..."
      puts indent + "| Syntax: (klasa) " + syntax.class.name

      print_type syntax, root, ->(x: String) { puts indent + "| " + x }
    end

    puts

    tree.children.each do |child|
      print_recursive child, root, indent + "-"
    end
  end

  private def self.print_type(
    syntax : CrSNMP::BER::DataType,
    root : CrSNMP::MIBParser::RootTreeNode, printer : Proc(String, Nil))

    if syntax.is_a?(PrimitiveDataType)
      printer.call "Typ prymitywny: " + syntax.class.name
    elsif syntax.is_a?(SequenceDataType)
      printer.call "Sequence: "

      syntax.items.each do |k, subitem|
        printer.call " >>>>>>>>>>>> " + k
        print_type subitem, root, printer
        printer.call " <<<<<<<<<<<< " + k
      end
    elsif syntax.is_a?(ArrayDataType)
      printer.call "SequenceOf: "
      print_type syntax.item, root, printer
    elsif syntax.is_a?(ChoiceDataType)
      printer.call "Choice: "

      syntax.items.each do |k, subitem|
        printer.call " >>>>>>>>>>>> " + k
        print_type subitem, root, printer
        printer.call " <<<<<<<<<<<< " + k
      end
    elsif syntax.is_a?(CustomDataType)
      printer.call "Custom: "

      printer.call "Tag: " + (syntax.type_tag.nil? ? "---" : syntax.type_tag.to_s)
      printer.call "Tag rodzaj: " + (syntax.tagging_mode.to_s)
      printer.call "Przedział wartości: " + (syntax.restrictions.value.nil? ? "---" : syntax.restrictions.value.to_s)
      printer.call "Rozmiar: " + (syntax.restrictions.size.nil? ? "---" : syntax.restrictions.size.to_s)

      print_type syntax.parent, root, printer
    end
  end

end
