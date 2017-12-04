require "./mibparser/*"
require "./debug/*"
require "./file_resolver"
require "./object_tree_builder"

extractor = CrSNMP::MIBParser::Extractor.new
resolver = CrSNMP::SimpleFileResolver.new "/home/eplightning/Projects/crsnmp"
builder = CrSNMP::ObjectTreeBuilder.new extractor, resolver

tree = builder.build ["MY-MIB"]

CrSNMP::Debug.print_object_tree tree
