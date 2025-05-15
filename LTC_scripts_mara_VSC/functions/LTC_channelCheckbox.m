function [badChannels] = LTC_channelCheckbox(preFlaggedBadChannels)
    % LTC_channelCheckbox (figure-based version)
    % A GUI for selecting bad channels (1–16) using checkboxes.
    % Optionally pre-selects certain channels.
    %
    % Usage:
    %   badChannels = LTC_channelCheckbox();
    %   badChannels = LTC_channelCheckbox([2, 5, 7]);
    
    if nargin < 1
        preFlaggedBadChannels = [];
    end

    % Create traditional figure window
    SelectBadChannels = figure('Name', 'Select bad channels', ...
        'Position', [150, 400, 375, 215], ...
        'NumberTitle', 'off', ...
        'MenuBar', 'none', ...
        'ToolBar', 'none');

    % Set up channel positions
    positions = [ ...
        45, 150; 125, 150; 205, 150; 285, 150; ... % Row 1
        45, 125; 125, 125; 205, 125; 285, 125; ... % Row 2
        45, 100; 125, 100; 205, 100; 285, 100; ... % Row 3
        45,  75; 125,  75; 205,  75; 285,  75  ... % Row 4
    ];

    % Create checkboxes for 16 channels
    Elec = gobjects(1, 16);  % preallocate graphics array
    for i = 1:16
        Elec(i) = uicontrol(SelectBadChannels, ...
            'Style', 'checkbox', ...
            'String', ['Ch' num2str(i)], ...
            'Position', [positions(i, 1), positions(i, 2), 80, 15], ...
            'Value', ismember(i, preFlaggedBadChannels));
    end

    % Create Save button
    uicontrol(SelectBadChannels, ...
        'Style', 'pushbutton', ...
        'String', 'Save', ...
        'Position', [137 27 101 21], ...
        'Callback', @(src, event) uiresume(SelectBadChannels));

    % Wait for button press
    uiwait(SelectBadChannels);

    % Collect selected channels
    if ishandle(SelectBadChannels)
        values = arrayfun(@(cb) get(cb, 'Value'), Elec);
        badChannels = find(values);
        delete(SelectBadChannels);
    else
        badChannels = [];
    end
end
