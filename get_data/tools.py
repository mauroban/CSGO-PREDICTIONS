import requests
from bs4 import BeautifulSoup
from time import sleep
import pyodbc
from config import con
import pandas as pd


def get_html_code(url):
    sleep(2.5)
    x = requests.get(url)
    print(url)
    return BeautifulSoup(x.text, features="html.parser")


def get_paginas(inicio, fim):
    paginas = {
        'pagina 1': f'https://www.hltv.org/stats/matches?startDate={inicio}&endDate={fim}',
    }

    pagina_html = get_html_code(paginas['pagina 1'])
    jogos = int(pagina_html.find('div', 'pagination-component with-stats-table').text.split()[-1])
    print(jogos)
    if jogos > 50:
        x = range(50,
                  jogos,
                  50)

        count = 2
        for num in x:
            paginas.update({
                'pagina ' + str(count): f'https://www.hltv.org/stats/matches?startDate={inicio}&endDate={fim}' + '&offset=' + str(num)
            })
            count += 1

    total_paginas = len(paginas.keys())
    print(f'{total_paginas} páginas.')
    return paginas


def get_links_jogos(pagina):
    links_jogos = list()
    pagina_html = get_html_code(pagina)

    jogos = pagina_html.find('table', attrs={'class': 'stats-table matches-table no-sort'})
    lista_jogos = jogos.find_all('tr')

    for jogo in lista_jogos[1::]:
        link_partida = jogo.find('td', attrs={'class': 'date-col'})
        link_partida = link_partida.find('a')

        if link_partida.has_attr('href'):
            pagina_jogo = get_html_code('https://www.hltv.org/' + link_partida['href'])
            link_serie = pagina_jogo.find('a', attrs={'class': 'match-page-link button'})['href']

            links_jogos.append('https://www.hltv.org' + link_serie)

    return links_jogos


def get_links_jogos_futuros():

    pagina = 'https://www.hltv.org/matches'

    links_jogos = list()
    pagina_html = get_html_code(pagina)

    jogos_live = pagina_html.find('div', attrs={'class': 'liveMatches'})
    jogos_marcados = pagina_html.find_all('div', attrs={'class': 'upcomingMatchesSection'})[0:2]

    lista_jogos_marcados = jogos_marcados[0].find_all('a', attrs={'class': 'match a-reset'}) + jogos_marcados[1].find_all('a', attrs={'class': 'match a-reset'})

    # lista_jogos_marcados = jogos_marcados.find_all('a', attrs={'class': 'match a-reset'})

    if jogos_live is not None:
        lista_jogos_live = jogos_live.find_all('a', attrs={'class': 'match a-reset'})
    else:
        lista_jogos_live = list()

    lista_jogos = list(lista_jogos_live) + list(lista_jogos_marcados)

    for jogo in lista_jogos:
        print(jogo['href'])
        if jogo.has_attr('href'):
            pagina_jogo = 'https://www.hltv.org' + jogo['href']
            links_jogos.append(pagina_jogo)

    print(links_jogos)

    return links_jogos


