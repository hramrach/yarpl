require 'pipeline'
require 'test/unit'
require 'stringio'

class TestPipeline < Test::Unit::TestCase
    def setup
        # none
        @data_lines = 1000
        @data_text = "%i some data"
        @inp = StringIO.new
        output_data @inp
        @inp.rewind
        @inp = @inp.read
    end
    def output_data io
        (1..@data_lines).each {|i| io.puts(@data_text % i) }
    end
    def teardown
        # none
    end

    def test_cat
        out, err, ret = run_pipeline_w( ["cat"] ){|io| output_data io rescue nil}
        assert_equal 0, ret
        assert_equal @inp, out
        assert_equal "", err
    end

    def test_doublecat
        out, err1, ret1, err2, ret2 = run_pipeline_w( ["cat","cat"] ){|io| output_data io rescue nil}
        assert_equal 0, ret1, ret2
        assert_equal @inp, out
        assert_equal "", err1, err2
    end

end

