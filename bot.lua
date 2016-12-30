package.path = package.path .. ';.luarocks/share/lua/5.2/?.lua'
  .. ';.luarocks/share/lua/5.2/?/init.lua'
package.cpath = package.cpath .. ';.luarocks/lib/lua/5.2/?.so'


tdcli = dofile('tdcli.lua')
redis = (loadfile "./libs/redis.lua")()

sudo_users = {
  90285047,
  0
}

-- Print message format. Use serpent for prettier result.
function vardump(value, depth, key)
  local linePrefix = ''
  local spaces = ''

  if key ~= nil then
    linePrefix = key .. ' = '
  end

  if depth == nil then
    depth = 0
  else
    depth = depth + 1
    for i=1, depth do 
      spaces = spaces .. '  '
    end
  end

  if type(value) == 'table' then
    mTable = getmetatable(value)
    if mTable == nil then
      print(spaces .. linePrefix .. '(table) ')
    else
      print(spaces .. '(metatable) ')
        value = mTable
    end
    for tableKey, tableValue in pairs(value) do
      vardump(tableValue, depth, tableKey)
    end
  elseif type(value)  == 'function' or 
    type(value) == 'thread' or 
    type(value) == 'userdata' or 
    value == nil then --@MuteTeam
      print(spaces .. tostring(value))
  elseif type(value)  == 'string' then
    print(spaces .. linePrefix .. '"' .. tostring(value) .. '",')
  else
    print(spaces .. linePrefix .. tostring(value) .. ',')
  end
end

-- Print callback
function dl_cb(arg, data)
  vardump(arg)
  vardump(data)
end

function is_sudo(msg)
  local var = false
  -- Check users id in config
  for v,user in pairs(sudo_users) do
    if user == msg.sender_user_id_ then
      var = true
    end
  end
  return var
end


