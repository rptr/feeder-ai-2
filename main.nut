require("util.nut");
require("pathfinder.nut");
require("world.nut");
require("signs.nut");
require("task.nut");
require("finance.nut");
require("builder.nut");
require("planner.nut");
require("manager.nut");
require("vehicles.nut");

require("help.nut");

const MIN_DISTANCE =  30;
const MAX_DISTANCE = 100;
const MAX_BUS_ROUTE_DISTANCE = 40;
const INDEPENDENTLY_WEALTHY = 1000000;	// no longer need a loan

const CARGO_STATION_LENGTH = 6;

const SOAK_ALL_CARGOES  = 0;
const MAX_SOAK_PER_STATION = 30;
const SOAK_DISTANCE     = 200;

enum Direction {
	N, E, S, W, NE, NW, SE, SW
}

// counterclockwise
enum Rotation {
	ROT_0, ROT_90, ROT_180, ROT_270
}

enum SignalMode {
	NONE, FORWARD, BACKWARD
}

class HelperAI extends AIController
{
	function Start()
    {
		AICompany.SetAutoRenewStatus(true);
		AICompany.SetAutoRenewMonths(0);
		AICompany.SetAutoRenewMoney(0);
	
		AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);
		
		::COMPANY <- AICompany.ResolveCompanyID(AICompany.COMPANY_SELF);
		::PAX <- GetPassengerCargoID();
		::MAIL <- GetMailCargoID();
		::TICKS_PER_DAY <- 37;
		::SIGN1 <- -1;
		::SIGN2 <- -1;
		
		::tasks <- [];
		
		/* CheckGameSettings(); */
		
		AIRail.SetCurrentRailType(AIRailTypeList().Begin());
	    //CalculateRoutes();
		
		local minMoney = 0;
		local year = 0;
		while (true)
        {
			HandleEvents();

			if (tasks.len() == 0)
            {
				tasks.push(LookForWork());
                HelperAI.Sleep(10);
			}
			
			/* Debug("Tasks: " + ArrayToString(tasks)); */
			
			local task;

			try
            {
				if (minMoney > 0) WaitForMoney(minMoney);
				minMoney = 0;
				
				// run the next task in the queue
				task = tasks[0];
				/* Debug("Running: " + task); */
				task.Run();
				tasks.remove(0);
                ResetSign();
			}
            catch (e)
            {
                task.Failed();  

				if (typeof(e) == "instance")
                {
					if (e instanceof TaskRetryException)
                    {
						Sleep(e.sleep);
						Debug("Retrying...");
					}
                    else if (e instanceof TaskFailedException)
                    {
						Warning(task + " failed: " + e);
						tasks.remove(0);
						task.Failed();
					}
                    else if (e instanceof NeedMoneyException)
                    {
						Debug(task + " needs �" + e.amount);
						minMoney = e.amount;
					}
				}
                else
                {
					Error("Unexpected error");
					return;
				}
			}
		}
	}
	
	function WaitForMoney(amount)
    {
		local reserve = GetMinimumSafeMoney();
		local autorenew = GetAutoRenewMoney();
		local total = amount + reserve + autorenew;
		
		Debug("Waiting until we have �" + total + " (�" + amount + " to spend plus �" + reserve + " in reserve and �" + autorenew + " for autorenew)");
		MaxLoan();
		while (GetBankBalance() < amount) {
			local percentage = (100 * GetBankBalance()) / total;
			local bar = "";
			for (local i = 0; i < 100; i += 10) {
				if (percentage > i) {
					bar += "I";
				} else {
					bar += ".";
				}
			}
			
			// maximum sign length is 30 characters; pound sign seems to require two (bytes?)
			local currency = total >= 100000 ? "" : "�";
			SetSecondarySign("Money: need " + currency + total/1000 + "K [" + bar + "]");
			
			FullyMaxLoan();
			HandleEvents();
			Sleep(TICKS_PER_DAY);
			MaxLoan();
		}
		
		ClearSecondarySign();
	}
	
	function HandleEvents() {
		while (AIEventController.IsEventWaiting()) {
  			local e = AIEventController.GetNextEvent();
  			local converted;
  			local vehicle;
  			switch (e.GetEventType()) {
  				case AIEvent.AI_ET_VEHICLE_UNPROFITABLE:
  					converted = AIEventVehicleUnprofitable.Convert(e);
  					vehicle = converted.GetVehicleID();
  					Cull(vehicle);
  					break;
  					
				case AIEvent.AI_ET_VEHICLE_WAITING_IN_DEPOT:
					converted = AIEventVehicleWaitingInDepot.Convert(e);
					vehicle = converted.GetVehicleID();
					Warning("Selling: " + AIVehicle.GetName(vehicle));
					AIVehicle.SellVehicle(vehicle);
					break;
				
      			default:
      				// Debug("Unhandled event:" + e);
  			}
		}
	}
	
	function CheckGameSettings() {
		local ok = true;
		ok = CheckSetting("construction.road_stop_on_town_road", 1,
			"Advanced Settings, Stations, Allow drive-through road stations on town owned roads") && ok;
		ok = CheckSetting("station.distant_join_stations", 1,
			"Advanced Settings, Stations, Allow to join stations not directly adjacent") && ok;
		
		if (ok) {
			Debug("Game settings OK");
		} else {
			throw "ChooChoo is not compatible with current game settings.";
		}
	}
	
	function CheckSetting(name, value, description) {
		if (!AIGameSettings.IsValid(name)) {
			Warning("Setting " + name + " does not exist! ChooChoo may not work properly.");
			return true;
		}
		
		local gameValue = AIGameSettings.GetValue(name);
		if (gameValue == value) {
			return true;
		} else {
			Warning(name + " is " + (gameValue ? "on" : "off"));
			Warning("You can change this setting under " + description);
			return false;
		}
	}

    function add_task (task)
    {
        tasks.push(task);
    }
	
	function Save() {
		return {};
	}

	function Load(version, data) {}
}

class LookForWork extends Task
{
	
	function _tostring() {
		return "Look for work";
	}
	
	function Run()
    {
        local station = Help.get_player_station_in_need();

        if (station == null)
        {
            /* Debug("no stations to help"); */
            return false;
        }

        local industry_id  = Help.get_feed_industry(station.station_id);
        
        if (industry_id == null)
        {
            /* Debug("no nearby industries"); */
            return false;
        }

        if (!AIIndustry.IsValidIndustry(industry_id))
        {
            Warning("invalid industry");
            return false;
        }

        local cargoes   = AICargoList_IndustryProducing(industry_id);
        local cargo     = cargoes.Begin();
        local task      = CreateFeeder(station.station_id, 
                                       industry_id, 
                                       cargo)
        HelperAI.add_task(task);
	}
	
}

