--[[
	Copyright 2015-2023 surrim

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]--

function string_starts(String,Start)
	return string.sub(String,1,string.len(Start))==Start
end

function descriptor()
	return {
		title = "VLC Delete";
		version = "0.1";
		author = "surrim";
		url = "https://github.com/postmaxin/vlc-delete/";
		shortdesc = "&Move file on remote server";
		capabilities = {'menu'};
		description = [[
<h1>vlc-delete</h1>"
When you're playing a file, use VLC Delete to
delete the current file from your playlist <b>and filesystem</b> with one click.<br />
This extension has been tested on GNU Linux with VLC 2.x and 3.x.<br />
The author is not responsible for damage caused by this extension.
		]];
	}
end

--[[
  we are ssh'ing from Windows to Linux
  Command is bourne shell escaped for the SSH command to Linux
  then command is %-escaped for CMD.EXE
]]--
function ssh_escape(str)
	local s = tostring(str)
	if s:match("[^A-Za-z0-9_/:=-]") then
		s = "'"..s:gsub("'", "'\\''").."'"
		-- pattern has to be %-escaped for lua, so this actually
		-- converts all '%' to '%%'
		s = s:gsub("%%", "%%")
	end
	return s
end

function sleep(seconds)
	local t_0 = os.clock()
	while os.clock() - t_0 <= seconds do end
end

function remove_from_playlist()
	local id = vlc.playlist.current()
	vlc.playlist.next()
	sleep(1)
	vlc.playlist.delete(id)
end

function current_uri()
	local item = (vlc.player or vlc.input).item()
	local uri = item:uri()
	if uri:find("^file://") ~= nil then
		uri = vlc.strings.decode_uri(uri)
		uri = string.gsub(uri, "^file://", "")
		if not string_starts(uri, "/") then
			uri = "/" .. uri
		end
	end
	return uri
end

local ssh = "C:\\Windows\\System32\\OpenSSH\\ssh.exe"

function move_to_target(target)
	local uri = current_uri()
	vlc.msg.dbg("Moving target " .. uri)
	local escaped_uri = ssh_escape(uri)
	command = {
		ssh, 'faraway@192.168.2.68', '--', 'bin/vlc-remote-move',
		target, escaped_uri, '2^>^&1'}
	command_str = table.concat(command, " ")
	vlc.msg.dbg(command_str)
	local pipe = assert(io.popen(command_str))
	local output = pipe:read('*all')
	success, error_message, error_code = pipe:close()
	print(output)
	if success then
		vlc.msg.info(output)
	else
		vlc.msg.error("Command failed: " .. command_str)
		vlc.msg.error(output)
		vlc.msg.error("Error message: " .. error_message)

	end
	remove_from_playlist()
	vlc.osd.message("Moved to " .. target .. ": " .. uri)
end

local targets = {'keep', 'remove'}

function menu()
	return targets
end

function trigger_menu(target)
	move_to_target(targets[target])
end

function build_dialog()
	local target
	local move_targets = {'keep', 'remove'}
	move_dialog = vlc.dialog("Move where?")
	for i, target in ipairs(move_targets) do
		local move_function = function()
			move_to_target(target)
		end
		move_dialog:add_button(target, move_function)
	end
end

function activate()
end

function click_ok()
	d:delete()
	deactivate()
end

function deactivate()
	vlc.deactivate()
end

function close()
	deactivate()
end

function meta_changed()
end
