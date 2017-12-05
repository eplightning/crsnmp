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


oid = OID.new nil, [
  OIDFragment.new(1),
  OIDFragment.new(2),
  OIDFragment.new(21603836)
]

value = OIDDataValue.new oid

if !syntax.nil?
  encoded = syntax.encode(value)

  CrSNMP::Debug.print_binary encoded

  puts syntax.decode(encoded)
end

CrSNMP::Debug.print_object_tree tree
