--# selene: allow(unused_variable)
---@diagnostic disable: unused-local

-- A scrolling window manager. Inspired by PaperWM Gnome extension.
--
-- # Usage
--
-- `PaperWM:start()` will begin automatically tiling new and existing windows.
-- `PaperWM:stop()` will release control over windows.
-- `PaperWM::bindHotkeys()` will move / resize windows using keyboard shortcuts.
--
-- Here is an example Hammerspoon config:
--
-- ```
-- PaperWM = hs.loadSpoon("PaperWM")
-- PaperWM:bindHotkeys({
--     -- switch to a new focused window in tiled grid
--     focus_left  = {{"alt", "cmd"}, "left"},
--     focus_right = {{"alt", "cmd"}, "right"},
--     focus_up    = {{"alt", "cmd"}, "up"},
--     focus_down  = {{"alt", "cmd"}, "down"},
--
--     -- move windows around in tiled grid
--     swap_left  = {{"alt", "cmd", "shift"}, "left"},
--     swap_right = {{"alt", "cmd", "shift"}, "right"},
--     swap_up    = {{"alt", "cmd", "shift"}, "up"},
--     swap_down  = {{"alt", "cmd", "shift"}, "down"},
--
--     -- position and resize focused window
--     center_window       = {{"alt", "cmd"}, "c"},
--     full_width          = {{"alt", "cmd"}, "f"},
--     cycle_width         = {{"alt", "cmd"}, "r"},
--     reverse_cycle_width = {{"ctrl", "alt", "cmd"}, "r"},
--     cycle_height        = {{"alt", "cmd", "shift"}, "r"},
--    reverse_cycle_height = {{"ctrl", "alt", "cmd", "shift"}, "r"},
--
--     -- move focused window into / out of a column
--     slurp_in = {{"alt", "cmd"}, "i"},
--     barf_out = {{"alt", "cmd"}, "o"},
--
--     --- move the focused window into / out of the tiling layer
--     toggle_floating = {{"alt", "cmd", "shift"}, "escape"},
--
--     -- switch to a new Mission Control space
--     switch_space_1 = {{"alt", "cmd"}, "1"},
--     switch_space_2 = {{"alt", "cmd"}, "2"},
--     switch_space_3 = {{"alt", "cmd"}, "3"},
--     switch_space_4 = {{"alt", "cmd"}, "4"},
--     switch_space_5 = {{"alt", "cmd"}, "5"},
--     switch_space_6 = {{"alt", "cmd"}, "6"},
--     switch_space_7 = {{"alt", "cmd"}, "7"},
--     switch_space_8 = {{"alt", "cmd"}, "8"},
--     switch_space_9 = {{"alt", "cmd"}, "9"},
--
--     -- move focused window to a new space and tile
--     move_window_1 = {{"alt", "cmd", "shift"}, "1"},
--     move_window_2 = {{"alt", "cmd", "shift"}, "2"},
--     move_window_3 = {{"alt", "cmd", "shift"}, "3"},
--     move_window_4 = {{"alt", "cmd", "shift"}, "4"},
--     move_window_5 = {{"alt", "cmd", "shift"}, "5"},
--     move_window_6 = {{"alt", "cmd", "shift"}, "6"},
--     move_window_7 = {{"alt", "cmd", "shift"}, "7"},
--     move_window_8 = {{"alt", "cmd", "shift"}, "8"},
--     move_window_9 = {{"alt", "cmd", "shift"}, "9"}
-- })
-- PaperWM:start()
-- ```
--
-- Use `PaperWM:bindHotkeys(PaperWM.default_hotkeys)` for defaults.
--
-- Set `PaperWM.window_gap` to the number of pixels to space between windows and
-- the top and bottom screen edges.
--
-- Overwrite `PaperWM.window_filter` to ignore specific applications. For example:
--
-- ```
-- PaperWM.window_filter = PaperWM.window_filter:setAppFilter("Finder", false)
-- PaperWM:start() -- restart for new window filter to take effect
-- ```
--
-- Set `PaperWM.window_ratios` to the ratios to cycle window widths and heights
-- through. For example:
--
-- ```
-- PaperWM.window_ratios = { 1/3, 1/2, 2/3 }
-- ```
--
-- # Limitations
--
-- Under System Preferences -> Mission Control, unselect "Automatically
-- rearrange Spaces based on most recent use" and select "Displays have separate
-- Spaces".
--
-- MacOS does not allow a window to be moved fully off-screen. Windows that would
-- be tiled off-screen are placed in a margin on the left and right edge of the
-- screen. They are still visible and clickable.
--
-- It's difficult to detect when a window is dragged from one space or screen to
-- another. Use the move_window_N commands to move windows between spaces and
-- screens.
--
-- Arrange screens vertically to prevent windows from bleeding into other screens.
--
--
-- Download: [https://github.com/mogenson/PaperWM.spoon](https://github.com/mogenson/PaperWM.spoon)
---@class spoon.PaperWM
local M = {}
spoon.PaperWM = M

-- Adds a window to layout and tiles.
--
-- Parameters:
--  * add_window - An hs.window
--
-- Returns:
--  * The hs.spaces space for added window or nil if window not added.
function M:addWindow(add_window, ...) end

-- Removes current window from column and places it to the right
--
-- Parameters:
--  * None
function M:barfWindow() end

-- Binds hotkeys for PaperWM
--
-- Parameters:
--  * mapping - A table containing hotkey modifer/key details for the following items:
--   * stop_events - Stop automatic tiling
--   * refresh_windows - Refresh windows from window filter list
--   * toggle_floating - Add or remove window from floating layer
--   * focus_left - Focus window to left of current window
--   * focus_right - Focus window to right of current window
--   * focus_up - Focus window to up of current window
--   * focus_down - Focus window to down of current window
--   * swap_left - Swap positions of window to the left and current window
--   * swap_right - Swap positions of window to the right and current window
--   * swap_up - Swap positions of window above and current window
--   * swap_down - Swap positions of window below and current window
--   * center_window - Move current window to center of screen
--   * full_width - Resize width of current window to width of screen
--   * cycle_width - Toggle through preset window widths
--   * cycle_height - Toggle through preset window heights
--   * reverse_cycle_width - Toggle through preset window widths
--   * reverse_cycle_height - Toggle through preset window heights
--   * slurp_in - Move current window into column to the left
--   * barf_out - Remove current window from column and place to the right
--   * switch_space_l - Switch to Mission Control space to the left
--   * switch_space_r - Switch to Mission Control space to the right
--   * switch_space_1 - Switch to Mission Control space 1
--   * switch_space_2 - Switch to Mission Control space 2
--   * switch_space_3 - Switch to Mission Control space 3
--   * switch_space_4 - Switch to Mission Control space 4
--   * switch_space_5 - Switch to Mission Control space 5
--   * switch_space_6 - Switch to Mission Control space 6
--   * switch_space_7 - Switch to Mission Control space 7
--   * switch_space_8 - Switch to Mission Control space 8
--   * switch_space_9 - Switch to Mission Control space 9
--   * move_window_1 - Move current window to Mission Control space 1
--   * move_window_2 - Move current window to Mission Control space 2
--   * move_window_3 - Move current window to Mission Control space 3
--   * move_window_4 - Move current window to Mission Control space 4
--   * move_window_5 - Move current window to Mission Control space 5
--   * move_window_6 - Move current window to Mission Control space 6
--   * move_window_7 - Move current window to Mission Control space 7
--   * move_window_8 - Move current window to Mission Control space 8
--   * move_window_9 - Move current window to Mission Control space 9
function M.bindHotkeys(mapping, ...) end

-- Moves current window to center of screen, without resizing.
--
-- Parameters:
--  * None
function M:centerWindow() end

-- Resizes current window by cycling through width or height ratios.
--
-- Parameters:
--  * direction - One of Direction { WIDTH, HEIGHT }
--  * cycle_direction - One of Direction { ASCENDING, DESCENDING }
function M:cycleWindowSize(direction, cycle_direction, ...) end

-- Default hotkeys for moving / resizing windows
M.default_hotkeys = nil

-- Change focus to a nearby window
--
-- Parameters:
--  * direction - One of Direction { LEFT, RIGHT, DOWN, UP }
--  * focused_index - The coordinates of the current window in the tiling layout
--
-- Returns:
--  * A boolean. True if a new window was focused. False if no nearby window
--    was found in that direction.
function M:focusWindow(direction, focused_index, ...) end

-- Switch to a Mission Control space to the left or right of current space
--
-- Parameters:
--  * direction - One of Direction { LEFT, RIGHT }
function M:incrementSpace(direction, ...) end

-- Logger object. Can be accessed to set default log level.
M.logger = nil

-- Resizes a window without triggering a windowMoved event
--
-- Parameters:
--  * window - An hs.window
--  * frame - An hs.geometry.rect for the windows new frame size.
function M::moveWindow(window, frame, ...) end

-- Moves the current window to a new Mission Control space
--
-- Parameters:
--  * index - The space number
--  * window - Optional window to move
function M:moveWindowToSpace(index, window, ...) end

-- Searches for all windows that match window filter.
--
-- Parameters:
--  * None
--
-- Returns:
--  * A boolean, true if the layout needs to be re-tiled, false if no change.
function M:refreshWindows() end

-- Remove window from tiling layout
--
-- Parameters:
--  * remove_window - A hs.window to remove from tiling layout
--  * skip_new_window_focus - A boolean. True if a nearby window should not be
--                            focused after current window is removed.
--
-- Returns:
--  * The hs.spaces space for removed window.
function M:remove_window(remove_window, skip_new_window_focus, ...) end

-- Resizes current window's width to width of screen, without adjusting height.
--
-- Parameters:
--  * None
function M:setWindowFullWidth() end

-- Moves current window into column of windows to the left
--
-- Parameters:
--  * None
function M:slurpWindow() end

-- Start automatic tiling of windows
--
-- Parameters:
--  * None
--
-- Returns:
--  * The PaperWM object
function M:start() end

-- Stop automatic tiling of windows
--
-- Parameters:
--  * None
--
-- Returns:
--  * The PaperWM object
function M:stop() end

-- Swaps window postions between current window and window in specified direction.
--
-- Parameters:
--  * direction - One of Direction { LEFT, RIGHT, DOWN, UP }
function M:swapWindows(direction, ...) end

-- Switch to a Mission Control space
--
-- Parameters:
--  * index - The space number
function M:switchToSpace(index, ...) end

-- Tile a column of windows
--
-- Parameters:
--  * windows - A list of hs.windows.
--  * bounds - An hs.geometry.rect. The area for this column to fill.
--  * h - The height for each window in column.
--  * w - The width for each window in column.
--  * id - A hs.window.id() for a specific window in column.
--  * h4id - The height for a window matching id in column.
--
-- Notes:
--  * The h, w, id, and h4id parameters are optional. The height and width of
--    all windows will be calculated and set to fill column bounds.
--  * If bounds width is not specified, all windows in column will be resized
--    to width of first window.
--
-- Returns:
--  * The width of the column
function M:tileColumn(windows, bounds, h, w, id, h4id, ...) end

-- Tile all windows within a space
--
-- Parameters:
--  * space - A hs.spaces space.
function M:tileSpace(space, ...) end

-- Add or remove focused window from the floating layer and retile the space
--
-- Parameters:
--  * None
function M:toggleFloating() end

-- Windows captured by this filter are automatically tiled and managed
M.window_filter = nil

-- Number of pixels between tiled windows
M.window_gap = nil

-- Size of the on-screen margin to place off-screen windows
M.window_ratios = nil

