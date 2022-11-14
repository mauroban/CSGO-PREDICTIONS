with games as (

select
	   g.MATCH_ID
	 , g.GAME_NUM
	 , m.DATE_UNIX
	 , g.MAP_NAME
	 , tg1."NAME" as TEAM_NAME
	 , case when g.TEAM1 = tg1."NAME" then g.TEAM2 else g.TEAM1 end as OPPONENT
	 , case when g.WINNER = tg1."NAME" then 1 else 0 end win
	 , tg1.SCORE
	 , tg1.SCORE_CT
	 , tg1.SCORE_T
	 , CASE WHEN tg1."RANK" IS NULL THEN 350 ELSE tg1."RANK" END "RANK"
	 , tg2.SCORE SCORE_OPPONENT
	 , tg2.SCORE_CT SCORE_CT_OPPONENT
	 , tg2.SCORE_T SCORE_T_OPPONENT
	 , CASE WHEN tg2."RANK" IS NULL THEN 350 ELSE tg2."RANK" END RANK_OPPONENT

	 , tg1.score + tg2.score as rounds_played
	 , tg1.score_ct + tg2.score_t as rounds_played_ct
	 , tg1.score_t + tg2.score_ct as rounds_played_t

from game g
left join TEAM_GAME tg1 on g.MATCH_ID = tg1.MATCH_ID and g.GAME_NUM = tg1.GAME_NUM and g.TEAM1 = tg1."NAME"
left join TEAM_GAME tg2 on g.MATCH_ID = tg2.MATCH_ID and g.GAME_NUM = tg2.GAME_NUM and g.TEAM2 = tg2."NAME"
left join MATCH m on g.MATCH_ID = m.ID
),

picks as (

select pa.MATCH_ID
	 , pa.PICK_ORDER
	 , pa.TYPE
	 , pa.AUTHOR
	 , pa.MAP
	 , case when team1 = pa.author then team2 else team1 end as opponent
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
group by pa.MATCH_ID, pa.PICK_ORDER, pa.TYPE, pa.AUTHOR, pa.MAP, m.MAX_GAMES, m.DATE_UNIX, m.team1, m.TEAM2
),

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
),

