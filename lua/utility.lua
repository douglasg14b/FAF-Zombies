
------------------------------------------------------------------------
----- Script by CookieNoob and KeyBlue (modified by svenni_badbwoi)-----
------------------------------------------------------------------------

local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Group = import('/lua/maui/group.lua').Group
local Checkbox = import('/lua/maui/checkbox.lua').Checkbox

------------------------------------------------------------------------
----- Message part -----------------------------------------------------
------------------------------------------------------------------------
function BroadcastMSG(message, fontsize, RGBColor, duration, location)
    ----------------------------------------
    -- broadcast a text message to players
    -- possible locations = lefttop, leftcenter, leftbottom,  righttop, rightcenter, rightbottom, rightbottom, centertop, center, centerbottom
    ----------------------------------------
    PrintText(message, fontsize, 'ff' .. RGBColor, duration , location);
end


