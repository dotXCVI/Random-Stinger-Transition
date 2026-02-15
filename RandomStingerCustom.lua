obs = obslua
video_folder = ""
video_files = {}
played_videos = {}
transition_in_progress = false
target_transition_name = ""

function script_description()
    return [[Random Stinger Transition Script with Smart Rotation

Randomly selects stinger videos from a folder and applies them to a specific stinger transition.
Prioritizes stingers that haven't been played yet this session.

Filename format: anything_XXXms.ext (e.g., "explosion_500ms.webm")
The number before "ms" will be used as the transition point in milliseconds.
If no timing is found in filename, defaults to 500ms.

Select which Stinger transition to apply random videos to. Other transitions work normally.]]
end

function script_properties()
    local props = obs.obs_properties_create()
    
    obs.obs_properties_add_path(props, "folder", "Stinger Video Folder", 
        obs.OBS_PATH_DIRECTORY, "", nil)
    
    -- Dropdown to select which transition to apply random stingers to
    local transition_list = obs.obs_properties_add_list(props, "target_transition", 
        "Target Stinger Transition", obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
    
    -- Populate with available transitions
    local transitions = obs.obs_frontend_get_transitions()
    if transitions ~= nil then
        for _, transition in ipairs(transitions) do
            local name = obs.obs_source_get_name(transition)
            local id = obs.obs_source_get_id(transition)
            
            -- Only show stinger transitions
            if id == "obs_stinger_transition" then
                obs.obs_property_list_add_string(transition_list, name, name)
            end
        end
        obs.source_list_release(transitions)
    end
    
    obs.obs_properties_add_button(props, "refresh", "Refresh Video List", refresh_clicked)
    
    obs.obs_properties_add_button(props, "reset", "Reset Rotation", reset_rotation_clicked)
    
    return props
end

function script_defaults(settings)
    obs.obs_data_set_default_string(settings, "folder", "")
    obs.obs_data_set_default_string(settings, "target_transition", "")
end

function script_update(settings)
    video_folder = obs.obs_data_get_string(settings, "folder")
    target_transition_name = obs.obs_data_get_string(settings, "target_transition")
    
    obs.script_log(obs.LOG_INFO, string.format("Target transition set to: '%s'", target_transition_name))
    scan_folder()
end

function refresh_clicked(props, p)
    scan_folder()
    return true
end

function reset_rotation_clicked(props, p)
    played_videos = {}
    obs.script_log(obs.LOG_INFO, "Stinger rotation reset - all videos marked as unplayed")
    return true
end

function scan_folder()
    video_files = {}
    
    if video_folder == "" then 
        obs.script_log(obs.LOG_INFO, "No folder selected")
        return 
    end
    
    local extensions = {".mp4", ".webm", ".mov", ".mkv", ".avi"}
    
    local handle = obs.os_opendir(video_folder)
    if handle then
        local entry = obs.os_readdir(handle)
        while entry do
            if not entry.directory then
                local filename = entry.d_name
                local is_video = false
                
                for _, ext in ipairs(extensions) do
                    if filename:lower():sub(-#ext) == ext then
                        is_video = true
                        break
                    end
                end
                
                if is_video then
                    local full_path = video_folder .. "/" .. filename
                    table.insert(video_files, {
                        path = full_path,
                        name = filename,
                        transition_point = get_transition_point(filename)
                    })
                end
            end
            entry = obs.os_readdir(handle)
        end
        obs.os_closedir(handle)
    end
    
    obs.script_log(obs.LOG_INFO, string.format("Found %d stinger videos", #video_files))
    
    for i, video in ipairs(video_files) do
        obs.script_log(obs.LOG_INFO, string.format("  %s (transition: %dms)", 
            video.name, video.transition_point))
    end
    
    -- Reset played videos when rescanning
    played_videos = {}
end

function get_transition_point(filename)
    local ms = filename:match("_(%d+)ms")
    if ms then
        return tonumber(ms)
    end
    
    ms = filename:match("(%d+)ms")
    if ms then
        return tonumber(ms)
    end
    
    return 500
end

function get_unplayed_videos()
    local unplayed = {}
    
    for i, video in ipairs(video_files) do
        local is_played = false
        
        -- Check if this video path has been played
        for played_path, _ in pairs(played_videos) do
            if played_path == video.path then
                is_played = true
                break
            end
        end
        
        if not is_played then
            table.insert(unplayed, video)
        end
    end
    
    return unplayed
end

function find_transition_by_name(name)
    if name == "" then
        return nil
    end
    
    -- Search through all transitions
    local transitions = obs.obs_frontend_get_transitions()
    if transitions == nil then
        return nil
    end
    
    local found_transition = nil
    
    for _, t in ipairs(transitions) do
        local transition_name = obs.obs_source_get_name(t)
        if transition_name == name then
            found_transition = t
            break
        end
    end
    
    -- Don't release the list yet - we're returning a reference from it
    -- The caller must release the transition list after using the transition
    return found_transition, transitions
end

function set_random_stinger()
    if #video_files == 0 then 
        obs.script_log(obs.LOG_WARNING, "No stinger videos found")
        return 
    end
    
    if target_transition_name == "" then
        obs.script_log(obs.LOG_WARNING, "No target transition selected")
        return
    end
    
    local unplayed = get_unplayed_videos()
    
    -- Debug: Log current state
    obs.script_log(obs.LOG_DEBUG, string.format("Total videos: %d, Unplayed: %d, Played: %d", 
        #video_files, #unplayed, table_length(played_videos)))
    
    if #unplayed == 0 then
        obs.script_log(obs.LOG_INFO, "All stingers played! Resetting rotation...")
        played_videos = {}
        unplayed = get_unplayed_videos()
    end
    
    local random_index = math.random(#unplayed)
    local selected_video = unplayed[random_index]
    
    -- Mark as played
    played_videos[selected_video.path] = true
    
    local remaining = #unplayed - 1
    obs.script_log(obs.LOG_INFO, string.format("Queued next stinger: %s (transition: %dms) [%d unplayed remaining]", 
        selected_video.name, selected_video.transition_point, remaining))
    
    -- Get the specific transition by name
    local transition, transitions_list = find_transition_by_name(target_transition_name)
    
    if transition ~= nil then
        local transition_id = obs.obs_source_get_id(transition)
        
        if transition_id == "obs_stinger_transition" then
            local settings = obs.obs_source_get_settings(transition)
            
            obs.obs_data_set_string(settings, "path", selected_video.path)
            obs.obs_data_set_int(settings, "transition_point", selected_video.transition_point)
            
            obs.obs_source_update(transition, settings)
            
            obs.obs_data_release(settings)
            obs.script_log(obs.LOG_DEBUG, "✓ Successfully updated stinger")
        else
            obs.script_log(obs.LOG_WARNING, string.format("'%s' is not a Stinger transition (type: %s)", 
                target_transition_name, transition_id))
        end
        
        -- Release the transitions list
        obs.source_list_release(transitions_list)
    else
        obs.script_log(obs.LOG_WARNING, string.format("Could not find transition named '%s'", target_transition_name))
        if transitions_list ~= nil then
            obs.source_list_release(transitions_list)
        end
    end
end

function table_length(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

function frontend_event(event)
    -- Only proceed if we have a target transition set
    if target_transition_name == "" then
        return
    end
    
    -- Check if the current transition is our target
    local current_transition = obs.obs_frontend_get_current_transition()
    if current_transition == nil then
        return
    end
    
    local current_name = obs.obs_source_get_name(current_transition)
    obs.obs_source_release(current_transition)
    
    -- Only update if the current transition matches our target
    if current_name ~= target_transition_name then
        return
    end
    
    -- When transition stops, update the next stinger after a delay
    if event == obs.OBS_FRONTEND_EVENT_TRANSITION_STOPPED then
        obs.script_log(obs.LOG_DEBUG, string.format("Transition '%s' stopped - scheduling stinger update", current_name))
        
        -- Longer delay to ensure OBS has fully cleaned up the previous transition
        -- This prevents the brief flash of the next stinger
        obs.timer_add(update_stinger_delayed, 1000)
    end
end

function update_stinger_delayed()
    obs.timer_remove(update_stinger_delayed)
    set_random_stinger()
end

function script_load(settings)
    obs.obs_frontend_add_event_callback(frontend_event)
    obs.script_log(obs.LOG_INFO, "Random Stinger script loaded")
    
    -- Set initial stinger after a short delay to ensure OBS is fully loaded
    obs.timer_add(initial_stinger_delayed, 1000)
end

function initial_stinger_delayed()
    obs.timer_remove(initial_stinger_delayed)
    set_random_stinger()
end

function script_unload()
    obs.script_log(obs.LOG_INFO, "Random Stinger script unloaded")
end