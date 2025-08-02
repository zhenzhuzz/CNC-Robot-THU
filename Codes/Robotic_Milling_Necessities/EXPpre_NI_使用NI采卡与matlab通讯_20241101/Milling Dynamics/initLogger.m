% Subfunction to initialize logger arrays
function logger = initLogger(params)

    logger.Forcex = zeros(1, params.totalSteps);
    logger.Forcey = zeros(1, params.totalSteps);
    logger.xpos   = zeros(1, params.totalSteps);
    logger.ypos   = zeros(1, params.totalSteps);
    logger.xvel   = zeros(1, params.totalSteps);
    logger.yvel   = zeros(1, params.totalSteps);

end