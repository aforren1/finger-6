function main(id, exp_type, tgt_name)
    addpath(genpath('Psychoobox'));
    addpath(genpath('matlab'));
    addpath('ptbutils');

    try
        if IsOctave
            pkg load all
        end

        exp = StateMachine.Factory(exp_type);
        tgt = ParseTgt(tgt_name, ',');
        exp.Set('tgt', tgt);
        exp.Set('id', id);
        exp.Setup();

        exp.Execute();

        exp.Cleanup();
    catch ME
        % save data!
        BailPtb;
        rethrow(ME);
    end
end