class MatchTables:
    def __init__(self, match):

        # Tables
        self.tables = {
            'EVENT': pd.DataFrame(columns=['NAME', 'HLTV_LINK']),
            'MATCH': pd.DataFrame(columns=['ID', 'HLTV_LINK', 'EVENT_NAME', 'DATE_UNIX', 'EVENT_DATE', 'MAX_GAMES',
                                           'TEAM1', 'TEAM2', 'TEAM1RANK', 'TEAM2RANK']),
            'PICK_ACTION': pd.DataFrame(columns=['MATCH_ID', 'PICK_ORDER', 'RAW_TEXT', 'TYPE', 'AUTHOR', 'MAP']),
            'AVAILABLE_MAP':  pd.DataFrame(columns=['MATCH_ID', 'PICK_ORDER', 'MAP_NAME']),
            'GAME':  pd.DataFrame(columns=['MATCH_ID', 'GAME_NUM', 'MAP_NAME', 'TEAM1', 'TEAM2', 'WINNER', 'OT']),
            'TEAM_GAME': pd.DataFrame(columns=['MATCH_ID', 'GAME_NUM', 'NAME', 'RANK', 'SCORE', 'START_SIDE',
                                               'SCORE_CT', 'SCORE_T']),
            'PLAYER_GAME': pd.DataFrame(columns=['MATCH_ID', 'GAME_NUM', 'TEAM_NAME', 'NAME', 'KILLS', 'DEATHS', 'ADR',
                                                 'RATING', 'KAST', 'CT_KILLS', 'CT_DEATHS', 'CT_ADR', 'CT_RATING',
                                                 'CT_KAST', 'T_DEATHS', 'T_ADR', 'T_RATING', 'T_KILLS', 'T_KAST']),
        }

        self.match = match
        self.match_id = self.get_match_id()

        # Fill tables
        self.insert_row(
            'EVENT',
            {
                'NAME': self.match.event,
                'HLTV_LINK': self.match.event_link
            }
        )

        self.insert_row(
            'MATCH',
            {
                'ID': self.match_id,
                'HLTV_LINK': self.match.hltv_link,
                'EVENT_NAME': self.match.event,
                'DATE_UNIX': self.match.date_unix,
                'EVENT_DATE': self.match.date,
                'MAX_GAMES': len(self.match.maps_to_play),
                'TEAM1': self.match.team1.name,
                'TEAM2': self.match.team2.name,
                'TEAM1RANK': self.match.team1.rank,
                'TEAM2RANK': self.match.team2.rank,

            }
        )

        for action in match.picks.actions:
            self.insert_row(
                'PICK_ACTION',
                {
                    'MATCH_ID': self.match_id,
                    'PICK_ORDER': action.order,
                    'RAW_TEXT': action.text,
                    'TYPE': action.type,
                    'AUTHOR': action.author,
                    'MAP': action.map
                }
            )
            for map_name in action.available_maps:
                self.insert_row(
                    'AVAILABLE_MAP',
                    {
                        'MATCH_ID': self.match_id,
                        'PICK_ORDER': action.order,
                        'MAP_NAME': map_name,
                    }
                )

        game_num = 0
        for game in self.match.games:
            game_num += 1
            self.insert_row(
                'GAME',
                {
                    'MATCH_ID': self.match_id,
                    'GAME_NUM': game_num,
                    'MAP_NAME': game.map_name,
                    'TEAM1': self.match.team1.name,
                    'TEAM2': self.match.team2.name,
                    'WINNER': self.match.team1.name if game.team1.score > game.team2.score else self.match.team2.name,
                    'OT': game.team1.score + game.team2.score > 30
                }
            )

            for team_match, team in {
                self.match.team1: game.team1,
                self.match.team2: game.team2
            }.items():
                self.insert_row(
                    'TEAM_GAME',
                    {
                        'MATCH_ID': self.match_id,
                        'GAME_NUM': game_num,
                        'NAME': team_match.name,
                        'RANK': team_match.rank,
                        'SCORE': team.score,
                        'START_SIDE': team.start_side,
                        'SCORE_CT': team.score_ct,
                        'SCORE_T': team.score_t,
                    }
                )

                for player in team.lineup:
                    self.insert_row(
                        'PLAYER_GAME',
                        {
                            'MATCH_ID': self.match_id,
                            'GAME_NUM': game_num,
                            'TEAM_NAME': team_match.name,
                            'NAME': player.name,
                            'KILLS': player.kills,
                            'DEATHS': player.deaths,
                            'ADR': player.adr,
                            'RATING': player.rating,
                            'KAST': player.kast,
                            'CT_KILLS': player.ct_kills,
                            'CT_DEATHS': player.ct_deaths,
                            'CT_ADR': player.ct_adr,
                            'CT_RATING': player.ct_rating,
                            'CT_KAST': player.ct_kast,
                            'T_DEATHS': player.t_deaths,
                            'T_ADR': player.t_adr,
                            'T_RATING': player.t_rating,
                            'T_KILLS': player.t_kills,
                            'T_KAST': player.t_kast
                        }
                    )

        self.save_match_to_db()

        # for table in self.tables.values():
        #     print(table)

    def insert_row(self, table, row_dict):
        i = len(self.tables[table])
        self.tables[table].loc[i] = row_dict

    def get_match_id(self):
        cursor = con.cursor()
        cursor.execute(f"SELECT id from MATCH where HLTV_LINK = '{self.match.hltv_link}'")

        found = cursor.fetchone()
        if found:
            return found[0]

        cursor = con.cursor()
        cursor.execute("SELECT max(id) last_id from MATCH")

        last_id = cursor.fetchone().last_id

        if last_id:
            return last_id + 1
        else:
            return 1

    def save_match_to_db(self):
        inseridas = 0
        nao_inseridas = 0
        cursor = con.cursor()
        for table_name, table in self.tables.items():
            colunas = tuple(table.columns)
            command = f"""INSERT INTO {table_name} {colunas}
                          VALUES(""".replace("'", "") + "?,"*(len(colunas) - 1) + '?)'

            for row in table.values:
                try:
                    cursor.execute(command, list(row))
                    inseridas += 1
                except pyodbc.IntegrityError as er:
                    nao_inseridas += 1
                except pyodbc.ProgrammingError:
                    print(command)
                    print(list(row))

        con.commit()


