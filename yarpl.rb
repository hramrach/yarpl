module Yarpl
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

def construct_pipeline cmds
    inp_chld, inp = IO.pipe
    out, out_chld = IO.pipe
    [inp, out] + (construct_pipeline_ios inp_chld, out_chld, cmds, [inp])
end

def construct_pipeline_ios inp_chld, out_chld, cmds, odd_ends
    cmd, *cmds = cmds
    err, err_chld = IO.pipe
    odd_ends << err
    if cmds.length >0 then
        inp_next, out_curr = IO.pipe
        pid = fork_process cmd, inp_chld, out_curr, err_chld, [inp_next,out_chld] + odd_ends
        errs, pids = (construct_pipeline_ios inp_next, out_chld, cmds, odd_ends)
        [[err] + errs, [pid] + pids]
    else
        [[err], [(fork_process cmd, inp_chld, out_chld, err_chld, odd_ends)]]
    end
end

def run_pipeline cmds, read = false, write = false
    inp, out, errs, pids = construct_pipeline cmds
    errstrs = []
    threads = []
    ret = []
    inp.close if !write
    if ! read then
        outstr = ""
        threads << Thread.new { gather_out out, outstr }
        ret << outstr
    end
    errs.each{|io|
        errstr = ""
        errstrs << errstr
        threads <<  Thread.new { gather_out io, errstr }
    }
    yield_ios = []
    yield_ios << inp if write
    yield_ios << out if read
    threads << Thread.new { yield *yield_ios ; yield_ios.each{|io| io.close rescue nil} } if yield_ios.length > 0
    retcodes = waiton pids
    waiton threads
    ret + [errstrs, retcodes]
end

def run_pipeline_w cmds, &block
    run_pipeline cmds, false, true, &block
end

def run_pipeline_r cmds, &block
    run_pipeline cmds, true, false, &block
end

def run_pipeline_rw cmds, &block
    run_pipeline cmds, true, true, &block
end
end
