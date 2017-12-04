require "./mibparser/extractor"
require "./file_resolver"
require "./object_tree"
require "./mib_to_ber"
require "./shared/*"

module CrSNMP

  class ObjectTreeBuilder
    alias SymbolMap = Hash(String, MIBSymbol)
    alias NodeMap = Hash(String, TreeNode)

    def initialize(@extractor : Extractor, @resolver : FileResolver)
      @converter = MIBBERTypeConverter.new
    end

    def build(entrypoints : Array(String)) : RootTreeNode
      root = RootTreeNode.new
      node_map = {} of String => TreeNode
      symbols = {} of String => MIBSymbol

      insert_initial_nodes root, node_map, symbols

      entrypoints.each do |ep|
        build_entrypoint(ep, root, node_map, symbols)
      end

      root
    end

    private def insert_initial_nodes(root : RootTreeNode, node_map : NodeMap, symbol_map : SymbolMap)
      iso_symbol = ObjectIdentifierSymbol.new("iso", "iso", ExtractedOID.new)
      iso_node = TreeNode.new nil, nil, OID.new(nil, 1), "iso"

      node_map["iso::iso"] = iso_node
      symbol_map["iso"] = iso_symbol

      root.children.push iso_node
    end

    private def build_entrypoint(entrypoint : String, root : RootTreeNode, node_map : NodeMap, symbols : SymbolMap)
      entry_mib = @extractor.extract @resolver.load(entrypoint)
      imported_mibs = load_imports entrypoint, entry_mib.imports

      # merge all symbols
      all_symbols = symbols.dup
      all_symbols.merge! entry_mib.symbols
      imported_mibs.each do |k, v|
        all_symbols.merge! v.symbols
      end

      # get all global types
      types = {} of String => ExtractedType
      all_symbols.each do |symbol_name, symbol|
        if symbol.is_a?(TypeDefinitionSymbol)
          types[symbol_name] = symbol.definition
        end
      end

      # init converter
      @converter = MIBBERTypeConverter.new types

      # build tree
      all_symbols.each do |symbol_name, symbol|
        if symbol.is_a?(ObjectTypeSymbol) || symbol.is_a?(ObjectIdentifierSymbol)
          build_simple_parent(symbol_name, root, node_map, all_symbols)
        end
      end
    end

    private def build_simple_parent(
      symbol_name : String, root : RootTreeNode,
      node_map : NodeMap, symbols : SymbolMap
    ): TreeNode
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

          node = create_node symbol, last_frag.number, parent
          node_map[symbol.full_id] = node

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
      node_map : NodeMap, symbols : SymbolMap
    ): TreeNode
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
          parent = build_hinted_parent(frags, root, node_map, symbols)
          num = frag.number
          symbol = ObjectIdentifierSymbol.new(frag.symbol_name, frag.symbol_name, ExtractedOID.new)
          node = create_node symbol, num, parent
          node_map[symbol.full_id] = node
          node
        end
      else
        raise "Nope number"
      end
    end

    private def create_node(symbol : MIBSymbol, idx : Int32, parent : TreeNode) : TreeNode
      oid = OID.new(parent.oid, idx)

      if symbol.is_a?(ObjectTypeSymbol)
        node = TreeNode.new symbol.object_type, @converter.convert(symbol.syntax), oid, symbol.identifier
      else
        node = TreeNode.new nil, nil, oid, symbol.identifier
      end

      parent.children.push node
      node
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
