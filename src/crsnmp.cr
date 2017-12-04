require "./mibparser/*"
require "./debug/*"
require "./file_resolver"
require "./object_tree_builder"
require "./ber/values"

extractor = CrSNMP::MIBParser::Extractor.new
resolver = CrSNMP::SimpleFileResolver.new "/home/eplightning/Projects/crsnmp"
builder = CrSNMP::ObjectTreeBuilder.new extractor, resolver

tree = builder.build ["MY-MIB"]

flat_tree = tree.flatten

obj = flat_tree["1.3.6.1.2.1.1"]
syntax = obj.syntax

value = OctetStringDataValue.new [1_u8,2_u8,3_u8]

if !syntax.nil?
  puts syntax.encode(value)
end

CrSNMP::Debug.print_object_tree tree
