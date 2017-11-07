require "./extractor"
require "./object_tree"
require "./file_resolver"

module CrSNMP::MIBParser

  class ObjectTreeBuilder
    def initialize(@extractor : Extractor, @resolver : FileResolver)
    end

    def build(entrypoints : Array(String)) : RootTreeNode
      iso_node = TreeNode.new ObjectIdentifierSymbol.new("iso", "iso", ExtractedOID.new), OID.new(1)

      root = RootTreeNode.new
      node_map = {} of String => TreeNode

      node_map["iso::iso"] = iso_node
      root.children.push iso_node

      entrypoints.each do |ep|
        build_entrypoint(ep, root, node_map)
      end

      root
    end

    private def build_entrypoint(entrypoint : String, root : RootTreeNode, node_map : Hash(String, TreeNode))
      entry_mib = @extractor.extract @resolver.load(entrypoint)
      imported_mibs = load_imports entrypoint, entry_mib.imports

      # merge all symbols
      all_symbols = entry_mib.symbols.dup
      all_symbols["iso"] = node_map["iso::iso"].object

      imported_mibs.each do |k, v|
        all_symbols.merge! v.symbols
      end

      all_symbols.each do |symbol_name, symbol|
        if symbol.is_a?(ObjectTypeSymbol) || symbol.is_a?(ObjectIdentifierSymbol)
          build_simple_parent(symbol_name, root, node_map, all_symbols)
        end
      end

    end

    private def build_simple_parent(
      symbol_name : String, root : RootTreeNode,
      node_map : Hash(String, TreeNode), symbols : Hash(String, MIBSymbol)
    ): TreeNode
      puts "simple: " + symbol_name
      symbol = symbols[symbol_name]

      if !node_map.has_key?(symbol.full_id)
        if symbol.is_a?(ObjectTypeSymbol) || symbol.is_a?(ObjectIdentifierSymbol)
          frags = symbol.oid.fragments.dup

          if frags.size < 2
            raise "oid with less than 2 fragments"
          end

          last_frag = frags.pop

          if !last_frag.is_a? ExtractedOIDNumber
            raise "last oid fragment was not a index"
          end

          if frags.size == 1
            fr = frags[0]

            if fr.is_a?(ExtractedOIDSymbol)
              parent = build_simple_parent(fr.symbol_name, root, node_map, symbols)
            else
              raise "weird oid structure"
            end
          elsif frags.size > 1
            parent = build_hinted_parent(frags, root, node_map, symbols)
          else
            raise "weird oid structure"
          end

          node = create_node symbol, last_frag.number
          node_map[symbol.full_id] = node

          parent.children.push node

          node
        else
          raise "wrong symbol"
        end
      else
        node_map[symbol.full_id]
      end
    end

    private def build_hinted_parent(
      frags : Array(ExtractedOIDFragment), root : RootTreeNode,
      node_map : Hash(String, TreeNode), symbols : Hash(String, MIBSymbol)
    ): TreeNode
      puts "hinted"
      frag = frags.pop

      if frag.is_a?(ExtractedOIDSymbol)
        if symbols.has_key?(frag.symbol_name)
          build_simple_parent(frag.symbol_name, root, node_map, symbols)
        else
          raise "Nope symbol"
        end
      elsif frag.is_a?(ExtractedOIDForwardSymbol)
        if symbols.has_key?(frag.symbol_name)
          build_simple_parent(frag.symbol_name, root, node_map, symbols)
        else
          num = frag.number
          symbol = ObjectIdentifierSymbol.new(frag.symbol_name, frag.symbol_name, ExtractedOID.new)
          node = create_node symbol, num
          node_map[symbol.full_id] = node
          parent = build_hinted_parent(frags, root, node_map, symbols)
          parent.children.push node
          node
        end
      else
        raise "Nope number"
      end
    end

    private def create_node(symbol : MIBSymbol, idx : Int32) : TreeNode
      TreeNode.new symbol, OID.new(idx)
    end

    private def load_imports(entrypoint : String, import : Array(ExtractedImport)) : Hash(String, ExtractedMIB)
      out = {} of String => ExtractedMIB

      # todo cycle detection

      import.each do |info|
        if info.mib != "RFC-1212"
          loaded_mib = @extractor.extract @resolver.load(info.mib)

          out[info.mib] = loaded_mib

          if !loaded_mib.imports.empty?
            out = out.merge load_imports(info.mib, loaded_mib.imports)
          end
        end
      end

      out
    end

  end
end