full_picks as (

SELECT p.MATCH_ID
	 , p.PICK_ORDER
	 , p.TYPE
	 , p.AUTHOR
	 , p.MAP
	 , p.MAX_GAMES
	 , p.DATE_UNIX
	 , p.first_pick
	 , p.opponent
	 , p.jogos

	 , p.pick_rate_mirage
	 , p.pick_rate_ancient
	 , p.pick_rate_vertigo
	 , p.pick_rate_nuke
	 , p.pick_rate_inferno
	 , p.pick_rate_overpass
	 , p.pick_rate_dust2

	 , p.ban_rate_mirage
	 , p.ban_rate_ancient
	 , p.ban_rate_vertigo
	 , p.ban_rate_nuke
	 , p.ban_rate_inferno
	 , p.ban_rate_overpass
	 , p.ban_rate_dust2

	 , p.first_pick_rate_mirage
	 , p.first_pick_rate_ancient
	 , p.first_pick_rate_vertigo
	 , p.first_pick_rate_nuke
	 , p.first_pick_rate_inferno
	 , p.first_pick_rate_overpass
	 , p.first_pick_rate_dust2

	 , p.first_ban_rate_mirage
	 , p.first_ban_rate_ancient
	 , p.first_ban_rate_vertigo
	 , p.first_ban_rate_nuke
	 , p.first_ban_rate_inferno
	 , p.first_ban_rate_overpass
	 , p.first_ban_rate_dust2


	 , sum(case when p2.map = 'Mirage' and p2.type = 'picked' THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.mirage = 1 and p2.type = 'picked' THEN 1.0 ELSE 0 END), 0) pick_rate_mirage_opponent
	 , sum(case when p2.map = 'Ancient' and p2.type = 'picked' THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.ancient = 1 and p2.type = 'picked' THEN 1.0 ELSE 0 END), 0) pick_rate_ancient_opponent
	 , sum(case when p2.map = 'Vertigo' and p2.type = 'picked' THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.vertigo = 1 and p2.type = 'picked' THEN 1.0 ELSE 0 END), 0) pick_rate_vertigo_opponent
	 , sum(case when p2.map = 'Nuke' and p2.type = 'picked' THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.nuke = 1 and p2.type = 'picked' THEN 1.0 ELSE 0 END), 0) pick_rate_nuke_opponent
	 , sum(case when p2.map = 'Inferno' and p2.type = 'picked' THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.inferno = 1 and p2.type = 'picked' THEN 1.0 ELSE 0 END), 0) pick_rate_inferno_opponent
	 , sum(case when p2.map = 'Overpass' and p2.type = 'picked' THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.overpass = 1 and p2.type = 'picked' THEN 1.0 ELSE 0 END), 0) pick_rate_overpass_opponent
	 , sum(case when p2.map = 'Dust2' and p2.type = 'picked' THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.dust2 = 1 and p2.type = 'picked' THEN 1.0 ELSE 0 END), 0) pick_rate_dust2_opponent
	 , sum(case when p2.type = 'picked' then 1 else 0 end) picks_opponent


	 , sum(case when p2.map = 'Mirage' and p2.first_pick = 1 THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.mirage = 1 and p2.first_pick = 1 THEN 1.0 ELSE 0 END), 0) first_pick_rate_mirage_opponent
	 , sum(case when p2.map = 'Ancient' and p2.first_pick = 1 THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.ancient = 1 and p2.first_pick = 1 THEN 1.0 ELSE 0 END), 0) first_pick_rate_ancient_opponent
	 , sum(case when p2.map = 'Vertigo' and p2.first_pick = 1 THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.vertigo = 1 and p2.first_pick = 1 THEN 1.0 ELSE 0 END), 0) first_pick_rate_vertigo_opponent
	 , sum(case when p2.map = 'Nuke' and p2.first_pick = 1 THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.nuke = 1 and p2.first_pick = 1 THEN 1.0 ELSE 0 END), 0) first_pick_rate_nuke_opponent
	 , sum(case when p2.map = 'Inferno' and p2.first_pick = 1 THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.inferno = 1 and p2.first_pick = 1 THEN 1.0 ELSE 0 END), 0) first_pick_rate_inferno_opponent
	 , sum(case when p2.map = 'Overpass' and p2.first_pick = 1 THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.overpass = 1 and p2.first_pick = 1 THEN 1.0 ELSE 0 END), 0) first_pick_rate_overpass_opponent
	 , sum(case when p2.map = 'Dust2' and p2.first_pick = 1 THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.dust2 = 1 and p2.first_pick = 1 THEN 1.0 ELSE 0 END), 0) first_pick_rate_dust2_opponent
	 , sum(p2.first_pick) first_picks_opponent

	 , sum(case when p2.map = 'Mirage' and p2.type = 'removed' THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.mirage = 1 and p2.type = 'removed' THEN 1.0 ELSE 0 END), 0) ban_rate_mirage_opponent
	 , sum(case when p2.map = 'Ancient' and p2.type = 'removed' THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.ancient = 1 and p2.type = 'removed' THEN 1.0 ELSE 0 END), 0) ban_rate_ancient_opponent
	 , sum(case when p2.map = 'Vertigo' and p2.type = 'removed' THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.vertigo = 1 and p2.type = 'removed' THEN 1.0 ELSE 0 END), 0) ban_rate_vertigo_opponent
	 , sum(case when p2.map = 'Nuke' and p2.type = 'removed' THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.nuke = 1 and p2.type = 'removed' THEN 1.0 ELSE 0 END), 0) ban_rate_nuke_opponent
	 , sum(case when p2.map = 'Inferno' and p2.type = 'removed' THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.inferno = 1 and p2.type = 'removed' THEN 1.0 ELSE 0 END), 0) ban_rate_inferno_opponent
	 , sum(case when p2.map = 'Overpass' and p2.type = 'removed' THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.overpass = 1 and p2.type = 'removed' THEN 1.0 ELSE 0 END), 0) ban_rate_overpass_opponent
	 , sum(case when p2.map = 'Dust2' and p2.type = 'removed' THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.dust2 = 1 and p2.type = 'removed' THEN 1.0 ELSE 0 END), 0) ban_rate_dust2_opponent
	 , sum(case when p2.type = 'removed' then 1 else 0 end) bans_opponent

	 , sum(case when p2.map = 'Mirage' and p2.first_ban = 1 THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.mirage = 1 and p2.first_ban = 1 THEN 1.0 ELSE 0 END), 0) first_ban_rate_mirage_opponent
	 , sum(case when p2.map = 'Ancient' and p2.first_ban = 1 THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.ancient = 1 and p2.first_ban = 1 THEN 1.0 ELSE 0 END), 0) first_ban_rate_ancient_opponent
	 , sum(case when p2.map = 'Vertigo' and p2.first_ban = 1 THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.vertigo = 1 and p2.first_ban = 1 THEN 1.0 ELSE 0 END), 0) first_ban_rate_vertigo_opponent
	 , sum(case when p2.map = 'Nuke' and p2.first_ban = 1 THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.nuke = 1 and p2.first_ban = 1 THEN 1.0 ELSE 0 END), 0) first_ban_rate_nuke_opponent
	 , sum(case when p2.map = 'Inferno' and p2.first_ban = 1 THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.inferno = 1 and p2.first_ban = 1 THEN 1.0 ELSE 0 END), 0) first_ban_rate_inferno_opponent
	 , sum(case when p2.map = 'Overpass' and p2.first_ban = 1 THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.overpass = 1 and p2.first_ban = 1 THEN 1.0 ELSE 0 END), 0) first_ban_rate_overpass_opponent
	 , sum(case when p2.map = 'Dust2' and p2.first_ban = 1 THEN 1.0 ELSE 0 END)/NULLIF(sum(case when p2.dust2 = 1 and p2.first_ban = 1 THEN 1.0 ELSE 0 END), 0) first_ban_rate_dust2_opponent
	 , sum(p2.first_pick) first_bans_opponent

	 , count(1) jogos_opponent
