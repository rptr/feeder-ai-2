
class Station
{
    station_id      = null;
    industries      = null;
    is_full         = null;
    cargoes         = null;

    constructor (station_id)
    {
        this.station_id     = station_id;
        is_full             = false;

        find_cargoes();
        find_industries();
    }

    function find_cargoes ()
    {
        local all = get_raw_cargoes();
        cargoes = AIList();

        foreach (cargo_id, _ in all)
        {
            if (AIStation.HasCargoRating(station_id, cargo_id) || 
                SOAK_ALL_CARGOES)
            {
                Warning("have rating", cargo_id);
                cargoes.AddItem(cargo_id, 0);
            }
        }
    }

    function find_industries ()
    {
        local max_dist      = 500;
        local station_tile  = AIStation.GetLocation(station_id);

        industries = AIList();

        foreach (cargo_id, _ in cargoes)
        {
            industries.AddList(AIIndustryList_CargoProducing(cargo_id));
        }

        industries.Valuate(AITile.GetDistanceManhattanToTile, station_tile); 
        industries.KeepBelowValue(max_dist);

        Warning(industries.Count(), "nearby");
    }

    function get_cargo ()
    {
        find_cargoes();
        find_industries();

        return cargoes.Count() > 0 ? cargoes.Begin() : null;
    }
}

class Help
{
    // industries that the ai has used
    static ai_industries    = AIList();
    // stations that the ai has built
    static ai_stations      = AIList();
    // stations that the player has build
    static player_stations  = [];

}

function Help::register_ai_industry (industry_id)
{
    Help.ai_industries.AddItem(industry_id, 0);
}

function Help::register_ai_station (station_id)
{
    Help.ai_stations.AddItem(station_id, 0);
}

function Help::register_player_station (station_id)
{
    if (station_id >= Help.player_stations.len())
    {
        local new_len = max(Help.player_stations.len() * 2, station_id);
        Help.player_stations.resize(new_len);
    }

    Help.player_stations.insert(station_id, Station(station_id));
    Warning("found player station");
}

function Help::find_player_stations ()
{
    local all = AIStationList(AIStation.STATION_TRAIN);

    foreach (station, _ in all)
    {
        if (Help.ai_stations.HasItem(station) ||
            Help.is_player_station(station))
        {
            continue;
        }

        Help.register_player_station(station);
    }
}

/*
 * Returns a non-"full" station, i.e. one which still has nearby industries
 * which haven't been connected
 */
function Help::get_player_station_in_need ()
{
    Help.find_player_stations();

    foreach (station_id, station in Help.player_stations)
    {
        if (station == null || station.is_full)
            continue;

        return station;
    }

    return null;
}

function Help::is_player_station (station_id)
{
    return Help.player_stations.len() > station_id &&
           Help.player_stations[station_id] != null;
}

function Help::is_ai_station (station_id)
{
    return Help.ai_stations.HasItem(station_id);
}

/*
 * Returns an array of industries which should be "fed" to this station
 */
function Help::get_feed_industry (station_id)
{
    if (!Help.is_player_station(station_id))
    {
        Error("not player station");
        return null;
    }

    local all = Help.player_stations[station_id].industries;

    Help.player_stations[station_id].get_cargo();

    foreach (industry_id, _ in all)
    {
        if (Help.ai_industries.HasItem(industry_id))
        {
            continue;
        }

        return industry_id;
    }

    Debug("station has no industry");
    return null;
}

function Help::set_station_full (station_id, full)
{
    Help.player_stations.GetValue(station_id).is_full = true;
}
