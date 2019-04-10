
local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Button = import('/lua/maui/button.lua').Button
local Checkbox = import('/lua/maui/checkbox.lua').Checkbox
local StatusBar = import('/lua/maui/statusbar.lua').StatusBar
local GameMain = import('/lua/ui/game/gamemain.lua')
local Tooltip = import('/lua/ui/game/tooltip.lua')
local Prefs = import('/lua/user/prefs.lua')
local Tooltip = import('/lua/ui/game/tooltip.lua')

local parent = false;

local pUI = {
	arrow = false,
	box = false
}

function CreateModUI(_parent)
    parent = _parent;

    BuildUI();
	SetLayout();
	CommonLogic();

	--ShowAlert({ "Welcome", "to the Zombie horde..." });
end

function BuildUI()
	-- Create arrow checkbox
	pUI.arrow = Checkbox(parent)

	-- Create group for main UI
	pUI.box = Group(parent)
	
	-- Create main UI objects
	pUI.box.panel = Bitmap(pUI.box)
	pUI.box.leftBracket = Bitmap(pUI.box)
	pUI.box.leftBracketGlow = Bitmap(pUI.box)

	pUI.box.rightGlowTop = Bitmap(pUI.box)
	pUI.box.rightGlowMiddle = Bitmap(pUI.box)
	pUI.box.rightGlowBottom = Bitmap(pUI.box)
	
	pUI.box.title = UIUtil.CreateText(pUI.box, '', 18, UIUtil.bodyFont)
	pUI.box.title:SetDropShadow(true)
	pUI.box.countdown = UIUtil.CreateText(pUI.box, '', 14, UIUtil.bodyFont)
	pUI.box.countdown:SetDropShadow(true)
end

function SetLayout()
	# Assign layout info to arrow checkbox
	pUI.arrow:SetTexture(UIUtil.UIFile('/game/tab-l-btn/tab-close_btn_up.dds'))
	pUI.arrow:SetNewTextures(UIUtil.UIFile('/game/tab-l-btn/tab-close_btn_up.dds'),
		UIUtil.UIFile('/game/tab-l-btn/tab-open_btn_up.dds'),
		UIUtil.UIFile('/game/tab-l-btn/tab-close_btn_over.dds'),
		UIUtil.UIFile('/game/tab-l-btn/tab-open_btn_over.dds'),
		UIUtil.UIFile('/game/tab-l-btn/tab-close_btn_dis.dds'),
		UIUtil.UIFile('/game/tab-l-btn/tab-open_btn_dis.dds'))
		
	LayoutHelpers.AtLeftTopIn(pUI.arrow, GetFrame(0), -3, 172)
	pUI.arrow.Depth:Set(function() return pUI.box.Depth() + 10 end)

	# Assign layout info to main UI
	pUI.box.panel:SetTexture(UIUtil.UIFile('/game/resource-panel/resources_panel_bmp.dds'))
	LayoutHelpers.AtLeftTopIn(pUI.box.panel, pUI.box)

	pUI.box.Height:Set(pUI.box.panel.Height)
	pUI.box.Width:Set(pUI.box.panel.Width)
	LayoutHelpers.AtLeftTopIn(pUI.box, parent, 16, 153)
	
	pUI.box:DisableHitTest()

	pUI.box.leftBracket:SetTexture(UIUtil.UIFile('/game/filter-ping-panel/bracket-left_bmp.dds'))
	pUI.box.leftBracketGlow:SetTexture(UIUtil.UIFile('/game/filter-ping-panel/bracket-energy-l_bmp.dds'))

	pUI.box.leftBracket.Right:Set(function() return pUI.box.panel.Left() + 10 end)
	pUI.box.leftBracketGlow.Left:Set(function() return pUI.box.leftBracket.Left() + 12 end)

	pUI.box.leftBracket.Depth:Set(pUI.box.panel.Depth)
	pUI.box.leftBracketGlow.Depth:Set(function() return pUI.box.leftBracket.Depth() - 1 end)

	LayoutHelpers.AtVerticalCenterIn(pUI.box.leftBracket, pUI.box.panel)
	LayoutHelpers.AtVerticalCenterIn(pUI.box.leftBracketGlow, pUI.box.panel)

	pUI.box.rightGlowTop:SetTexture(UIUtil.UIFile('/game/bracket-right-energy/bracket_bmp_t.dds'))
	pUI.box.rightGlowMiddle:SetTexture(UIUtil.UIFile('/game/bracket-right-energy/bracket_bmp_m.dds'))
	pUI.box.rightGlowBottom:SetTexture(UIUtil.UIFile('/game/bracket-right-energy/bracket_bmp_b.dds'))

	pUI.box.rightGlowTop.Top:Set(function() return pUI.box.Top() + 2 end)
	pUI.box.rightGlowTop.Left:Set(function() return pUI.box.Right() - 12 end)
	pUI.box.rightGlowBottom.Bottom:Set(function() return pUI.box.Bottom() - 2 end)
	pUI.box.rightGlowBottom.Left:Set(pUI.box.rightGlowTop.Left)
	pUI.box.rightGlowMiddle.Top:Set(pUI.box.rightGlowTop.Bottom)
	pUI.box.rightGlowMiddle.Bottom:Set(function() return math.max(pUI.box.rightGlowTop.Bottom(), pUI.box.rightGlowBottom.Top()) end)
	pUI.box.rightGlowMiddle.Right:Set(function() return pUI.box.rightGlowTop.Right() end)

	LayoutHelpers.AtLeftTopIn(pUI.box.title, pUI.box, 15, 10)
	pUI.box.title:SetColor('ffb7e75f')

	LayoutHelpers.AtLeftTopIn(pUI.box.countdown, pUI.box, 15, 41)
	pUI.box.countdown:SetColor('ffb7e75f')		
	
	# Hide panel
	pUI.box:Hide()
	pUI.arrow:SetCheck(true, true)
	pUI.box.Left:Set(parent.Left()-pUI.box.Width())

