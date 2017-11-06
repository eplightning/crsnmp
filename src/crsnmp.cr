require "./mibparser/*"

mib = File.read("RFC1213-MIB.txt")

extractor = CrSNMP::MIBParser::Extractor.new

ext = extractor.extract(mib)

puts ext.exports
puts ext.imports
puts ext.name
puts ext.symbols
