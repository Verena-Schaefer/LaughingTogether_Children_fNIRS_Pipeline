function [badChannels] = LTC_channelCheckbox(preFlaggedBadChannels)
    % LTC_channelCheckbox is a function that displays a small GUI for the 
    % selection of bad channels. It returns a vector including the numbers
    % of the bad channels. If some channels are already flagged as bad, for instance due
    % to their scalp-coupling index (SCI), these channels are automatically
    % marked in the GUI.
    %
    % Use as
    %   [badChannels] = LTC_channelCheckbox()
    % or
    %   [badChannels] = LTC_channelCheckbox(preFlaggedBadChannels)
    %
    % output: vector of bad channels
    %
    % input (optional): vector of pre-flagged bad channels. This vector should
    % contain the channel numbers (e.g., 1, 3, 4, 16)
    %
    % SEE also UIFIGURE, UICHECKBOX, UIBUTTON, UIRESUME, UIWAIT

    % LTC_channelCheckbox was created by Carolina Pletti in 2024 and is based on CARE_CHANNELCHECKBOX by Daniel
    % Matthes, MPI CBS, 2018

    % -------------------------------------------------------------------------
    % Create GUI
    % -------------------------------------------------------------------------
    SelectBadChannels = uifigure;
    SelectBadChannels.Position = [150 400 375 215];
    SelectBadChannels.Name = 'Select bad channels';

    % Pre-flagged bad channels initialization
    if nargin < 1
        preFlaggedBadChannels = []; % If no input, default to an empty list
    end

    % Initialize checkboxes for 16 channels
    Elec = struct();
    positions = [ ...
        45, 150; 125, 150; 205, 150; 285, 150; ... % Row 1
        45, 125; 125, 125; 205, 125; 285, 125; ... % Row 2
        45, 100; 125, 100; 205, 100; 285, 100; ... % Row 3
        45,  75; 125,  75; 205,  75; 285,  75  ... % Row 4
    ];
    for i = 1:16
        Elec.(['Ch' num2str(i)]) = uicheckbox(SelectBadChannels);
        Elec.(['Ch' num2str(i)]).Text = ['Ch' num2str(i)];
        Elec.(['Ch' num2str(i)]).Position = [positions(i, 1), positions(i, 2), 80, 15];
        
        % Automatically check pre-flagged bad channels
        if ismember(i, preFlaggedBadChannels)
            Elec.(['Ch' num2str(i)]).Value = true;
        end
    end

    % Create SaveButton
    btn = uibutton(SelectBadChannels, 'push');
    btn.ButtonPushedFcn = @(btn, evt) SaveButtonPushed(SelectBadChannels);
    btn.Position = [137 27 101 21];
    btn.Text = 'Save';

    % -------------------------------------------------------------------------
    % Wait for user input and return selection after btn 'Save' was pressed
    % -------------------------------------------------------------------------
    % Wait until button is pushed
    uiwait(SelectBadChannels);

    if ishandle(SelectBadChannels) % If GUI still exists
        % Retrieve checkbox values
        badChannels = [ ...
            Elec.Ch1.Value; Elec.Ch2.Value; Elec.Ch3.Value; Elec.Ch4.Value; ...
            Elec.Ch5.Value; Elec.Ch6.Value; Elec.Ch7.Value; Elec.Ch8.Value; ...
            Elec.Ch9.Value; Elec.Ch10.Value; Elec.Ch11.Value; Elec.Ch12.Value; ...
            Elec.Ch13.Value; Elec.Ch14.Value; Elec.Ch15.Value; Elec.Ch16.Value ...
        ];
        channelNumbers = 1:16;
        badChannels = channelNumbers(badChannels); % Extract selected bad channels
        if isempty(badChannels)
            badChannels = [];
        end
        delete(SelectBadChannels); % Close GUI
    else % If GUI was already closed (e.g., by using the close button)
        badChannels = []; % Return empty selection
    end

end

% -------------------------------------------------------------------------
% Event Functions
% -------------------------------------------------------------------------
% Button pushed function: Save button
function SaveButtonPushed(SelectBadChannels)
    uiresume(SelectBadChannels); % Resume from wait status
end