from picks_team p
left join picks p2 on p.opponent = p2.author and p2.DATE_UNIX < p.DATE_UNIX and p2.date_unix >= p.DATE_UNIX - 2548000000 and p.MATCH_ID <> p2.MATCH_ID
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
	 , p.jogos

	 , p.pick_rate_mirage
	 , p.pick_rate_ancient
	 , p.pick_rate_vertigo
	 , p.pick_rate_nuke
	 , p.pick_rate_inferno
	 , p.pick_rate_overpass
	 , p.pick_rate_dust2

	 , p.ban_rate_mirage
	 , p.ban_rate_ancient
	 , p.ban_rate_vertigo
	 , p.ban_rate_nuke
	 , p.ban_rate_inferno
	 , p.ban_rate_overpass
	 , p.ban_rate_dust2

	 , p.first_pick_rate_mirage
	 , p.first_pick_rate_ancient
	 , p.first_pick_rate_vertigo
	 , p.first_pick_rate_nuke
	 , p.first_pick_rate_inferno
	 , p.first_pick_rate_overpass
	 , p.first_pick_rate_dust2

	 , p.first_ban_rate_mirage
	 , p.first_ban_rate_ancient
	 , p.first_ban_rate_vertigo
	 , p.first_ban_rate_nuke
	 , p.first_ban_rate_inferno
	 , p.first_ban_rate_overpass
	 , p.first_ban_rate_dust2
),

