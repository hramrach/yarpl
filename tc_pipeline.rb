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
        out, err, ret = result = run_pipeline_w( ["cat"] ){|io| output_data io }
        #STDERR.puts result.inspect
        assert_equal "", err
        assert_equal 0, ret
        assert_equal @inp, out
    end

    def test_cat_rw
        output = ""
        err, ret = result = run_pipeline_rw( ["cat"] ){|inp, out|
            thread = Thread.new{ gather_out out, output}
            output_data inp
            inp.close
            thread.join
        }
        assert_equal "", err
        assert_equal 0, ret
        assert_equal @inp, output
    end


    def test_doublecat
        out, err1, ret1, err2, ret2 = result = run_pipeline_w( ["cat","cat"] ){|io| output_data io }
        assert_equal "", err1, err2
        assert_equal 0, ret1, ret2
        assert_equal @inp, out
    end

    def test_echo
        output = ""
        err, ret = run_pipeline_r( ["echo '#{@inp.chomp}'"] ){|io| gather_out io, output }
        assert_equal "", err
        assert_equal 0, ret
        assert_equal @inp, output
    end

    def test_true_false
        out, err1, ret1, err2, ret2, err3, ret3 = result = run_pipeline_w( ["true", "false", "true"] ) {}
        assert_equal 0, ret1, ret3
        assert_not_equal 0, ret2
        err1, ret1, err2, ret2, err3, ret3 = result = run_pipeline_r( ["false", "true", "false"] ) {}
        assert_not_equal 0, ret1, ret3
        assert_equal 0, ret2
        err1, ret1, err2, ret2, err3, ret3, err4, ret4 = result = run_pipeline_rw( ["false", "true", "false", "true"] ) {}
        assert_not_equal 0, ret1, ret3
        assert_equal 0, ret2, ret4
    end

    def test_err
      out, err1, ret1, err2, ret2 = result = run_pipeline_w( ["sh -c 'while read x ; do echo $x ; echo A$x >&2 ; done; exit 5'" ,
                                                            "sh -c 'while read x ; do echo $x ; echo B$x >&2 ; done ; exit 3'" ] ) {|io|
        output_data io }
        assert_equal 5, ret1
        assert_equal 3, ret2
        assert_equal @inp.gsub(/^/,'A') , err1
        assert_equal @inp.gsub(/^/,'B') , err2
        assert_equal @inp, out
    end

end

