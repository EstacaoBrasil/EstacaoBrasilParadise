/mob/Logout()
	SStgui.on_logout(src) // Cleanup any TGUIs the user has open
	unset_machine()
	GLOB.player_list -= src
	log_access_out(src)
	create_attack_log("<font color='red'>Logged out at [atom_loc_line(get_turf(src))]</font>")
	create_log(MISC_LOG, "Logged out")

	..()
	update_morgue()
	return 1
