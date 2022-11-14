with picks as (

select pa.MATCH_ID
	 , pa.PICK_ORDER
	 , pa.TYPE
	 , pa.AUTHOR
	 , pa.MAP
	 , m.MAX_GAMES
	 , m.DATE_UNIX
	 , case when pa.PICK_ORDER <= 2 and pa.TYPE = 'removed' then 1 else 0 end first_ban
	 , case when m.MAX_GAMES = 3 and pa.PICK_ORDER <= 4 and pa.TYPE = 'picked' then 1 else 0 end first_pick
	 , case when pa.map = 'Mirage' and pa.TYPE = 'picked' then 1 else 0 end pick_mirage
	 , sum(case when am.MAP_NAME = 'Ancient' then 1 else 0 end) ancient
	 , sum(case when am.MAP_NAME = 'Vertigo' then 1 else 0 end) vertigo
	 , sum(case when am.MAP_NAME = 'Nuke' then 1 else 0 end) nuke
	 , sum(case when am.MAP_NAME = 'Mirage' then 1 else 0 end) mirage
	 , sum(case when am.MAP_NAME = 'Inferno' then 1 else 0 end) inferno
	 , sum(case when am.MAP_NAME = 'Overpass' then 1 else 0 end) overpass
	 , sum(case when am.MAP_NAME = 'Dust2' then 1 else 0 end) dust2
from PICK_ACTION pa
left join AVAILABLE_MAP am on pa.MATCH_ID = am.MATCH_ID and pa.PICK_ORDER = am.PICK_ORDER
left join MATCH m on m.id = pa.MATCH_ID
group by pa.MATCH_ID, pa.PICK_ORDER, pa.TYPE, pa.AUTHOR, pa.MAP, m.MAX_GAMES, m.DATE_UNIX
)


