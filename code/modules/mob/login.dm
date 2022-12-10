//handles setting lastKnownIP and computer_id for use by the ban systems as well as checking for multikeying
/mob/proc/update_Login_details()
	//Multikey checks and logging
	lastKnownIP	= client.address
	computer_id	= client.computer_id
	log_access_in(client)
	create_attack_log("<font color='red'>Logged in at [atom_loc_line(get_turf(src))]</font>")
	create_log(MISC_LOG, "Logged in")
	if(GLOB.configuration.logging.access_logging && !(client.computer_id in GLOB.configuration.admin.common_cid_map))
		for(var/mob/M in GLOB.player_list)
			if(M == src)
				continue
			if(M.key && (M.key != key))
				var/matches
				if(M.lastKnownIP == client.address)
					matches += "IP ([client.address])"
				if(M.computer_id == client.computer_id)
					if(matches)
						matches += " and "
					matches += "ID ([client.computer_id])"
					if(!GLOB.configuration.general.disable_cid_warning_popup)
						spawn()
							alert("You have logged in already with another key this round, please log out of this one NOW or risk being banned!")
				if(matches)
					if(M.client)
						message_admins("<font color='red'><B>Notice: </B><font color='#EB4E00'><A href='?src=[usr.UID()];priv_msg=[src.client.ckey]'>[key_name_admin(src)]</A> has the same [matches] as <A href='?src=[usr.UID()];priv_msg=[M.client.ckey]'>[key_name_admin(M)]</A>.</font>", 1)
						log_adminwarn("Notice: [key_name(src)] has the same [matches] as [key_name(M)].")
					else
						message_admins("<font color='red'><B>Notice: </B><font color='#EB4E00'><A href='?src=[usr.UID()];priv_msg=[src.client.ckey]'>[key_name_admin(src)]</A> has the same [matches] as [key_name_admin(M)] (no longer logged in). </font>", 1)
						log_adminwarn("Notice: [key_name(src)] has the same [matches] as [key_name(M)] (no longer logged in).")

/mob/Login()
	GLOB.player_list |= src
	last_known_ckey = ckey
	update_Login_details()
	world.update_status()

	client.images = null				//remove the images such as AIs being unable to see runes
	client.screen = list()				//remove hud items just in case
	if(client.click_intercept)
		client.click_intercept.quit() // Let's not keep any old click_intercepts

	if(!hud_used)
		create_mob_hud()
	if(hud_used)
		hud_used.show_hud(hud_used.hud_version)

	next_move = 1
	sight |= SEE_SELF
	..()

	reset_perspective(loc)


	if(ckey in GLOB.deadmins)
		verbs += /client/proc/readmin

	//Clear ability list and update from mob.
	client.verbs -= GLOB.ability_verbs

	if(abilities)
		client.verbs |= abilities

	client.update_active_keybindings()

	//HUD updates (antag hud, etc)
	//readd this mob's HUDs (antag, med, etc)
	reload_huds()

	add_click_catcher()

	if(viewing_alternate_appearances && viewing_alternate_appearances.len)
		for(var/datum/alternate_appearance/AA in viewing_alternate_appearances)
			AA.display_to(list(src))

	update_client_colour(0)

	if(GLOB.admin_datums[ckey])
		var/datum/admins/temp_admin = GLOB.admin_datums[ckey]
		if(temp_admin.rights & R_BAN)
			message_admins("Admin login: [key_name_admin(src)]")
			var/list/admincounter = staff_countup(R_BAN)
			if(admincounter[1] == 1) // One active admin
				SSdiscord.send2discord_simple(DISCORD_WEBHOOK_ADMIN, "First admin [key_name(src)] logged in - 1 active admins, [admincounter[2]] non-admin staff, [admincounter[3]] inactive staff.")

		else if(temp_admin.rights & R_MENTOR)
			var/list/mentorcounter = staff_countup(R_MENTOR)
			if(mentorcounter[1] == 1) // One active mentor
				SSdiscord.send2discord_simple(DISCORD_WEBHOOK_MENTOR, "First mentor [key_name(src)] logged in - 1 active mentors, [mentorcounter[2]] non-mentor staff, [mentorcounter[3]] inactive mentors.")

	update_morgue()