function tdcli_update_callback(data)
  vardump(data)

  if (data.ID == "UpdateNewMessage") then
    local msg = data.message_
    local input = msg.content_.text_
    local chat_id = msg.chat_id_
    local user_id = msg.sender_user_id_
    local reply_id = msg.reply_to_message_id_
    vardump(msg)
    if msg.content_.ID == "MessageText" then
      if input == "ping" then
        tdcli.sendMessage(chat_id, msg.id_, 1, '<code>pong</code>', 1, 'html')
      end
      if input == "PING" then
        tdcli.sendMessage(chat_id, msg.id_, 1, '<b>PONG</b>', 1, 'html')
      end
      if input:match("^[#!/][Ii][Dd]$") then
        tdcli.sendMessage(chat_id, msg.id_, 1, '<b>Chat ID : </b><code>'..string.sub(chat_id, 5,14)..'</code>\n<b>Your ID : </b><code>'..user_id..'</code>', 1, 'html')
      end

      if input:match("^[#!/][Pp][Ii][Nn]") and reply_id then
        tdcli.sendMessage(chat_id, msg.id_, 1, '<b>Done!</b>', 1, 'html')
        tdcli.pinChannelMessage(chat_id, reply_id, 1)
      end

      if input:match("^[#!/][Uu][Nn][Pp][Ii][Nn]") and reply_id then
        tdcli.sendMessage(chat_id, msg.id_, 1, '<b>Done!</b>', 1, 'html')
        tdcli.unpinChannelMessage(chat_id, reply_id, 1)
      end

      if input:match("^[#!/][Ll]ock link$") and is_sudo(msg) then
       if redis:get('llink:'..chat_id) then
        tdcli.sendMessage(chat_id, msg.id_, 1, '<b>Error!</b>\n<i>>Link Posting Is Already Not Allowed Here.</i>', 1, 'html')
       else 
        redis:set('llink:'..chat_id, true)
        tdcli.sendMessage(chat_id, msg.id_, 1, '<b>Done!</b>\n<i>>Now Link Posting Is Not Allowed Here.</i>', 1, 'html')
      end
      end 
      if input:match("^[#!/][Uu]nlock link$") and is_sudo(msg) then
       if not redis:get('llink:'..chat_id) then
        tdcli.sendMessage(chat_id, msg.id_, 1, '<b>Error!</b>\n<i>>Link Posting Is Already Allowed Here.</i>', 1, 'html')
       else
         redis:del('llink:'..chat_id)
        tdcli.sendMessage(chat_id, msg.id_, 1, '<b>Done!</b>\n<i>>Now Link Posting Is Allowed Here.</i>', 1, 'html')
      end
      end
      if redis:get('llink:'..chat_id) and input:match("[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm].[Mm][Ee]/") then
        tdcli.deleteMessages(chat_id, {[0] = msg.id_})
      end
		
	if input:match("^[#!/][Ll]ock fwd$") and is_sudo(msg) then
       if redis:get('lfwd:'..chat_id) then
        tdcli.sendMessage(chat_id, msg.id_, 1, '<b>Error!</b>\n<i>>Fwd Posting Is Already Not Allowed Here.</i>', 1, 'html')
       else 
        redis:set('lfwd:'..chat_id, true)
        tdcli.sendMessage(chat_id, msg.id_, 1, '<b>Done!</b>\n<i>>Now Fwd Posting Is Not Allowed Here.</i>', 1, 'html')
      end
      end 
      if input:match("^[#!/][Uu]nlock fwd$") and is_sudo(msg) then
       if not redis:get('lfwd:'..chat_id) then
        tdcli.sendMessage(chat_id, msg.id_, 1, '<b>Error!</b>\n<i>>Fwd Posting Is Already Allowed Here.</i>', 1, 'html')
       else
         redis:del('lfwd:'..chat_id)
        tdcli.sendMessage(chat_id, msg.id_, 1, '<b>Done!</b>\n<i>>Now Fwd Posting Is Allowed Here.</i>', 1, 'html')
      end
      end		
	if redis:get('lfwd:'..chat_id) and msg.forward_info_ and not is_sudo(msg) then
	tdcli.deleteMessages(chat_id, {[0] = msg.id_})
      end
		
	if input:match("^[#!/][Ll]ock tag$") and is_sudo(msg) then
       if redis:get('ltag:'..chat_id) then
        tdcli.sendMessage(chat_id, msg.id_, 1, '<b>Error!</b>\n<i>>Tag Posting Is Already Not Allowed Here.</i>', 1, 'html')
       else 
        redis:set('ltag:'..chat_id, true)
        tdcli.sendMessage(chat_id, msg.id_, 1, '<b>Done!</b>\n<i>>Now Tag Posting Is Not Allowed Here.</i>', 1, 'html')
      end
      end 
      if input:match("^[#!/][Uu]nlock tag$") and is_sudo(msg) then
       if not redis:get('ltag:'..chat_id) then
        tdcli.sendMessage(chat_id, msg.id_, 1, '<b>Error!</b>\n<i>>Tag Posting Is Already Allowed Here.</i>', 1, 'html')
       else
         redis:del('ltag:'..chat_id)
        tdcli.sendMessage(chat_id, msg.id_, 1, '<b>Done!</b>\n<i>>Now Tag Posting Is Allowed Here.</i>', 1, 'html')
      end
      end
      if redis:get('ltag:'..chat_id) and input:match("@") then
        tdcli.deleteMessages(chat_id, {[0] = msg.id_})
      end	
		
	if input:match("^[#!/][Ll]ock hashtag$") and is_sudo(msg) then
       if redis:get('lhashtag:'..chat_id) then
        tdcli.sendMessage(chat_id, msg.id_, 1, '<b>Error!</b>\n<i>>HashTag Posting Is Already Not Allowed Here.</i>', 1, 'html')
       else 
        redis:set('lhashtag:'..chat_id, true)
        tdcli.sendMessage(chat_id, msg.id_, 1, '<b>Done!</b>\n<i>>Now HashTag Posting Is Not Allowed Here.</i>', 1, 'html')
      end
      end 
      if input:match("^[#!/][Uu]nlock hashtag$") and is_sudo(msg) then
       if not redis:get('lhashtag:'..chat_id) then
        tdcli.sendMessage(chat_id, msg.id_, 1, '<b>Error!</b>\n<i>>HashTag Posting Is Already Allowed Here.</i>', 1, 'html')
       else
         redis:del('lhashtag:'..chat_id)
        tdcli.sendMessage(chat_id, msg.id_, 1, '<b>Done!</b>\n<i>>Now HashTag Posting Is Allowed Here.</i>', 1, 'html')
      end
      end
      if redis:get('lhashtag:'..chat_id) and input:match("#") then
        tdcli.deleteMessages(chat_id, {[0] = msg.id_})
      end

	if input:match("^[#!/][Ll]ock cmd$") and is_sudo(msg) then
       if redis:get('lcmd:'..chat_id) then
        tdcli.sendMessage(chat_id, msg.id_, 1, '<b>Error!</b>\n<i>>Cmd Posting Is Already Not Allowed Here.</i>', 1, 'html')
       else 
        redis:set('lcmd:'..chat_id, true)
        tdcli.sendMessage(chat_id, msg.id_, 1, '<b>Done!</b>\n<i>>Now Cmd Posting Is Not Allowed Here.</i>', 1, 'html')
      end
      end 
      if input:match("^[#!/][Uu]nlock cmd$") and is_sudo(msg) then
       if not redis:get('lcmd:'..chat_id) then
        tdcli.sendMessage(chat_id, msg.id_, 1, '<b>Error!</b>\n<i>>Cmd Posting Is Already Allowed Here.</i>', 1, 'html')
       else
         redis:del('lcmd:'..chat_id)
        tdcli.sendMessage(chat_id, msg.id_, 1, '<b>Done!</b>\n<i>>Cmd Link Posting Is Allowed Here.</i>', 1, 'html')
      end
      end
      if redis:get('lcmd:'..chat_id) and input:match("[#/!]") then
        tdcli.deleteMessages(chat_id, {[0] = msg.id_})
      end
			
      if input:match("^[#!/][Ll]ock webpage$") and is_sudo(msg) then
       if redis:get('lwebpage:'..chat_id) then
        tdcli.sendMessage(chat_id, msg.id_, 1, '<b>Error!</b>\n<i>>WebPage Posting Is Already Not Allowed Here.</i>', 1, 'html')
       else 
        redis:set('lwebpage:'..chat_id, true)
        tdcli.sendMessage(chat_id, msg.id_, 1, '<b>Done!</b>\n<i>>Now WebPage Posting Is Not Allowed Here.</i>', 1, 'html')
      end
      end 
      if input:match("^[#!/][Uu]nlock webpage$") and is_sudo(msg) then
       if not redis:get('lwebpage:'..chat_id) then
        tdcli.sendMessage(chat_id, msg.id_, 1, '<b>Error!</b>\n<i>>WebPage Posting Is Already Allowed Here.</i>', 1, 'html')
       else
         redis:del('lwebpage:'..chat_id)
        tdcli.sendMessage(chat_id, msg.id_, 1, '<b>Done!</b>\n<i>>Now WebPage Posting Is Allowed Here.</i>', 1, 'html')
      end
      end
      --if redis:get('lwebpage:'..chat_id) and input:match("^[Hh][Tt][Tt][Pp][Ss]://$") or input:match("^[Hh][Tt][Tt][Pp]://$") or input:match("^[Ww][Ww][Ww].$") or input:match("^.com$") or input:match("^.ir$") or input:match("^.org$") or input:match("^.net$") or input:match("^.info$") then
        --tdcli.deleteMessages(chat_id, {[0] = msg.id_})
      --end
			
	if input:match("^[#!/][Ll]ock english$") and is_sudo(msg) then
       if redis:get('lenglish:'..chat_id) then
        tdcli.sendMessage(chat_id, msg.id_, 1, '<b>Error!</b>\n<i>>English Posting Is Already Not Allowed Here.</i>', 1, 'html')
       else 
        redis:set('lenglish:'..chat_id, true)
        tdcli.sendMessage(chat_id, msg.id_, 1, '<b>Done!</b>\n<i>>Now English Posting Is Not Allowed Here.</i>', 1, 'html')
      end
      end 
      if input:match("^[#!/][Uu]nlock english$") and is_sudo(msg) then
       if not redis:get('lenglish:'..chat_id) then
        tdcli.sendMessage(chat_id, msg.id_, 1, '<b>Error!</b>\n<i>>English Posting Is Already Allowed Here.</i>', 1, 'html')
       else
         redis:del('lenglish:'..chat_id)
        tdcli.sendMessage(chat_id, msg.id_, 1, '<b>Done!</b>\n<i>>Now English Posting Is Allowed Here.</i>', 1, 'html')
      end
      end
      if redis:get('lenglish:'..chat_id) and input:match("[Aa]") or input:match("[Bb]") or input:match("[Cc]") or input:match("[Dd]") or input:match("[Ee]") or input:match("[Ff]") or input:match("[Gg]") or input:match("[Hh]") or input:match("[Hh]") or input:match("[Ii]") or input:match("[Jj]") or input:match("[Kk]") or input:match("[Ll]") or input:match("[Mm]") or input:match("[Nn]") or input:match("[Oo]") or input:match("[Pp]") or input:match("[Qq]") or input:match("[Rr]") or input:match("[Ss]") or input:match("[Tt]") or input:match("[Uu]") or input:match("[Vv]") or input:match("[Ww]") or input:match("[Xx]") or input:match("[Yy]") or input:match("[Zz]") and not is_sudo(msg) then
        tdcli.deleteMessages(chat_id, {[0] = msg.id_})
      end		
			
      if input:match("^[#!/][Mm]ute all$") and is_sudo(msg) then
       if redis:get('mall:'..chat_id) then
        tdcli.sendMessage(chat_id, msg.id_, 1, '<b>Error!</b>\n<i>>Mute All Is Already Enabled.</i>', 1, 'html')
       else 
        redis:set('mall:'..chat_id, true)
        tdcli.sendMessage(chat_id, msg.id_, 1, '<b>Done!</b\n<i>>Mute All Has Been Enabled.</i>', 1, 'html')
      end
      end
      if input:match("^[#!/][Uu]nmute all$") and is_sudo(msg) then
       if not redis:get('mall:'..chat_id) then
        tdcli.sendMessage(chat_id, msg.id_, 1, '<b>Error!</b>\n<i>>Mute All Is Already Disable.</i>', 1, 'html')
       else 
         redis:del('mall:'..chat_id)
        tdcli.sendMessage(chat_id, msg.id_, 1, '<b>Done!</b>\n<i>>Mute All Has Been Disabled.</i>', 1, 'html')
      end
      end
         local links = 'llink:'..chat_id
	 if redis:get(links) then
	  Links = "Lock"
	  else 
	  Links = "Unlock"
	 end
			
	local lfwd = 'lfwd:'..chat_id
	 if redis:get(lfwd) then
	  lfwd = "Lock"
	  else 
	  lfwd = "Unlock"
	 end
			
	local ltag = 'ltag:'..chat_id
	 if redis:get(ltag) then
	  ltag = "Lock"
	  else 
	  ltag = "Unlock"
	 end
			
	local lhashtag = 'lhashtag:'..chat_id
	 if redis:get(lhashtag) then
	  lhashtag = "Lock"
	  else 
	  lhashtag = "Unlock"
	 end

	local lcmd = 'lcmd:'..chat_id
	 if redis:get(lcmd) then
	  lcmd = "Lock"
	  else 
	  lcmd = "Unlock"
	 end
			
	local lwebpage = 'lwebpage:'..chat_id
	 if redis:get(lwebpage) then
	  lwebpage = "Lock"
	  else 
	  lwebpage = "Unlock"
	 end
			
	local lenglish = 'lenglish:'..chat_id
	 if redis:get(lenglish) then
	  lenglish = "Lock"
	  else 
	  lenglish = "Unlock"
	 end			
         
         local all = 'mall:'..chat_id
	 if redis:get(all) then
	  All = "Lock"
	  else 
	  All = "Unlock"
	 end
      if input:match("^[#!/][Ss]ettings$") and is_sudo(msg) then
        tdcli.sendMessage(chat_id, msg.id_, 1, '<b>Settings:</b>\n\n<b>Fwd:</b> <code>'..lfwd..'</code>\n<b>Link:</b> <code>'..Links..'</code>\n<b>Tag{@}:</b> <code>'..ltag..'</code>\n<b>HashTag{#}:</b> <code>'..lhashtag..'</code>\n<b>Cmd:</b> <code>'..lcmd..'</code>\n<b>WebPage:</b> <code>'..lwebpage..'</code>\n<b>English:</b> <code>'..lenglish..'</code>\n➖➖➖➖➖➖➖\n<b>Mutes List:</b>\n\n<b>Mute All:</b> <code>'..All..'</code>\n➖➖➖➖➖➖➖\n<b>Group Language:</b> <i>EN</i>', 1, 'html')
      end
      if input:match("^[#!/][Ff]wd$") then
        tdcli.forwardMessages(chat_id, chat_id,{[0] = reply_id}, 0)
      end

      if input:match("^[#!/][Uu]sername") and is_sudo(msg) then
        tdcli.changeUsername(string.sub(input, 11))
         tdcli.sendMessage(chat_id, msg.id_, 1,'<b>Username Changed To </b>@'..string.sub(input, 11), 1, 'html')
      end

      if input:match("^[#!/][Ee]cho") then
        tdcli.sendMessage(chat_id, msg.id_, 1, string.sub(input, 7), 1, 'html')
      end

      if input:match("^[#!/][Ss]etname") then
        tdcli.changeChatTitle(chat_id, string.sub(input, 10), 1)
         tdcli.sendMessage(chat_id, msg.id_, 1,'<b>SuperGroup Name Changed To </b><code>'..string.sub(input, 10)..'</code>', 1, 'html')
      end
      if input:match("^[#!/][Ee]dit") then
        tdcli.editMessageText(chat_id, reply_id, nil, string.sub(input, 7), 'html')
      end

      if input:match("^[#!/][Cc]hangename") and is_sudo(msg) then
        tdcli.changeName(string.sub(input, 13), nil, 1)
         tdcli.sendMessage(chat_id, msg.id_, 1,'<b>Bot Name Changed To </b><code>'..string.sub(input, 13)..'</code>', 1, 'html')
      end

      if input:match("^[#!/][Ii]nvite") and is_sudo(msg) then
        tdcli.addChatMember(chat_id, string.sub(input, 9), 20)
      end
      if input:match("^[#!/][Cc]reatesuper") and is_sudo(msg) then
        tdcli.createNewChannelChat(string.sub(input, 14), 1, 'My Supergroup, my rules')
         tdcli.sendMessage(chat_id, msg.id_, 1,'<b>SuperGroup </b>'..string.sub(input, 14)..' <b>Created</b>', 1, 'html')
      end

      if input:match("^[#!/]view") then
        tdcli.viewMessages(chat_id, {[0] = msg.id_})
        tdcli.sendMessage(chat_id, msg.id_, 1,'<b>Messages Viewed</b>', 1, 'html')
      end
    end

   if redis:get('mall:'..chat_id) and msg then
     tdcli.deleteMessages(chat_id, {[0] = msg.id_})
   end

  elseif (data.ID == "UpdateOption" and data.name_ == "my_id") then
    
    tdcli_function ({
      ID="GetChats",
      offset_order_="9223372036854775807",
      offset_chat_id_=0,
      limit_=20
    }, dl_cb, nil)
  end
end