SELECT p.MATCH_ID
	 , p.PICK_ORDER
	 , p.TYPE
	 , p.AUTHOR
	 , p.MAP
	 , p.MAX_GAMES
	 , p.DATE_UNIX


	 , 100*sum(case when p2.map = 'Mirage' and p2.type = 'picked' THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.mirage = 1 and p2.type = 'picked' THEN 1.0 ELSE 0 END), 0) pick_rate_mirage
	 , 100*sum(case when p2.map = 'Ancient' and p2.type = 'picked' THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.ancient = 1 and p2.type = 'picked' THEN 1.0 ELSE 0 END), 0) pick_rate_ancient
	 , 100*sum(case when p2.map = 'Vertigo' and p2.type = 'picked' THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.vertigo = 1 and p2.type = 'picked' THEN 1.0 ELSE 0 END), 0) pick_rate_vertigo
	 , 100*sum(case when p2.map = 'Nuke' and p2.type = 'picked' THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.nuke = 1 and p2.type = 'picked' THEN 1.0 ELSE 0 END), 0) pick_mirage_rate_nuke
	 , 100*sum(case when p2.map = 'Inferno' and p2.type = 'picked' THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.inferno = 1 and p2.type = 'picked' THEN 1.0 ELSE 0 END), 0) pick_rate_inferno
	 , 100*sum(case when p2.map = 'Overpass' and p2.type = 'picked' THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.overpass = 1 and p2.type = 'picked' THEN 1.0 ELSE 0 END), 0) pick_rate_overpass
	 , 100*sum(case when p2.map = 'Dust2' and p2.type = 'picked' THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.dust2 = 1 and p2.type = 'picked' THEN 1.0 ELSE 0 END), 0) pick_rate_dust2
	 , sum(case when p2.type = 'picked' then 1 else 0 end) picks


	 , 100*sum(case when p2.map = 'Mirage' and p2.first_pick = 1 THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.mirage = 1 and p2.first_pick = 1 THEN 1.0 ELSE 0 END), 0) first_pick_rate_mirage
	 , 100*sum(case when p2.map = 'Ancient' and p2.first_pick = 1 THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.ancient = 1 and p2.first_pick = 1 THEN 1.0 ELSE 0 END), 0) first_pick_rate_ancient
	 , 100*sum(case when p2.map = 'Vertigo' and p2.first_pick = 1 THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.vertigo = 1 and p2.first_pick = 1 THEN 1.0 ELSE 0 END), 0) first_pick_rate_vertigo
	 , 100*sum(case when p2.map = 'Nuke' and p2.first_pick = 1 THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.nuke = 1 and p2.first_pick = 1 THEN 1.0 ELSE 0 END), 0) first_pick_mirage_rate_nuke
	 , 100*sum(case when p2.map = 'Inferno' and p2.first_pick = 1 THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.inferno = 1 and p2.first_pick = 1 THEN 1.0 ELSE 0 END), 0) first_pick_rate_inferno
	 , 100*sum(case when p2.map = 'Overpass' and p2.first_pick = 1 THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.overpass = 1 and p2.first_pick = 1 THEN 1.0 ELSE 0 END), 0) first_pick_rate_overpass
	 , 100*sum(case when p2.map = 'Dust2' and p2.first_pick = 1 THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.dust2 = 1 and p2.first_pick = 1 THEN 1.0 ELSE 0 END), 0) first_pick_rate_dust2
	 , sum(p2.first_pick) first_picks

	 , 100*sum(case when p2.map = 'Mirage' and p2.type = 'removed' THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.mirage = 1 and p2.type = 'removed' THEN 1.0 ELSE 0 END), 0) ban_rate_mirage
	 , 100*sum(case when p2.map = 'Ancient' and p2.type = 'removed' THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.ancient = 1 and p2.type = 'removed' THEN 1.0 ELSE 0 END), 0) ban_rate_ancient
	 , 100*sum(case when p2.map = 'Vertigo' and p2.type = 'removed' THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.vertigo = 1 and p2.type = 'removed' THEN 1.0 ELSE 0 END), 0) ban_rate_vertigo
	 , 100*sum(case when p2.map = 'Nuke' and p2.type = 'removed' THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.nuke = 1 and p2.type = 'removed' THEN 1.0 ELSE 0 END), 0) ban_mirage_rate_nuke
	 , 100*sum(case when p2.map = 'Inferno' and p2.type = 'removed' THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.inferno = 1 and p2.type = 'removed' THEN 1.0 ELSE 0 END), 0) ban_rate_inferno
	 , 100*sum(case when p2.map = 'Overpass' and p2.type = 'removed' THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.overpass = 1 and p2.type = 'removed' THEN 1.0 ELSE 0 END), 0) ban_rate_overpass
	 , 100*sum(case when p2.map = 'Dust2' and p2.type = 'removed' THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.dust2 = 1 and p2.type = 'removed' THEN 1.0 ELSE 0 END), 0) ban_rate_dust2
	 , sum(case when p2.type = 'removed' then 1 else 0 end) bans

	 , 100*sum(case when p2.map = 'Mirage' and p2.first_ban = 1 THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.mirage = 1 and p2.first_ban = 1 THEN 1.0 ELSE 0 END), 0) first_ban_rate_mirage
	 , 100*sum(case when p2.map = 'Ancient' and p2.first_ban = 1 THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.ancient = 1 and p2.first_ban = 1 THEN 1.0 ELSE 0 END), 0) first_ban_rate_ancient
	 , 100*sum(case when p2.map = 'Vertigo' and p2.first_ban = 1 THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.vertigo = 1 and p2.first_ban = 1 THEN 1.0 ELSE 0 END), 0) first_ban_rate_vertigo
	 , 100*sum(case when p2.map = 'Nuke' and p2.first_ban = 1 THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.nuke = 1 and p2.first_ban = 1 THEN 1.0 ELSE 0 END), 0) first_ban_mirage_rate_nuke
	 , 100*sum(case when p2.map = 'Inferno' and p2.first_ban = 1 THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.inferno = 1 and p2.first_ban = 1 THEN 1.0 ELSE 0 END), 0) first_ban_rate_inferno
	 , 100*sum(case when p2.map = 'Overpass' and p2.first_ban = 1 THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.overpass = 1 and p2.first_ban = 1 THEN 1.0 ELSE 0 END), 0) first_ban_rate_overpass
	 , 100*sum(case when p2.map = 'Dust2' and p2.first_ban = 1 THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.dust2 = 1 and p2.first_ban = 1 THEN 1.0 ELSE 0 END), 0) first_ban_rate_dust2 
	 , sum(p2.first_pick) first_bans
from picks p
left join picks p2 on p.author = p2.author and p2.DATE_UNIX < p.DATE_UNIX and p2.date_unix >= p.DATE_UNIX - 2548000000 and p.MATCH_ID <> p2.MATCH_ID
where p.first_pick = 1

group by p.MATCH_ID
	 , p.PICK_ORDER
	 , p.TYPE
	 , p.AUTHOR
	 , p.MAP
	 , p.MAX_GAMES
	 , p.DATE_UNIX 