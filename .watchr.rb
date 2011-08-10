watch('(.*)\.rb')     {|md| (md[1] =~ /^tc_/) or system "ruby tc_#{md[1]}.rb"}
watch('tc_.*\.rb') {|md| system "ruby -w #{md[0]}"}
