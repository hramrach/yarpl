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
        out, errs, rets = result = run_pipeline_w( ["cat"] ){|io| output_data io }
        assert_equal 1, errs.length, rets.length
        assert_equal "", *errs
        assert_equal 0, *rets
        assert_equal @inp, out
    end

    def test_cat_rw
        output = ""
        errs, rets = result = run_pipeline_rw( ["cat"] ){|inp, out|
            thread = Thread.new{ gather_out out, output}
            output_data inp
            inp.close
            thread.join
        }
        assert_equal 1, errs.length, rets.length
        assert_equal "", *errs
        assert_equal 0, *rets
        assert_equal @inp, output
    end


    def test_doublecat
        out, errs, rets = run_pipeline_w( ["cat","cat"] ){|io| output_data io }
        assert_equal 2, errs.length, rets.length
        assert_equal "", *errs
        assert_equal 0, *rets
        assert_equal @inp, out
    end

    def test_echo
        output = ""
        errs, rets = run_pipeline_r( ["echo '#{@inp.chomp}'"] ){|io| gather_out io, output }
        assert_equal 1, errs.length, rets.length
        assert_equal "", *errs
        assert_equal 0, *rets
        assert_equal @inp, output
    end

    def test_true_false
        out, errs, rets = run_pipeline_w( ["true", "false", "true"] ) {}
        assert_equal 3, errs.length, rets.length
        assert_equal 3, errs.length, rets.length
        assert_equal 0, rets[0], rets[2]
        assert_not_equal 0, rets[1]
        errs, rets = run_pipeline_r( ["false", "true", "false"] ) {}
        assert_equal 3, errs.length, rets.length
        assert_not_equal 0, rets[0], rets[2]
        assert_equal 0, rets[1]
        errs, rets = run_pipeline_rw( ["false", "true", "false", "true"] ) {}
        assert_equal 4, errs.length, rets.length
        assert_not_equal 0, rets[0], rets[2]
        assert_equal 0, rets[1], rets[3]
    end

    def test_err
      out, errs, rets = run_pipeline_w( ["sh -c 'while read x ; do echo $x ; echo A$x >&2 ; done; exit 5'" ,
                                                            "sh -c 'while read x ; do echo $x ; echo B$x >&2 ; done ; exit 3'" ] ) {|io|
        output_data io }
        assert_equal 2, errs.length, rets.length
        assert_equal 5, rets[0]
        assert_equal 3, rets[1]
        assert_equal @inp.gsub(/^/,'A') , errs[0]
        assert_equal @inp.gsub(/^/,'B') , errs[1]
        assert_equal @inp, out
    end

end

