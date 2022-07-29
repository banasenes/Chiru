    local orig_exec = MissionScriptElement.on_executed
    function MissionScriptElement:on_executed(...)
    	orig_exec(self, ...)
    	if not Network:is_server() then
    		return
    	end
     
    	if Global.level_data.level_id == "rat" then
    		managers.mission._scripts["default"]._elements[100486]._values.enabled = true
    		-- uncomment these to make the lab always spawn in the basement
    		 managers.mission._scripts["default"]._elements[100483]._values.enabled = false -- 2nd floor
    		 managers.mission._scripts["default"]._elements[100485]._values.enabled = false -- 1st floor
    	end
    end