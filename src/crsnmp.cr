require "./mibparser/*"
require "./debug/*"

extractor = CrSNMP::MIBParser::Extractor.new
resolver = CrSNMP::MIBParser::SimpleFileResolver.new "/home/eplightning/Projects/crsnmp"
builder = CrSNMP::MIBParser::ObjectTreeBuilder.new extractor, resolver

tree = builder.build ["MY-MIB"]

CrSNMP::Debug.print_object_tree tree
