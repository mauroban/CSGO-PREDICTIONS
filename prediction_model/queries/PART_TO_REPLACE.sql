picks_team as (

SELECT p.MATCH_ID
	 , p.PICK_ORDER
	 , p.TYPE
	 , p.AUTHOR
	 , p.MAP
	 , p.MAX_GAMES
	 , p.DATE_UNIX
	 , p.first_pick
	 , p.opponent


	 , sum(case when p2.map = 'Mirage' and p2.type = 'picked' THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.mirage = 1 and p2.type = 'picked' THEN 1.0 ELSE 0 END), 0) pick_rate_mirage
	 , sum(case when p2.map = 'Ancient' and p2.type = 'picked' THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.ancient = 1 and p2.type = 'picked' THEN 1.0 ELSE 0 END), 0) pick_rate_ancient
	 , sum(case when p2.map = 'Vertigo' and p2.type = 'picked' THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.vertigo = 1 and p2.type = 'picked' THEN 1.0 ELSE 0 END), 0) pick_rate_vertigo
	 , sum(case when p2.map = 'Nuke' and p2.type = 'picked' THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.nuke = 1 and p2.type = 'picked' THEN 1.0 ELSE 0 END), 0) pick_rate_nuke
	 , sum(case when p2.map = 'Inferno' and p2.type = 'picked' THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.inferno = 1 and p2.type = 'picked' THEN 1.0 ELSE 0 END), 0) pick_rate_inferno
	 , sum(case when p2.map = 'Overpass' and p2.type = 'picked' THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.overpass = 1 and p2.type = 'picked' THEN 1.0 ELSE 0 END), 0) pick_rate_overpass
	 , sum(case when p2.map = 'Dust2' and p2.type = 'picked' THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.dust2 = 1 and p2.type = 'picked' THEN 1.0 ELSE 0 END), 0) pick_rate_dust2
	 , sum(case when p2.type = 'picked' then 1 else 0 end) picks


	 , sum(case when p2.map = 'Mirage' and p2.first_pick = 1 THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.mirage = 1 and p2.first_pick = 1 THEN 1.0 ELSE 0 END), 0) first_pick_rate_mirage
	 , sum(case when p2.map = 'Ancient' and p2.first_pick = 1 THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.ancient = 1 and p2.first_pick = 1 THEN 1.0 ELSE 0 END), 0) first_pick_rate_ancient
	 , sum(case when p2.map = 'Vertigo' and p2.first_pick = 1 THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.vertigo = 1 and p2.first_pick = 1 THEN 1.0 ELSE 0 END), 0) first_pick_rate_vertigo
	 , sum(case when p2.map = 'Nuke' and p2.first_pick = 1 THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.nuke = 1 and p2.first_pick = 1 THEN 1.0 ELSE 0 END), 0) first_pick_rate_nuke
	 , sum(case when p2.map = 'Inferno' and p2.first_pick = 1 THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.inferno = 1 and p2.first_pick = 1 THEN 1.0 ELSE 0 END), 0) first_pick_rate_inferno
	 , sum(case when p2.map = 'Overpass' and p2.first_pick = 1 THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.overpass = 1 and p2.first_pick = 1 THEN 1.0 ELSE 0 END), 0) first_pick_rate_overpass
	 , sum(case when p2.map = 'Dust2' and p2.first_pick = 1 THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.dust2 = 1 and p2.first_pick = 1 THEN 1.0 ELSE 0 END), 0) first_pick_rate_dust2
	 , sum(p2.first_pick) first_picks

	 , sum(case when p2.map = 'Mirage' and p2.type = 'removed' THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.mirage = 1 and p2.type = 'removed' THEN 1.0 ELSE 0 END), 0) ban_rate_mirage
	 , sum(case when p2.map = 'Ancient' and p2.type = 'removed' THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.ancient = 1 and p2.type = 'removed' THEN 1.0 ELSE 0 END), 0) ban_rate_ancient
	 , sum(case when p2.map = 'Vertigo' and p2.type = 'removed' THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.vertigo = 1 and p2.type = 'removed' THEN 1.0 ELSE 0 END), 0) ban_rate_vertigo
	 , sum(case when p2.map = 'Nuke' and p2.type = 'removed' THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.nuke = 1 and p2.type = 'removed' THEN 1.0 ELSE 0 END), 0) ban_rate_nuke
	 , sum(case when p2.map = 'Inferno' and p2.type = 'removed' THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.inferno = 1 and p2.type = 'removed' THEN 1.0 ELSE 0 END), 0) ban_rate_inferno
	 , sum(case when p2.map = 'Overpass' and p2.type = 'removed' THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.overpass = 1 and p2.type = 'removed' THEN 1.0 ELSE 0 END), 0) ban_rate_overpass
	 , sum(case when p2.map = 'Dust2' and p2.type = 'removed' THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.dust2 = 1 and p2.type = 'removed' THEN 1.0 ELSE 0 END), 0) ban_rate_dust2
	 , sum(case when p2.type = 'removed' then 1 else 0 end) bans

	 , sum(case when p2.map = 'Mirage' and p2.first_ban = 1 THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.mirage = 1 and p2.first_ban = 1 THEN 1.0 ELSE 0 END), 0) first_ban_rate_mirage
	 , sum(case when p2.map = 'Ancient' and p2.first_ban = 1 THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.ancient = 1 and p2.first_ban = 1 THEN 1.0 ELSE 0 END), 0) first_ban_rate_ancient
	 , sum(case when p2.map = 'Vertigo' and p2.first_ban = 1 THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.vertigo = 1 and p2.first_ban = 1 THEN 1.0 ELSE 0 END), 0) first_ban_rate_vertigo
	 , sum(case when p2.map = 'Nuke' and p2.first_ban = 1 THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.nuke = 1 and p2.first_ban = 1 THEN 1.0 ELSE 0 END), 0) first_ban_rate_nuke
	 , sum(case when p2.map = 'Inferno' and p2.first_ban = 1 THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.inferno = 1 and p2.first_ban = 1 THEN 1.0 ELSE 0 END), 0) first_ban_rate_inferno
	 , sum(case when p2.map = 'Overpass' and p2.first_ban = 1 THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.overpass = 1 and p2.first_ban = 1 THEN 1.0 ELSE 0 END), 0) first_ban_rate_overpass
	 , sum(case when p2.map = 'Dust2' and p2.first_ban = 1 THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.dust2 = 1 and p2.first_ban = 1 THEN 1.0 ELSE 0 END), 0) first_ban_rate_dust2 
	 , sum(p2.first_pick) first_bans

	 , count(1) jogos
from picks p
left join picks p2 on p.author = p2.author and p2.DATE_UNIX < p.DATE_UNIX and p2.date_unix >= p.DATE_UNIX - 2548000000 and p.MATCH_ID <> p2.MATCH_ID
where p.type = 'picked'

group by p.MATCH_ID
	 , p.PICK_ORDER
	 , p.TYPE
	 , p.AUTHOR
	 , p.MAP
	 , p.MAX_GAMES
	 , p.DATE_UNIX
	 , p.first_pick
	 , p.opponent
)