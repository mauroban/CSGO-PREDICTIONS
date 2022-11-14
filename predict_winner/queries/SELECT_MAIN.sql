with 

ratings as (
SELECT g.MATCH_ID
	 , g.GAME_NUM
	 , g.MAP_NAME
	 , tg1."NAME" TEAM_NAME

	 , sum(pg.rating) sum_rating
	 , max(pg.rating) max_rating
	 , min(pg.rating) min_rating

	 , sum(pg.T_RATING) sum_t_rating
	 , sum(pg.CT_RATING) sum_ct_rating

	 , sum(pg.kast) sum_kast
	 , sum(PG.ADR) sum_adr

	 , count(1) players_played


from game g
left join TEAM_GAME tg1 on g.MATCH_ID = tg1.MATCH_ID and g.GAME_NUM = tg1.GAME_NUM and g.TEAM1 = tg1."NAME"
LEFT JOIN PLAYER_GAME pg on g.MATCH_ID = pg.MATCH_ID and g.GAME_NUM = pg.GAME_NUM and tg1."NAME" = pg.TEAM_NAME


group by g.MATCH_ID
	 , g.GAME_NUM
	 , g.MAP_NAME
	 , tg1."NAME"

),


games as (

select
	   g.MATCH_ID
	 , m.HLTV_LINK
	 , g.GAME_NUM
	 , m.DATE_UNIX
	 , m.EVENT_NAME
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
	 , CASE WHEN g.GAME_NUM = MAX_GAMES then 1 else 0 end DECIDER

	 , tg1.score + tg2.score as rounds_played
	 , tg1.score_ct + tg2.score_t as rounds_played_ct
	 , tg1.score_t + tg2.score_ct as rounds_played_t

	 , r.sum_rating
	 , r.max_rating
	 , r.min_rating

	 , r.sum_t_rating
	 , r.sum_ct_rating

	 , r.sum_kast
	 , r.sum_adr

	 , r.players_played

from game g
left join TEAM_GAME tg1 on g.MATCH_ID = tg1.MATCH_ID and g.GAME_NUM = tg1.GAME_NUM and g.TEAM1 = tg1."NAME"
left join TEAM_GAME tg2 on g.MATCH_ID = tg2.MATCH_ID and g.GAME_NUM = tg2.GAME_NUM and g.TEAM2 = tg2."NAME"
left join ratings r on g.MATCH_ID = r.MATCH_ID and g.GAME_NUM = r.GAME_NUM and g.TEAM1 = r.TEAM_NAME
left join MATCH m on g.MATCH_ID = m.ID

),

event_importance as (
select EVENT_NAME
	 , SUM(CASE WHEN TEAM1RANK <= 20 OR TEAM2RANK <= 20 THEN 1 ELSE 0 END) JOGOS_AO_MENOS_1_TOP_20
	 , COUNT(1) JOGOS
	 , SUM(CASE WHEN TEAM1RANK <= 20 OR TEAM2RANK <= 20 THEN 1.0 ELSE 0 END) /COUNT(1) top_20_rate
from MATCH
group by EVENT_NAME
),

