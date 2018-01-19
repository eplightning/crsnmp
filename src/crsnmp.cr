require "./mibparser/*"
require "./debug/*"
require "./file_resolver"
require "./object_tree_builder"
require "./ber/values"
require "option_parser"

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
flat_tree = tree.flatten

# 1.3.6.1.2.1.1.1 sysDescr
# 1.3.6.1.2.1.1.3 sysUptime

if opt_tree
  CrSNMP::Debug.print_object_tree tree
elsif opt_dectest
  #udp UdpEntry ::=
  #{
  # udpLocalAddress '11010001000110101101000100011010'B
  # udpLocalPort 314
  #}
  # 1.3.6.1.2.1.7.5.1
  udpEntry = [0x30_u8, 0x0A_u8, 0x40_u8, 0x04_u8, 0xD1_u8, 0x1A_u8, 0xD1_u8, 0x1A_u8, 0x02_u8, 0x02_u8, 0x01_u8, 0x3A_u8]
  udpSyntax = CrSNMP::Debug.get_ber_type flat_tree, "1.3.6.1.2.1.7.5.1"
  puts "Zdekodowany UdpEntry (port 314)"
  puts udpSyntax.decode udpEntry

  #entry AtEntry ::= {
  #atIfIndex 0,
  #atPhysAddress '10101010'H,
  #atNetAddress internet '10101010'H
  #}
  # 300F0201 00040410 10101040 04101010 10
  # 1.3.6.1.2.1.3.1.1
  atEntry = [0x30_u8, 0x0F_u8, 0x02_u8, 0x01_u8, 0x00_u8, 0x04_u8, 0x04_u8, 0x10_u8,
  0x10_u8, 0x10_u8, 0x10_u8, 0x40_u8, 0x04_u8, 0x10_u8, 0x10_u8, 0x10_u8, 0x10_u8]
  atSyntax = CrSNMP::Debug.get_ber_type flat_tree, "1.3.6.1.2.1.3.1.1"
  puts "Zdekodowany AtEntry (0)"
  puts atSyntax.decode atEntry
else
  requested_oid = CrSNMP::Debug.prompt_oid "Podaj OID obiektu który chcesz zbudować: "
  syntax = CrSNMP::Debug.get_ber_type flat_tree, requested_oid.to_s
  # syntax = tree.types["Message"]

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
end
