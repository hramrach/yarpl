READSIZE = 1024 * 32
def gather_out io, str
    begin
        while true do
            str << (io.readpartial READSIZE)
        end
    rescue EOFError
    end
    str
end

def waiton things
    things.collect{|thing|
        if thing.is_a? Thread then
            thing.join
        else
            Process::waitpid thing
            $?.exitstatus
        end
    }
end

def fork_process cmd, inp_chld, out_chld, err_chld, odd_ends
    pid = fork {
        odd_ends.each{|fd| fd.close}
        STDIN.reopen inp_chld
        STDOUT.reopen out_chld
        STDERR.reopen err_chld
        exec cmd
    }
    inp_chld.close
    out_chld.close
    err_chld.close
    pid
end


def run_pipeline cmds, read = false
    threads = []
    odd_ends = []
    pids = []
    errs = []
    inp_chld, inp = IO.pipe
    odd_ends << inp
    errstr = ""
    errs << errstr
    err, err_chld = IO.pipe
    odd_ends << err
    cmd, *cmds = cmds
    threads <<  Thread.new { gather_out err, errstr }
    while cmds.length > 0 do
        inp_next, out_curr = IO.pipe
        pids << (fork_process cmd, inp_chld, out_curr, err_chld, odd_ends + [inp_next])
        inp_chld = inp_next
        errstr = ""
        errs << errstr
        err, err_chld = IO.pipe
        odd_ends << err
        cmd, *cmds = cmds
        threads <<  Thread.new { gather_out err, errstr }
    end
    out, out_chld = IO.pipe
    odd_ends << out
    if read
        yield_io = out
    else
        outstr = ""
        threads << Thread.new { gather_out out, outstr }
        yield_io = inp
    end
    pids << (fork_process cmd, inp_chld, out_chld, err_chld, odd_ends)
    inp.close if read
    threads << Thread.new { yield yield_io ; yield_io.close}
    waiton threads
    rets = waiton pids
    rets = (errs.zip rets).flatten
    if read then
        rets
    else
        [outstr] + rets
    end
end

def run_pipeline_w cmds, &block
    run_pipeline cmds, false, &block
end

def run_pipeline_r cmds, &block
    run_pipeline cmds, true, &block
end