class FutureMatchTable:
    def __init__(self, match):
        self.match = match
        self.tables = {'MATCHES_TO_PREDICT': pd.DataFrame(columns=[
                'HLTV_LINK',
                'TEAM1',
                'TEAM2',
                'EVENT_NAME',
                'DATA',
                'TEAM1RANK',
                'TEAM2RANK',
                'MAP1',
                'MAP2',
                'MAP3',
                'MAP4',
                'MAP5'
            ])
        }

        self.get_maps()

        self.insert_row(
            'MATCHES_TO_PREDICT',
            {
                'HLTV_LINK': self.match.hltv_link,
                'TEAM1': self.match.team1.name,
                'TEAM2': self.match.team2.name,
                'EVENT_NAME': self.match.event,
                'DATA': self.match.date,
                'TEAM1RANK': self.match.team1.rank,
                'TEAM2RANK': self.match.team2.rank,
                'MAP1': self.map1,
                'MAP2': self.map2,
                'MAP3': self.map3,
                'MAP4': self.map4,
                'MAP5': self.map5
            }
        )

        self.save_match_to_db()

    def insert_row(self, table, row_dict):
        i = len(self.tables[table])
        self.tables[table].loc[i] = row_dict

    def get_maps(self):
        self.map1 = self.match.maps_to_play[0] if len(self.match.maps_to_play) > 0 else None
        self.map2 = self.match.maps_to_play[1] if len(self.match.maps_to_play) > 1 else None
        self.map3 = self.match.maps_to_play[2] if len(self.match.maps_to_play) > 2 else None
        self.map4 = self.match.maps_to_play[3] if len(self.match.maps_to_play) > 3 else None
        self.map5 = self.match.maps_to_play[4] if len(self.match.maps_to_play) > 4 else None

    def save_match_to_db(self):
        inseridas = 0
        nao_inseridas = 0
        cursor = con.cursor()
        for table_name, table in self.tables.items():
            colunas = tuple(table.columns)
            command = f"""INSERT INTO {table_name} {colunas}
                          VALUES(""".replace("'", "") + "?,"*(len(colunas) - 1) + '?)'

            for row in table.values:
                try:
                    cursor.execute(command, list(row))
                    inseridas += 1
                except pyodbc.IntegrityError as er:
                    command = f"""UPDATE {table_name}
                                 SET MAP1 = '{self.map1}',
                                     MAP2 = '{self.map2}',
                                     MAP3 = '{self.map3}',
                                     MAP4 = '{self.map4}',
                                     MAP5 = '{self.map5}'
                                WHERE HLTV_LINK = '{self.match.hltv_link}'
                                """
                    nao_inseridas += 1
                except pyodbc.ProgrammingError:
                    print(command)
                    print(list(row))

        con.commit()
