class CreateFeeder extends Task
{
    target_station_id   = null;
    industry_id         = null;
    cargo               = null;
    source_station_id   = null;

    constructor (target_station_id, industry_id, cargo)
    {
        Task.constructor(null, null);

        this.target_station_id  = target_station_id;
        this.industry_id        = industry_id;
        this.cargo              = cargo;
    }

    function _tostring ()
    {
        return "Build feed station";
    }

    function Run ()
    {
        local station_tile  = AIStation.GetLocation(target_station_id);
        local industry_tile = AIIndustry.GetLocation(industry_id);
        local direction     = StationDirection(industry_tile, station_tile);
        local rotation      = StationRotationForDirection(direction);
		local site          = FindIndustryStationSite(industry_id, 
                                                      true, 
                                                      rotation,
                                                      industry_tile);

        if (site == null)
        {
            Debug("can't find station site for industry");
            PutSign(industry_tile, "x");
            Help.mark_industry_unusable(industry_id);
            return false;
        }

        Help.register_ai_industry(industry_id);

        // NOTE: source_station_id is set when BuildFeederStation::Run is run
        subtasks =
        [
            BuildFeederStation(this, site, direction, 
                               industry_id, target_station_id, cargo, 6),
            BuildFeederTrain(this, target_station_id, cargo),
            BuildFeederTrain(this, target_station_id, cargo)
        ];

        RunSubtasks();
    }

    function Failed ()
    {
        Help.mark_industry_unusable(industry_id);
    }
}
