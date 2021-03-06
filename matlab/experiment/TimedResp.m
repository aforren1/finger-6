classdef TimedResp < StateMachine

    properties
    % in order of appearance...
        ref_time % reference time for the entire block
        consts % consts for the experiment
        win % window/screen for Psychtoolbox
        aud % audio
        imgs % images
        keys % keyboard
        feed % keyboard feedback
        data_summary % for easy analyses (each row is a response)
        data_long % complete data, including times of onset for everything
        %data_nested % optional? nested-style data, which allows for varying
                    % numbers of events per trial
        last_beep
    end

    methods
        function self = TimedResp
            self = self@StateMachine;
            self.p.FunctionName = 'TimedResp';
            self.ref_time = GetSecs;
            self.data_summary = struct('id', [], 'day', [], 'block', [], ...
                                       'trial', [], 'resp_num', [], ...
                                       'resp_index', [], 'request_index', [], ...
                                       'correct', [], 'trial_time_press', [], ...
                                       'abs_time_press', [], 'trial_time_release', [],...
                                       'abs_time_release', [], 'image_index', [],...
                                       'trial_time_image', [], 'abs_time_image', [], ...
                                       'abs_time_audio', [], 'inter_click_interval', [], ...
                                       'num_beeps', []);
            self.data_long = struct(); %TODO: just bookkeeping and

            consts = struct('win_size', [30 30 400 400], ...
                            'reversed', false, ...
                            'beep_half', 0.02);
            self.consts = consts;

        end

        function Setup(s)
            Screen('Preference', 'Verbosity', 1);
            if s.consts.reversed
                front_color = [0 0 0];
                back_color = [255 255 255];
            else
                front_color = [255 255 255];
                back_color = [0 0 0];
            end
            s.win = PsychWindow(0, true, 'rect', s.consts.win_size,...
                                'color', back_color, ...
                                'alpha_blending', true);

            % add audio
            snd1 = GenClick(1046, 0.45, 3); % from ptbutils
            % fourth beep in seconds
            s.last_beep = (length(snd1) - s.consts.beep_half * 44100)/44100;

            snd2 = audioread('misc/sounds/scaled_coin.wav');

            s.aud = PsychAudio('mode', 9);
            s.aud.AddSlave(1, 'channels', 2);
            s.aud.AddSlave(2, 'channels', 2);

            s.aud.FillBuffer([snd1; snd1].', 1);
            s.aud.FillBuffer([snd2; snd2].', 2);

            % add images
            if s.tgt.image_type(1)
                subdir = 'shapes/';
            else
                subdir = 'hands/';
            end
            img_dir = ['misc/images/', subdir];
            img_names = dir([img_dir, '/*.jpg']);

            s.imgs = PsychTextures;
            for ii = 1:length(name_array)
                img = imread([img_dir, img_names(ii).name]);
                s.imgs.AddImage(img, s.win.pointer, ii,...
                                'rel_x_pos', 0.5, ...
                                'rel_y_pos', 0.5, ...
                                'rel_x_scale', 0.23);
            end

            s.keys = BlamKeyboard(unique(s.tgt.finger_index));
            l_keys = length(s.keys.valid_indices);

            % add feedback
            s.feed = BlamKeyFeedback(l_keys, 'fill_color', back_color, ...
                                     'frame_color', front_color, ...
                                     'rel_x_scale', repmat(0.06, 1, l_keys));
        end % end setup

        function Execute(s)
            done = false;
            time_flip = GetSecs;
            state = 'intrial';
            neststate = 'prep';
            trial_count = 1;
            while ~(GetSecs - s.ref_time > 4200) || done
                loop_time = GetSecs;

                [press_times, ~, press_array, ...
                 release_times, ~, release_array] = Check(s.keys);

                switch state
                    case 'intrial'
                        switch neststate
                            case 'prep'
                            % all pre-trial things
                                trial_time = s.aud.Play(0, 1);
                                img_time = trial_time + s.consts.fourth * s.tgt.image_time(trial_count);
                                neststate = 'doneprep';

                            case 'doneprep'
                                if loop_time >= img_time
                                    s.textures.Draw(scrn.pointer, s.tgt.image_index(trial_count));
                                end
                        end

                        % draw press feedback
                        if loop_time >= endtrial_time
                            state = 'feedback';
                        end

                    case 'feedback'
                        s.textures.Draw(scrn.pointer, s.tgt.image_index(trial_count));
                        % draw correctness feedback

                    case 'between'
                        trial_count = trial_count + 1;

                    otherwise
                        error('Invalid state.')

                end
                s.win.DrawingFinished();
                % collect button presses, write data... anything not timing critical
                time_flip = s.win.Flip(time_flip + (0.7 * s.win.flip_interval));
                if trial_count > max(s.tgt.trial)
                    done = true;
                end
            end

        end % end execute

        function Cleanup(self)
            BailPtb;
            %...
        end

    end % end methods
end % end classdef