team_win as (


select p.MATCH_ID
	 , m.HLTV_LINK
	 , p.PICK_ORDER
	 , p.TYPE
	 , p.AUTHOR
	 , p.MAP
	 , p.MAX_GAMES
	 , p.DATE_UNIX
	 , p.first_pick
	 , p.opponent
	 , p.jogos
	 , p.jogos_opponent

	 , p.pick_rate_mirage
	 , p.pick_rate_ancient
	 , p.pick_rate_vertigo
	 , p.pick_rate_nuke
	 , p.pick_rate_inferno
	 , p.pick_rate_overpass
	 , p.pick_rate_dust2

	 , p.ban_rate_mirage
	 , p.ban_rate_ancient
	 , p.ban_rate_vertigo
	 , p.ban_rate_nuke
	 , p.ban_rate_inferno
	 , p.ban_rate_overpass
	 , p.ban_rate_dust2

	 , p.first_pick_rate_mirage
	 , p.first_pick_rate_ancient
	 , p.first_pick_rate_vertigo
	 , p.first_pick_rate_nuke
	 , p.first_pick_rate_inferno
	 , p.first_pick_rate_overpass
	 , p.first_pick_rate_dust2

	 , p.first_ban_rate_mirage
	 , p.first_ban_rate_ancient
	 , p.first_ban_rate_vertigo
	 , p.first_ban_rate_nuke
	 , p.first_ban_rate_inferno
	 , p.first_ban_rate_overpass
	 , p.first_ban_rate_dust2

	 , p.pick_rate_mirage_opponent
	 , p.pick_rate_ancient_opponent
	 , p.pick_rate_vertigo_opponent
	 , p.pick_rate_nuke_opponent
	 , p.pick_rate_inferno_opponent
	 , p.pick_rate_overpass_opponent
	 , p.pick_rate_dust2_opponent

	 , p.ban_rate_mirage_opponent
	 , p.ban_rate_ancient_opponent
	 , p.ban_rate_vertigo_opponent
	 , p.ban_rate_nuke_opponent
	 , p.ban_rate_inferno_opponent
	 , p.ban_rate_overpass_opponent
	 , p.ban_rate_dust2_opponent

	 , p.first_pick_rate_mirage_opponent
	 , p.first_pick_rate_ancient_opponent
	 , p.first_pick_rate_vertigo_opponent
	 , p.first_pick_rate_nuke_opponent
	 , p.first_pick_rate_inferno_opponent
	 , p.first_pick_rate_overpass_opponent
	 , p.first_pick_rate_dust2_opponent

	 , p.first_ban_rate_mirage_opponent
	 , p.first_ban_rate_ancient_opponent
	 , p.first_ban_rate_vertigo_opponent
	 , p.first_ban_rate_nuke_opponent
	 , p.first_ban_rate_inferno_opponent
	 , p.first_ban_rate_overpass_opponent
	 , p.first_ban_rate_dust2_opponent
	 
	 , sum(1.0*win)/count(1) as win_rate
	 , sum(case when g.MAP_NAME = 'Ancient' then 1.0*win else 0 end)/SUM(NULLIF(case when g.MAP_NAME = 'Ancient' then 1 else 0 end, 0)) win_rate_ancient
	 , sum(case when g.MAP_NAME = 'Vertigo' then 1.0*win else 0 end)/SUM(NULLIF(case when g.MAP_NAME = 'Vertigo' then 1 else 0 end, 0)) win_rate_vertigo
	 , sum(case when g.MAP_NAME = 'Nuke' then 1.0*win else 0 end)/SUM(NULLIF(case when g.MAP_NAME = 'Nuke' then 1 else 0 end, 0)) win_rate_nuke
	 , sum(case when g.MAP_NAME = 'Mirage' then 1.0*win else 0 end)/SUM(NULLIF(case when g.MAP_NAME = 'Mirage' then 1 else 0 end, 0)) win_rate_mirage
	 , sum(case when g.MAP_NAME = 'Inferno' then 1.0*win else 0 end)/SUM(NULLIF(case when g.MAP_NAME = 'Inferno' then 1 else 0 end, 0)) win_rate_inferno
	 , sum(case when g.MAP_NAME = 'Overpass' then 1.0*win else 0 end)/SUM(NULLIF(case when g.MAP_NAME = 'Overpass' then 1 else 0 end, 0)) win_rate_overpass
	 , sum(case when g.MAP_NAME = 'Dust2' then 1.0*win else 0 end)/SUM(NULLIF(case when g.MAP_NAME = 'Dust2' then 1 else 0 end, 0)) win_rate_dust2

from full_picks p
left join games g on p.AUTHOR = g.TEAM_NAME and p.MATCH_ID <> g.MATCH_ID and g.DATE_UNIX < p.DATE_UNIX and g.DATE_UNIX >= p.DATE_UNIX - 2548000000
left join match m on p.MATCH_ID = m.id
group by 
	   p.MATCH_ID
	 , m.HLTV_LINK
	 , p.PICK_ORDER
	 , p.TYPE
	 , p.AUTHOR
	 , p.MAP
	 , p.MAX_GAMES
	 , p.DATE_UNIX
	 , p.first_pick
	 , p.opponent
	 , p.jogos
	 , p.jogos_opponent

	 , p.pick_rate_mirage
	 , p.pick_rate_ancient
	 , p.pick_rate_vertigo
	 , p.pick_rate_nuke
	 , p.pick_rate_inferno
	 , p.pick_rate_overpass
	 , p.pick_rate_dust2

	 , p.ban_rate_mirage
	 , p.ban_rate_ancient
	 , p.ban_rate_vertigo
	 , p.ban_rate_nuke
	 , p.ban_rate_inferno
	 , p.ban_rate_overpass
	 , p.ban_rate_dust2

	 , p.first_pick_rate_mirage
	 , p.first_pick_rate_ancient
	 , p.first_pick_rate_vertigo
	 , p.first_pick_rate_nuke
	 , p.first_pick_rate_inferno
	 , p.first_pick_rate_overpass
	 , p.first_pick_rate_dust2

	 , p.first_ban_rate_mirage
	 , p.first_ban_rate_ancient
	 , p.first_ban_rate_vertigo
	 , p.first_ban_rate_nuke
	 , p.first_ban_rate_inferno
	 , p.first_ban_rate_overpass
	 , p.first_ban_rate_dust2

	 , p.pick_rate_mirage_opponent
	 , p.pick_rate_ancient_opponent
	 , p.pick_rate_vertigo_opponent
	 , p.pick_rate_nuke_opponent
	 , p.pick_rate_inferno_opponent
	 , p.pick_rate_overpass_opponent
	 , p.pick_rate_dust2_opponent

	 , p.ban_rate_mirage_opponent
	 , p.ban_rate_ancient_opponent
	 , p.ban_rate_vertigo_opponent
	 , p.ban_rate_nuke_opponent
	 , p.ban_rate_inferno_opponent
	 , p.ban_rate_overpass_opponent
	 , p.ban_rate_dust2_opponent

	 , p.first_pick_rate_mirage_opponent
	 , p.first_pick_rate_ancient_opponent
	 , p.first_pick_rate_vertigo_opponent
	 , p.first_pick_rate_nuke_opponent
	 , p.first_pick_rate_inferno_opponent
	 , p.first_pick_rate_overpass_opponent
	 , p.first_pick_rate_dust2_opponent

	 , p.first_ban_rate_mirage_opponent
	 , p.first_ban_rate_ancient_opponent
	 , p.first_ban_rate_vertigo_opponent
	 , p.first_ban_rate_nuke_opponent
	 , p.first_ban_rate_inferno_opponent
	 , p.first_ban_rate_overpass_opponent
	 , p.first_ban_rate_dust2_opponent
)



