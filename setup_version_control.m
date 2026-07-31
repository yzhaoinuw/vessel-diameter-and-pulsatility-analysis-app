function setup_version_control
%SETUP_VERSION_CONTROL Enable this repository's App Designer Git workflow.
%   Run once after cloning:
%       matlab -batch "setup_version_control"

    projectDir = fileparts(mfilename('fullpath'));
    hookFile = fullfile(projectDir, '.githooks', 'pre-commit');
    if ~isfile(hookFile)
        error('vessel_diameter_pulsatility_analysis_app:MissingGitHook', ...
            'Cannot find repository hook: %s', hookFile);
    end

    previousDir = pwd;
    cleanup = onCleanup(@() cd(previousDir));
    cd(projectDir);

    export_app_source;

    safeDirectory = strrep(projectDir, '\', '/');
    command = sprintf([ ...
        'git -c safe.directory="%s" config --local ' ...
        'core.hooksPath .githooks'], safeDirectory);
    [status, output] = system(command);
    if status ~= 0
        error('vessel_diameter_pulsatility_analysis_app:GitHookSetupFailed', ...
            'Could not configure the repository Git hooks:\n%s', output);
    end

    fprintf('Configured core.hooksPath=.githooks\n');
    fprintf('App Designer export workflow is ready.\n');
end
