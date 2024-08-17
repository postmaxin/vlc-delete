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

function descriptor()
	return {
		title = "VLC Delete";
		version = "0.1";
		author = "surrim";
		url = "https://github.com/postmaxin/vlc-delete/";
		shortdesc = "&Move file on remote server";
		description = [[
<h1>vlc-delete</h1>"
When you're playing a file, use VLC Delete to
delete the current file from your playlist <b>and filesystem</b> with one click.<br />
This extension has been tested on GNU Linux with VLC 2.x and 3.x.<br />
The author is not responsible for damage caused by this extension.
		]];
	}
end

function shell_escape(args)
	local ret = {}
	for _,a in pairs(args) do
		s = tostring(a)
		if s:match("[^A-Za-z0-9_/:=-]") then
			s = "'"..s:gsub("'", "'\\''").."'"
		end
		table.insert(ret,s)
	end
	return table.concat(ret, " ")
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

function current_uri_and_os()
	local item = (vlc.player or vlc.input).item()
	local uri = item:uri()
	local is_posix = (package.config:sub(1, 1) == "/")
	if uri:find("^file:///") ~= nil then
		uri = string.gsub(uri, "^file:///", "")
		uri = vlc.strings.decode_uri(uri)
		uri = "/" .. uri
	end
	return uri, is_posix
end

local move_dialog = nil

function move_to_target(target)
	move_dialog:hide()
	local uri, is_posix = current_uri_and_os()
	local escaped_uri = shell_escape(uri)
	local pipe = assert(io.popen(
		'ssh', 'faraway@192.168.2.68', 'vlc-remote-move', target, escaped_uri))
	local output = pipe:read('*all')
	success, error_message, error_code = pipe:close()
	print(output)
	if success then
		vlc.msg.info(output)
	else
		vlc.msg.error(output)
		vlc.msg.error("Error message: " .. error_message)
	end
	remove_from_playlist()
end

function build_dialog()
	local move_targets = {'keep', 'remove'}
	move_dialog = vlc.dialog("Move where?")
	for target in move_targets do
		local move_function = function()
			move_to_target(target)
		end
		move_dialog:add_button(target, move_function)
	end
end

function activate()
	if not move_dialog then
		build_dialog()
	end
	move_dialog:show()
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