select p.MATCH_ID
	 , p.HLTV_LINK
	 , p.PICK_ORDER
	 , p.TYPE
	 , p.AUTHOR
	 , p.MAP
	 , p.MAX_GAMES
	 , p.DATE_UNIX
	 , p.first_pick
	 , p.opponent
	 , p.jogos
	 , p.jogos_opponent

	 , p.pick_rate_mirage
	 , p.pick_rate_ancient
	 , p.pick_rate_vertigo
	 , p.pick_rate_nuke
	 , p.pick_rate_inferno
	 , p.pick_rate_overpass
	 , p.pick_rate_dust2

	 , p.ban_rate_mirage
	 , p.ban_rate_ancient
	 , p.ban_rate_vertigo
	 , p.ban_rate_nuke
	 , p.ban_rate_inferno
	 , p.ban_rate_overpass
	 , p.ban_rate_dust2

	 , p.first_pick_rate_mirage
	 , p.first_pick_rate_ancient
	 , p.first_pick_rate_vertigo
	 , p.first_pick_rate_nuke
	 , p.first_pick_rate_inferno
	 , p.first_pick_rate_overpass
	 , p.first_pick_rate_dust2

	 , p.first_ban_rate_mirage
	 , p.first_ban_rate_ancient
	 , p.first_ban_rate_vertigo
	 , p.first_ban_rate_nuke
	 , p.first_ban_rate_inferno
	 , p.first_ban_rate_overpass
	 , p.first_ban_rate_dust2

	 , p.pick_rate_mirage_opponent
	 , p.pick_rate_ancient_opponent
	 , p.pick_rate_vertigo_opponent
	 , p.pick_rate_nuke_opponent
	 , p.pick_rate_inferno_opponent
	 , p.pick_rate_overpass_opponent
	 , p.pick_rate_dust2_opponent

	 , p.ban_rate_mirage_opponent
	 , p.ban_rate_ancient_opponent
	 , p.ban_rate_vertigo_opponent
	 , p.ban_rate_nuke_opponent
	 , p.ban_rate_inferno_opponent
	 , p.ban_rate_overpass_opponent
	 , p.ban_rate_dust2_opponent

	 , p.first_pick_rate_mirage_opponent
	 , p.first_pick_rate_ancient_opponent
	 , p.first_pick_rate_vertigo_opponent
	 , p.first_pick_rate_nuke_opponent
	 , p.first_pick_rate_inferno_opponent
	 , p.first_pick_rate_overpass_opponent
	 , p.first_pick_rate_dust2_opponent

	 , p.first_ban_rate_mirage_opponent
	 , p.first_ban_rate_ancient_opponent
	 , p.first_ban_rate_vertigo_opponent
	 , p.first_ban_rate_nuke_opponent
	 , p.first_ban_rate_inferno_opponent
	 , p.first_ban_rate_overpass_opponent
	 , p.first_ban_rate_dust2_opponent

	 , case when (
	 case when p.first_ban_rate_mirage_opponent > 0 then 1 else 0 end +
	 case when  p.first_ban_rate_ancient_opponent  > 0 then 1 else 0 end +
	 case when p.first_ban_rate_vertigo_opponent  > 0 then 1 else 0 end +
	 case when  p.first_ban_rate_nuke_opponent  > 0 then 1 else 0 end +
	 case when  p.first_ban_rate_inferno_opponent  > 0 then 1 else 0 end +
	 case when  p.first_ban_rate_overpass_opponent > 0 then 1 else 0 end +
	 case when  p.first_ban_rate_dust2_opponent  > 0 then 1 else 0 end) > 2 then 1 else 0 end ban_variavel
	 
	 , win_rate
	 , win_rate_ancient
	 , win_rate_vertigo
	 , win_rate_nuke
	 , win_rate_mirage
	 , win_rate_inferno
	 , win_rate_overpass
	 , win_rate_dust2

	 , sum(1.0*win)/count(1) as win_rate_opponent
	 , sum(case when g.MAP_NAME = 'Ancient' then 1.0*win else 0 end)/SUM(NULLIF(case when g.MAP_NAME = 'Ancient' then 1 else 0 end, 0)) win_rate_ancient_opponent
	 , sum(case when g.MAP_NAME = 'Vertigo' then 1.0*win else 0 end)/SUM(NULLIF(case when g.MAP_NAME = 'Vertigo' then 1 else 0 end, 0)) win_rate_vertigo_opponent
	 , sum(case when g.MAP_NAME = 'Nuke' then 1.0*win else 0 end)/SUM(NULLIF(case when g.MAP_NAME = 'Nuke' then 1 else 0 end, 0)) win_rate_nuke_opponent
	 , sum(case when g.MAP_NAME = 'Mirage' then 1.0*win else 0 end)/SUM(NULLIF(case when g.MAP_NAME = 'Mirage' then 1 else 0 end, 0)) win_rate_mirage_opponent
	 , sum(case when g.MAP_NAME = 'Inferno' then 1.0*win else 0 end)/SUM(NULLIF(case when g.MAP_NAME = 'Inferno' then 1 else 0 end, 0)) win_rate_inferno_opponent
	 , sum(case when g.MAP_NAME = 'Overpass' then 1.0*win else 0 end)/SUM(NULLIF(case when g.MAP_NAME = 'Overpass' then 1 else 0 end, 0)) win_rate_overpass_opponent
	 , sum(case when g.MAP_NAME = 'Dust2' then 1.0*win else 0 end)/SUM(NULLIF(case when g.MAP_NAME = 'Dust2' then 1 else 0 end, 0)) win_rate_dust2_opponent

