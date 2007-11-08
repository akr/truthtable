$VERBOSE = true

Dir.glob('test/test-*.rb') {|filename|
  load filename
}
