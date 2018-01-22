require "./mibparser/*"
require "./debug/*"
require "./file_resolver"
require "./object_tree_builder"
require "./ber/values"
require "option_parser"
require "./server"
require "./data_source"
require "./data_sources/*"

opt_mib = "CUSTOM-MIB"
opt_path = "/home/eplightning/Projects/crsnmp"
opt_tree = false
opt_dectest = false

OptionParser.parse! do |parser|
  parser.banner = "Usage: crsnmp [arguments]"
  parser.on("-m NAME", "--mib=MIB", "MIB") { |name| opt_mib = name }
  parser.on("-d DIR", "--dir=DIR", "Ścieżka do MIBów") { |path| opt_path = path }
  parser.on("-x", "--dec-test", "Test dekodowania") { opt_dectest = true }
  parser.on("-t", "--tree", "Drzewko") { opt_tree = true }
  parser.on("-h", "--help", "Ta pomoc") { puts parser }
end

extractor = CrSNMP::MIBParser::Extractor.new
resolver = CrSNMP::SimpleFileResolver.new opt_path
builder = CrSNMP::ObjectTreeBuilder.new extractor, resolver

tree = builder.build [opt_mib, "RFC1157-SNMP"]

# 1.3.6.1.2.1.1.1 sysDescr
# 1.3.6.1.2.1.1.3 sysUptime

if opt_tree
  CrSNMP::Debug.print_object_tree tree
elsif opt_dectest
  flat_tree = tree.flatten
  requested_oid = CrSNMP::Debug.prompt_oid "Podaj OID obiektu który chcesz zbudować: "
  syntax = CrSNMP::Debug.get_ber_type flat_tree, requested_oid.to_s
  builder = CrSNMP::Debug::DataBuilder.new

  value = builder.build syntax

  puts "Przed zakodowaniem"
  puts value
  puts "Zakodowana wartość"
  encoded = syntax.encode value
  CrSNMP::Debug.print_binary encoded
  puts "Zdekodowana wartość"
  decoded = syntax.decode encoded
  puts decoded
else
  src = CrSNMP::DataManager.new

  src.register_source CrSNMP::DataSources::MemoryIntegerDataSource.new(
    CrSNMP::Shared::OID.from_string("1.3.6.1.4.1234.6"),
    5_i64
  )

  src.register_source CrSNMP::DataSources::TimeDataSource.new(
    CrSNMP::Shared::OID.from_string("1.3.6.1.4.1234.7")
  )

  server = CrSNMP::Server.new tree, src

  server.run
end