end

function CommonLogic()
	# Add heartbeat
	--GameMain.AddBeatFunction(MurderUIBeat)
	--GameMain.AddBeatFunction(InitMurderPanel)
	
	pUI.box.OnDestroy = function(self)
		--GameMain.RemoveBeatFunction(MurderUIBeat)
	end

	# Button Actions
	pUI.arrow.OnCheck = function(self, checked)
		ToggleZombiePanel()
	end

end

function ToggleZombiePanel(state)
	if import('/lua/ui/game/gamemain.lua').gameUIHidden and state != nil then
		return
	end

	if UIUtil.GetAnimationPrefs() then
		if state or pUI.box:IsHidden() then
			PlaySound(Sound({Cue = "UI_Score_Window_Open", Bank = "Interface"}))
			pUI.box:Show()			
			pUI.box:SetNeedsFrameUpdate(true)
			pUI.box.OnFrame = function(self, delta)
				local newLeft = self.Left() + (1000*delta)
				if newLeft > parent.Left()+14 then
					newLeft = parent.Left()+14
					self:SetNeedsFrameUpdate(false)
				end
				self.Left:Set(newLeft)
			end
			pUI.arrow:SetCheck(false, true)
		else
			PlaySound(Sound({Cue = "UI_Score_Window_Close", Bank = "Interface"}))
			pUI.box:SetNeedsFrameUpdate(true)
			pUI.box.OnFrame = function(self, delta)
				local newLeft = self.Left() - (1000*delta)
				if newLeft < parent.Left()-self.Width() then
					newLeft = parent.Left()-self.Width()
					self:SetNeedsFrameUpdate(false)
					self:Hide()
				end
				self.Left:Set(newLeft)
			end
			pUI.arrow:SetCheck(true, true)
		end
	else
		if state or pUI.box:IsHidden() then
			pUI.box:Show()
			
			pUI.arrow:SetCheck(false, true)
		else
			pUI.box:Hide()
			pUI.arrow:SetCheck(true, true)
		end
	end
end


function ShowAlert(args)
	SPEW("::Zombies:: Showing Alert")
	
	import('/lua/ui/game/announcement.lua').CreateAnnouncement(args[1], pUI.arrow, args[2])
end