picks as (


select pa.MATCH_ID
	 , pa.PICK_ORDER
	 , pa.TYPE
	 , pa.AUTHOR
	 , pa.MAP
	 , case when team1 = pa.author then team2 else team1 end as OPPONENT
	 , m.MAX_GAMES
	 , m.DATE_UNIX
	 , case when pa.PICK_ORDER <= 2 and pa.TYPE = 'removed' then 1 else 0 end first_ban
	 , case when m.MAX_GAMES = 3 and pa.PICK_ORDER <= 4 and pa.TYPE = 'picked' then 1 else 0 end first_pick

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

games_team as (

SELECT g.MATCH_ID
	 , g.HLTV_LINK
	 , g.EVENT_NAME
	 , g.GAME_NUM
	 , g.DATE_UNIX
	 , g.MAP_NAME
	 , g.TEAM_NAME
	 , g.OPPONENT
	 , g.win
	 , g.SCORE
	 , g.SCORE_CT
	 , g.SCORE_T
	 , g."RANK"
	 , g.SCORE_OPPONENT
	 , g.SCORE_CT_OPPONENT
	 , g.SCORE_T_OPPONENT
	 , g.RANK_OPPONENT
	 , g.DECIDER

	 , g.rounds_played
	 , g.rounds_played_ct
	 , g.rounds_played_t

	 , case when g."RANK" < G.RANK_OPPONENT - 10 OR g."RANK" < G.RANK_OPPONENT/2 THEN 1 ELSE 0 END FAVORITO

	 , sum(case when (g.TEAM_NAME = g2.TEAM_NAME and g.OPPONENT = g2.OPPONENT) THEN 1.0*g2.win ELSE 0 END)/nullif(sum(case when (g.TEAM_NAME = g2.TEAM_NAME and g.OPPONENT = g2.OPPONENT) THEN 1 ELSE 0 END), 0) HISTORICO

	 , sum(g2.sum_rating)/sum(g2.players_played) avg_rating
	 , sum(g2.sum_adr)/sum(g2.players_played) avg_adr
	 , sum(g2.sum_kast)/sum(g2.players_played) avg_kast

	 , sum(case when g2.MAP_NAME = g.MAP_NAME THEN g2.sum_rating ELSE 0 END)/NULLIF(sum(case when g2.MAP_NAME = g.MAP_NAME THEN g2.players_played ELSE 0 END), 0) avg_rating_map
	 , sum(case when g2.MAP_NAME = g.MAP_NAME THEN g2.sum_adr ELSE 0 END)/NULLIF(sum(case when g2.MAP_NAME = g.MAP_NAME THEN g2.players_played ELSE 0 END), 0) avg_adr_map
	 , sum(case when g2.MAP_NAME = g.MAP_NAME THEN g2.sum_kast ELSE 0 END)/NULLIF(sum(case when g2.MAP_NAME = g.MAP_NAME THEN g2.players_played ELSE 0 END), 0) avg_kast_map

	 , coalesce(DATEDIFF(day, max(CAST(DATEADD(SECOND, g2.DATE_UNIX/1000,'1970/1/1') AS DATE)), CAST(DATEADD(SECOND, g.DATE_UNIX/1000,'1970/1/1') AS DATE)), 35) dias_sem_jogar
	 , sum(case when g2.MAP_NAME = g.MAP_NAME THEN 1.0*g2.win ELSE 0 END)/NULLIF(sum(case when g2.MAP_NAME = g.MAP_NAME THEN 1.0 ELSE 0 END), 0) win_rate_map
	 , sum(case when g2.RANK_OPPONENT <= 10 THEN 1.0 ELSE 0 END) jogos_top10
	 , sum(case when g2.RANK_OPPONENT <= 10 THEN 1.0*g2.win ELSE 0 END)/NULLIF(sum(case when g2.RANK_OPPONENT <= 10 THEN 1.0 ELSE 0 END), 0) win_rate_top10
	 , sum(case when g2.RANK_OPPONENT <= 20 THEN 1.0*g2.win ELSE 0 END)/NULLIF(sum(case when g2.RANK_OPPONENT <= 20 THEN 1.0 ELSE 0 END), 0) win_rate_top20
	 , sum(case when g2.RANK_OPPONENT <= 50 THEN 1.0*g2.win ELSE 0 END)/NULLIF(sum(case when g2.RANK_OPPONENT <= 50 THEN 1.0 ELSE 0 END), 0) win_rate_top50
	 , sum(case when g2.RANK_OPPONENT <= 100 THEN 1.0*g2.win ELSE 0 END)/NULLIF(sum(case when g2.RANK_OPPONENT <= 100 THEN 1.0 ELSE 0 END), 0) win_rate_top100
	 , sum(case when (g.RANK_OPPONENT + 10 > g2.RANK_OPPONENT and g.RANK_OPPONENT - 10 < g2.RANK_OPPONENT) THEN 1.0*g2.win ELSE 0 END)/NULLIF(sum(case when (g.RANK_OPPONENT + 10 > g2.RANK_OPPONENT and g.RANK_OPPONENT - 10 < g2.RANK_OPPONENT) THEN 1.0 ELSE 0 END), 0) win_rate_same_rank
	 , sum(case when g2.MAP_NAME = g.MAP_NAME THEN 1.0*g2.score ELSE 0 END)/NULLIF(sum(case when g2.MAP_NAME = g.MAP_NAME THEN g2.rounds_played ELSE 0 END), 0) round_win_rate_map
	 , sum(case when g2.MAP_NAME = g.MAP_NAME and g2.RANK_OPPONENT <= 30 THEN 1.0*g2.score ELSE 0 END)/NULLIF(sum(case when g2.MAP_NAME = g.MAP_NAME and g2.RANK_OPPONENT <= 30 THEN g2.rounds_played ELSE 0 END), 0) round_win_rate_map_top30
	 , sum(case when g2.MAP_NAME = g.MAP_NAME THEN 1.0*g2.SCORE_T ELSE 0 END)/NULLIF(sum(case when g2.MAP_NAME = g.MAP_NAME THEN g2.rounds_played_t ELSE 0 END), 0) t_round_win_rate_map
	 , sum(case when g2.MAP_NAME = g.MAP_NAME THEN 1.0*g2.SCORE_CT ELSE 0 END)/NULLIF(sum(case when g2.MAP_NAME = g.MAP_NAME THEN g2.rounds_played_ct ELSE 0 END), 0) ct_round_win_rate_map
	 , sum(case when g2.MAP_NAME = g.MAP_NAME THEN 1 ELSE 0 END) jogos_map
	 , sum(case when g2.MAP_NAME = g.MAP_NAME THEN g2.rounds_played ELSE 0 END) rounds_map
	 , count(1) jogos
from games g
left join games g2 on g.TEAM_NAME = g2.TEAM_NAME and g2.DATE_UNIX < g.DATE_UNIX and g2.date_unix >= g.DATE_UNIX - 2*2548000000 and g.MATCH_ID <> g2.MATCH_ID

group by g.MATCH_ID
	 , g.HLTV_LINK
	 , g.EVENT_NAME
	 , g.GAME_NUM
	 , g.DATE_UNIX
	 , g.MAP_NAME
	 , g.TEAM_NAME
	 , g.OPPONENT
	 , g.win
	 , g.SCORE
	 , g.SCORE_CT
	 , g.SCORE_T
	 , g."RANK"
	 , g.SCORE_OPPONENT
	 , g.SCORE_CT_OPPONENT
	 , g.SCORE_T_OPPONENT
	 , g.RANK_OPPONENT

	 , g.rounds_played
	 , g.rounds_played_ct
	 , g.rounds_played_t
	 , g.DECIDER
),


games_full as (

SELECT g.MATCH_ID
	 , g.HLTV_LINK
	 , g.EVENT_NAME
	 , ev.top_20_rate top_20_rate_event
	 , g.GAME_NUM
	 , g.DATE_UNIX
	 , g.MAP_NAME
	 , g.TEAM_NAME
	 , g.OPPONENT
	 , g.win
	 , g.SCORE
	 , g.SCORE_CT
	 , g.SCORE_T
	 , g."RANK"
	 , g.SCORE_OPPONENT
	 , g.SCORE_CT_OPPONENT
	 , g.SCORE_T_OPPONENT
	 , g.RANK_OPPONENT
	 , g.DECIDER
	 , g.dias_sem_jogar

	 , g.FAVORITO
	 , g.HISTORICO

	 , g.jogos_top10
	 , g.win_rate_top10
	 , g.win_rate_top20
	 , g.win_rate_top50
	 , g.win_rate_top100
	 , g.win_rate_map
	 , g.win_rate_same_rank
	 , g.round_win_rate_map
	 , g.round_win_rate_map_top30
	 , g.t_round_win_rate_map
	 , g.ct_round_win_rate_map
	 , g.jogos_map
	 , g.rounds_map
	 , g.jogos

	 , g.avg_rating
	 , g.avg_adr
	 , g.avg_kast

	 , g.avg_rating_map
	 , g.avg_adr_map
	 , g.avg_kast_map

	 , sum(g2.sum_rating)/sum(g2.players_played) avg_rating_opponent
	 , sum(g2.sum_adr)/sum(g2.players_played) avg_adr_opponent
	 , sum(g2.sum_kast)/sum(g2.players_played) avg_kast_opponent

	 , sum(case when g2.MAP_NAME = g.MAP_NAME THEN 1.0*g2.win ELSE 0 END)/NULLIF(sum(case when g2.MAP_NAME = g.MAP_NAME THEN 1.0 ELSE 0 END), 0) win_rate_map_opponent

	 , sum(case when (g.TEAM_NAME = g2.TEAM_NAME and g.OPPONENT = g2.OPPONENT) THEN 1.0*g2.win ELSE 0 END)/nullif(sum(case when (g.TEAM_NAME = g2.TEAM_NAME and g.OPPONENT = g2.OPPONENT) THEN 1 ELSE 0 END), 0) HISTORICO_OPPONENT

	 , sum(case when g2.MAP_NAME = g.MAP_NAME THEN g2.sum_rating ELSE 0 END)/NULLIF(sum(case when g2.MAP_NAME = g.MAP_NAME THEN g2.players_played ELSE 0 END), 0) avg_rating_map_opponent
	 , sum(case when g2.MAP_NAME = g.MAP_NAME THEN g2.sum_adr ELSE 0 END)/NULLIF(sum(case when g2.MAP_NAME = g.MAP_NAME THEN g2.players_played ELSE 0 END), 0) avg_adr_map_opponent
	 , sum(case when g2.MAP_NAME = g.MAP_NAME THEN g2.sum_kast ELSE 0 END)/NULLIF(sum(case when g2.MAP_NAME = g.MAP_NAME THEN g2.players_played ELSE 0 END), 0) avg_kast_map_opponent

	 , sum(case when g2.RANK_OPPONENT <= 10 THEN 1.0 ELSE 0 END) jogos_top10_opponent
	 , sum(case when g2.RANK_OPPONENT <= 10 THEN 1.0*g2.win ELSE 0 END)/NULLIF(sum(case when g2.RANK_OPPONENT <= 10 THEN 1.0 ELSE 0 END), 0) win_rate_top10_opponent
	 , sum(case when g2.RANK_OPPONENT <= 20 THEN 1.0*g2.win ELSE 0 END)/NULLIF(sum(case when g2.RANK_OPPONENT <= 20 THEN 1.0 ELSE 0 END), 0) win_rate_top20_opponent
	 , sum(case when g2.RANK_OPPONENT <= 50 THEN 1.0*g2.win ELSE 0 END)/NULLIF(sum(case when g2.RANK_OPPONENT <= 50 THEN 1.0 ELSE 0 END), 0) win_rate_top50_opponent
	 , sum(case when g2.RANK_OPPONENT <= 100 THEN 1.0*g2.win ELSE 0 END)/NULLIF(sum(case when g2.RANK_OPPONENT <= 100 THEN 1.0 ELSE 0 END), 0) win_rate_top100_opponent
	 , COALESCE(DATEDIFF(day, max(CAST(DATEADD(SECOND, g2.DATE_UNIX/1000,'1970/1/1') AS DATE)), CAST(DATEADD(SECOND, g.DATE_UNIX/1000,'1970/1/1') AS DATE)), 35) dias_sem_jogar_opponent
	 , sum(case when (g.RANK + 10 > g2.RANK_OPPONENT and g.RANK - 10 < g2.RANK_OPPONENT) THEN 1.0*g2.win ELSE 0 END)/NULLIF(sum(case when (g.RANK_OPPONENT + 10 > g2.RANK_OPPONENT and g.RANK_OPPONENT - 10 < g2.RANK_OPPONENT) THEN 1.0 ELSE 0 END), 0) win_rate_same_rank_opponent
	 , sum(case when g2.MAP_NAME = g.MAP_NAME THEN 1.0*g2.score ELSE 0 END)/NULLIF(sum(case when g2.MAP_NAME = g.MAP_NAME THEN g2.rounds_played ELSE 0 END), 0) round_win_rate_map_opponent
	 , sum(case when g2.MAP_NAME = g.MAP_NAME and g2.RANK_OPPONENT <= 30 THEN 1.0*g2.score ELSE 0 END)/NULLIF(sum(case when g2.MAP_NAME = g.MAP_NAME and g2.RANK_OPPONENT <= 30 THEN g2.rounds_played ELSE 0 END), 0) round_win_rate_map_top30_opponent
	 , sum(case when g2.MAP_NAME = g.MAP_NAME THEN 1.0*g2.SCORE_T ELSE 0 END)/NULLIF(sum(case when g2.MAP_NAME = g.MAP_NAME THEN g2.rounds_played_t ELSE 0 END), 0) t_round_win_rate_map_opponent
	 , sum(case when g2.MAP_NAME = g.MAP_NAME THEN 1.0*g2.SCORE_CT ELSE 0 END)/NULLIF(sum(case when g2.MAP_NAME = g.MAP_NAME THEN g2.rounds_played_ct ELSE 0 END), 0) ct_round_win_rate_map_opponent
	 , sum(case when g2.MAP_NAME = g.MAP_NAME THEN 1 ELSE 0 END) jogos_map_opponent
	 , sum(case when g2.MAP_NAME = g.MAP_NAME THEN g2.rounds_played ELSE 0 END) rounds_map_opponent
	 , count(1) jogos_opponent
from games_team g
left join games g2 on g.TEAM_NAME = g2.OPPONENT and g2.DATE_UNIX < g.DATE_UNIX and g2.date_unix >= g.DATE_UNIX - 2*2548000000 and g.MATCH_ID <> g2.MATCH_ID
LEFT JOIN event_importance ev on g.EVENT_NAME = ev.EVENT_NAME

group by g.MATCH_ID
	 , g.HLTV_LINK
	 , g.EVENT_NAME
	 , ev.top_20_rate
	 , g.GAME_NUM
	 , g.DATE_UNIX
	 , g.MAP_NAME
	 , g.TEAM_NAME
	 , g.OPPONENT
	 , g.win
	 , g.SCORE
	 , g.SCORE_CT
	 , g.SCORE_T
	 , g.win_rate_top10
	 , g.win_rate_top20
	 , g.win_rate_top50
	 , g.win_rate_top100
	 , g."RANK"
	 , g.SCORE_OPPONENT
	 , g.SCORE_CT_OPPONENT
	 , g.SCORE_T_OPPONENT
	 , g.RANK_OPPONENT
	 , g.DECIDER

	 , g.FAVORITO
	 , g.HISTORICO

	 , g.win_rate_map
	 , g.win_rate_same_rank
	 , g.round_win_rate_map
	 , g.round_win_rate_map_top30
	 , g.t_round_win_rate_map
	 , g.ct_round_win_rate_map
	 , g.jogos_map
	 , g.rounds_map
	 , g.jogos
	 , g.jogos_top10
	 , g.dias_sem_jogar

	 , g.avg_rating
	 , g.avg_adr
	 , g.avg_kast

	 , g.avg_rating_map
	 , g.avg_adr_map
	 , g.avg_kast_map

)

select g.MATCH_ID
	 , g.HLTV_LINK
	 , g.EVENT_NAME
	 , g.top_20_rate_event
	 , g.GAME_NUM
	 , g.DATE_UNIX
	 , g.MAP_NAME
	 , g.TEAM_NAME
	 , g.OPPONENT
	 , g.win
	 , g.SCORE
	 , g.SCORE_CT
	 , g.SCORE_T
	 , g.win_rate_top10
	 , g.win_rate_top20
	 , g.win_rate_top50
	 , g.win_rate_top100
	 , g."RANK"
	 , g.SCORE_OPPONENT
	 , g.SCORE_CT_OPPONENT
	 , g.SCORE_T_OPPONENT
	 , g.RANK_OPPONENT
	 , g.DECIDER
	 , g.HISTORICO
	 , g.HISTORICO_OPPONENT


	 , g.FAVORITO
	 , g.win_rate_map
	 , g.win_rate_same_rank
	 , g.round_win_rate_map
	 , g.round_win_rate_map_top30
	 , g.t_round_win_rate_map
	 , g.ct_round_win_rate_map
	 , 1.0*g.jogos_map/g.jogos jogos_map
	 , g.rounds_map
	 , g.jogos
	 , g.jogos_top10
	 , g.dias_sem_jogar

	 , g.avg_rating
	 , g.avg_adr
	 , g.avg_kast

	 , g.avg_rating_map
	 , g.avg_adr_map
	 , g.avg_kast_map

	 , g.avg_rating_opponent
	 , g.avg_adr_opponent
	 , g.avg_kast_opponent

	 , g.win_rate_map_opponent

	 , g.avg_rating_map_opponent
	 , g.avg_adr_map_opponent
	 , g.avg_kast_map_opponent

	 , g.jogos_top10_opponent
	 , g.win_rate_top10_opponent
	 , g.win_rate_top20_opponent
	 , g.win_rate_top50_opponent
	 , g.win_rate_top100_opponent
	 , g.dias_sem_jogar_opponent
	 , g.win_rate_same_rank_opponent
	 , g.round_win_rate_map_opponent
	 , g.round_win_rate_map_top30_opponent
	 , g.t_round_win_rate_map_opponent
	 , g.ct_round_win_rate_map_opponent
	 , g.jogos_map_opponent
	 , g.rounds_map_opponent
	 , g.jogos_opponent

from games_full g


UNION ALL


select g.MATCH_ID
	 , g.HLTV_LINK
	 , g.EVENT_NAME
	 , g.top_20_rate_event
	 , g.GAME_NUM
	 , g.DATE_UNIX
	 , g.MAP_NAME
	 , g.OPPONENT 
	 , g.TEAM_NAME
	 , CASE WHEN g.win = 1 THEN 0 ELSE 1 END win
	 , g.SCORE_OPPONENT
	 , g.SCORE_CT_OPPONENT
	 , g.SCORE_T_OPPONENT
	 , g.win_rate_top10_opponent
	 , g.win_rate_top20_opponent
	 , g.win_rate_top50_opponent
	 , g.win_rate_top100_opponent
	 , g.RANK_OPPONENT
	 , g.SCORE
	 , g.SCORE_CT
	 , g.SCORE_T
	 , g."RANK"
	 , g.DECIDER
	 , g.HISTORICO
	 , g.HISTORICO_OPPONENT


	 , CASE WHEN g.FAVORITO = 1 THEN 0 ELSE 1 END FAVORITO
	 , g.win_rate_map_opponent
	 , g.win_rate_same_rank_opponent
	 , g.round_win_rate_map_opponent
	 , g.round_win_rate_map_top30_opponent
	 , g.t_round_win_rate_map_opponent
	 , g.ct_round_win_rate_map_opponent
	 , 1.0*g.jogos_map_opponent / g.jogos_opponent jogos_map_opponent
	 , g.rounds_map_opponent
	 , g.jogos_opponent
	 , g.jogos_top10_opponent
	 , g.dias_sem_jogar_opponent

	 , g.avg_rating_opponent
	 , g.avg_adr_opponent
	 , g.avg_kast_opponent

	 , g.avg_rating_map_opponent
	 , g.avg_adr_map_opponent
	 , g.avg_kast_map_opponent

	 , g.avg_rating
	 , g.avg_adr
	 , g.avg_kast

	 , g.win_rate_map

	 , g.avg_rating_map
	 , g.avg_adr_map
	 , g.avg_kast_map

	 , g.jogos_top10
	 , g.win_rate_top10
	 , g.win_rate_top20
	 , g.win_rate_top50
	 , g.win_rate_top100
	 , g.dias_sem_jogar
	 , g.win_rate_same_rank
	 , g.round_win_rate_map
	 , g.round_win_rate_map_top30
	 , g.t_round_win_rate_map
	 , g.ct_round_win_rate_map
	 , g.jogos_map
	 , g.rounds_map
	 , g.jogos

from games_full g