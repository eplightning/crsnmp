require "./mibparser/*"
require "./debug/*"
require "./file_resolver"
require "./object_tree_builder"
require "./ber/values"

extractor = CrSNMP::MIBParser::Extractor.new
resolver = CrSNMP::SimpleFileResolver.new "/home/eplightning/Projects/crsnmp"
builder = CrSNMP::ObjectTreeBuilder.new extractor, resolver

tree = builder.build ["RFC1213-MIB"]

flat_tree = tree.flatten

syntax = CrSNMP::Debug.get_ber_type flat_tree, "1.3.6.1.2.1.11.16"


oid = OID.new nil, [
  OIDFragment.new(1),
  OIDFragment.new(2),
  OIDFragment.new(21603836)
]


item1 = SequenceDataValue::Item.new(IntegerDataValue.new 500)
item2 = SequenceDataValue::Item.new(
  OctetStringDataValue.new([1_u8, 2_u8, 3_u8, 4_u8], Tag.new(0, TagClass::Application))
)

# value = OctetStringDataValue.new([55_u8, 23_u8])
value = IntegerDataValue.new 555

if !syntax.nil?
  encoded = syntax.encode(value)

  CrSNMP::Debug.print_binary encoded

  puts syntax.decode(encoded)
end

CrSNMP::Debug.print_object_tree tree
