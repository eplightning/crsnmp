require "./crsnmp/*"
require "./mibparser/*"

mib = File.read("RFC1213-MIB.txt")

extractor = CrSNMP::MIBParser::Extractor.new

extractor.extract mib