from team_win p
left join games g on p.opponent = g.TEAM_NAME and p.MATCH_ID <> g.MATCH_ID and g.DATE_UNIX < p.DATE_UNIX and g.DATE_UNIX >= p.DATE_UNIX - 2548000000
group by 
	   p.MATCH_ID
	 , p.HLTV_LINK
	 , p.PICK_ORDER
	 , p.TYPE
	 , p.AUTHOR
	 , p.MAP
	 , p.MAX_GAMES
	 , p.DATE_UNIX
	 , p.first_pick
	 , p.opponent
	 , p.jogos
	 , p.jogos_opponent

	 , p.pick_rate_mirage
	 , p.pick_rate_ancient
	 , p.pick_rate_vertigo
	 , p.pick_rate_nuke
	 , p.pick_rate_inferno
	 , p.pick_rate_overpass
	 , p.pick_rate_dust2

	 , p.ban_rate_mirage
	 , p.ban_rate_ancient
	 , p.ban_rate_vertigo
	 , p.ban_rate_nuke
	 , p.ban_rate_inferno
	 , p.ban_rate_overpass
	 , p.ban_rate_dust2

	 , p.first_pick_rate_mirage
	 , p.first_pick_rate_ancient
	 , p.first_pick_rate_vertigo
	 , p.first_pick_rate_nuke
	 , p.first_pick_rate_inferno
	 , p.first_pick_rate_overpass
	 , p.first_pick_rate_dust2

	 , p.first_ban_rate_mirage
	 , p.first_ban_rate_ancient
	 , p.first_ban_rate_vertigo
	 , p.first_ban_rate_nuke
	 , p.first_ban_rate_inferno
	 , p.first_ban_rate_overpass
	 , p.first_ban_rate_dust2

	 , p.pick_rate_mirage_opponent
	 , p.pick_rate_ancient_opponent
	 , p.pick_rate_vertigo_opponent
	 , p.pick_rate_nuke_opponent
	 , p.pick_rate_inferno_opponent
	 , p.pick_rate_overpass_opponent
	 , p.pick_rate_dust2_opponent

	 , p.ban_rate_mirage_opponent
	 , p.ban_rate_ancient_opponent
	 , p.ban_rate_vertigo_opponent
	 , p.ban_rate_nuke_opponent
	 , p.ban_rate_inferno_opponent
	 , p.ban_rate_overpass_opponent
	 , p.ban_rate_dust2_opponent

	 , p.first_pick_rate_mirage_opponent
	 , p.first_pick_rate_ancient_opponent
	 , p.first_pick_rate_vertigo_opponent
	 , p.first_pick_rate_nuke_opponent
	 , p.first_pick_rate_inferno_opponent
	 , p.first_pick_rate_overpass_opponent
	 , p.first_pick_rate_dust2_opponent

	 , p.first_ban_rate_mirage_opponent
	 , p.first_ban_rate_ancient_opponent
	 , p.first_ban_rate_vertigo_opponent
	 , p.first_ban_rate_nuke_opponent
	 , p.first_ban_rate_inferno_opponent
	 , p.first_ban_rate_overpass_opponent
	 , p.first_ban_rate_dust2_opponent

	 , p.win_rate
	 , p.win_rate_ancient
	 , p.win_rate_vertigo
	 , p.win_rate_nuke
	 , p.win_rate_mirage
	 , p.win_rate_inferno
	 , p.win_rate_overpass
	 , p.win_rate_dust2
