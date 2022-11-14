import re
from tools import get_html_code
from datetime import datetime


class PlayerGame:
    def __init__(self, player_data, name):

        self.name = name

        # total
        self.kills = player_data['totalstats'][name]['kills']
        self.deaths = player_data['totalstats'][name]['deaths']
        self.adr = player_data['totalstats'][name]['adr']
        self.rating = player_data['totalstats'][name]['rating']
        self.kast = player_data['totalstats'][name]['kast']

        # ct
        self.ct_kills = player_data['ctstats'][name]['kills']
        self.ct_deaths = player_data['ctstats'][name]['deaths']
        self.ct_adr = player_data['ctstats'][name]['adr']
        self.ct_rating = player_data['ctstats'][name]['rating']
        self.ct_kast = player_data['ctstats'][name]['kast']

        # t
        self.t_deaths = player_data['tstats'][name]['deaths']
        self.t_adr = player_data['tstats'][name]['adr']
        self.t_rating = player_data['tstats'][name]['rating']
        self.t_kills = player_data['tstats'][name]['kills']
        self.t_kast = player_data['tstats'][name]['kast']


class TeamMatch:
    def __init__(self, name):
        self.id = 0
        self.name = name
        self.rank = 0


class TeamGame:
    def __init__(self, score, scores_sides, player_stats):
        self.score = int(score)
        self.start_side = scores_sides[0]['class'][0]

        self.score_ct = int(scores_sides[0].text if self.start_side == 'ct' else scores_sides[1].text)
        self.score_t = int(scores_sides[0].text if self.start_side == 't' else scores_sides[1].text)

        self.lineup = [
            PlayerGame(player_stats, player) for player in player_stats['totalstats'].keys()
        ]


class PicksAndBans:
    def __init__(self, actions, map_pool):
        self.available_maps = map_pool
        self.actions = [PicksAndBansAction(action) for action in actions]

        self.max_games = sum([act.type in ['picked', 'was left'] for act in self.actions])

        for action in self.actions:
            action.available_maps = self.available_maps[::]
            self.available_maps.remove(action.map)

        self.available_maps = map_pool


class PicksAndBansAction:
    def __init__(self, text):
        self.text = text
        self.type = self.find_type()
        self.author = self.find_author()
        self.map = self.find_map()
        self.order = int(self.text[0])
        self.available_maps = None

    def find_type(self):
        for expression in ['removed', 'picked', 'was left']:
            if expression in self.text:
                return expression

    def find_author(self):
        if self.type in ['removed', 'picked']:
            pat = r'[1-7]\. (.*) (picked|removed) (.*)'
            match = re.search(pat, self.text)
            return match.group(1)
        else:
            return 'decider'

    def find_map(self):
        if self.type in ['removed', 'picked']:
            pat = r'[1-7]\. (.*) (picked|removed) (.*)'
            match = re.search(pat, self.text)
            return match.group(3)
        else:
            pat = r'[1-7]\. (.*) was left over'
            match = re.search(pat, self.text)
            return match.group(1)


class Game:
    def __init__(self, map_name, scores, scores_sides, tabelas, team1, team2):

        player_data = dict()

        for time in tabelas:
            classe = time['class']

            team_name = time.find('a', attrs={'class': 'teamName team'}).text

            if team_name not in player_data:
                player_data[team_name] = dict()

            if classe[1] not in player_data[team_name]:
                player_data[team_name][classe[1]] = dict()

            jogo_jogador = time.find_all('tr')[1::]

            for jogador in jogo_jogador:
                name = jogador.find('span', attrs={'class': 'player-nick'})
                nick = name.text if name is not None else None
                kd = jogador.find('td', attrs={'class': 'kd text-center'}).text
                adr = jogador.find('td', attrs={'class': 'adr text-center'}).text
                kast = jogador.find('td', attrs={'class': 'kast text-center'}).text
                rating = jogador.find('td', attrs={'class': 'rating text-center'}).text

                player_data[team_name][classe[1]].update({nick: {
                        'kills': int(kd.split('-')[0]),
                        'deaths': int(kd.split('-')[1]),
                        'adr': adr,
                        'kast': float(kast.replace('%', '')),
                        'rating': rating
                    }})

        self.map_name = map_name
        self.team1 = TeamGame(
            scores[0],
            scores_sides[0:3:2],
            player_data[team1]
        )

        self.team2 = TeamGame(
            scores[1],
            scores_sides[1:4:2],
            player_data[team2]
        )

        self.winner = self.team1 if self.team1.score > self.team2.score else self.team2

        self.ot = (self.team1.score + self.team2.score) > 30


class Match:
    def __init__(self, link):

        pagina = get_html_code(link)

        self.hltv_link = link

        self.date_unix = pagina.find('div', attrs={'class': 'date'})['data-unix']

        self.date = datetime.utcfromtimestamp(int(self.date_unix) / 1000).strftime('%Y-%m-%d')  # convert to date

        self.team1 = TeamMatch(pagina.find_all('div', attrs={'class': 'teamName'})[0].text)
        self.team2 = TeamMatch(pagina.find_all('div', attrs={'class': 'teamName'})[1].text)

        event_root = pagina.find('div', attrs={'class': 'event text-ellipsis'})

        self.event = event_root.text
        self.event_link = 'https://www.hltv.org' + event_root.find('a')['href']

        self.team1.rank = pagina.find_all('div', attrs={'class': 'teamRanking'})[0].text.replace(
            'World rank: #', ''
        )

        self.team2.rank = pagina.find_all('div', attrs={'class': 'teamRanking'})[1].text.replace(
            'World rank: #', ''
        )

        if self.team1.rank == '\nUnranked\n' or self.team1.rank == '':
            self.team1.rank = None

        if self.team2.rank == '\nUnranked\n' or self.team2.rank == '':
            self.team2.rank = None

        maps = pagina.find('div', attrs={'class': 'g-grid maps'})
        bans_list = maps.find_all('div', attrs={'class': 'padding'})
        if len(bans_list) > 1:
            bans_list = bans_list[1]

        bans_list = [str(x).replace('<div>', '').replace('</div>', '') for x in bans_list.find_all('div')]

        active_maps = ['Ancient', 'Dust2', 'Mirage', 'Vertigo', 'Overpass', 'Nuke', 'Inferno']
        self.picks = PicksAndBans(bans_list, active_maps)

        maps = pagina.find_all('div', attrs={'class': 'mapname'})
        self.maps_to_play = [game.text for game in maps]

        # Informações de placar, CT e T, e estatísticas do jogo
        scores = [s.text for s in pagina.find_all('div', attrs={'class': 'results-team-score'})]
        scores_sides = pagina.find_all('div', attrs={'class': 'results-center-half-score'})
        players_stats = pagina.find_all('div', attrs={'class': 'stats-content'})[1::]

        self.games = list()
        for idx, map_name in enumerate(self.maps_to_play):
            try:
                game_scores = scores[idx*2:idx*2+2]
                game_scores_sides = scores_sides[idx].find_all('span', attrs={'class': ['ct', 't']})
                tabelas = players_stats[idx].find_all('table')

                self.games.append(
                    Game(
                        map_name,
                        game_scores,
                        game_scores_sides,
                        tabelas,
                        self.team1.name,
                        self.team2.name
                    )
                )

            except IndexError:
                print(f'Jogo não jogado no mapa {map_name}.')


class FutureMatch:
    def __init__(self, link):

        pagina = get_html_code(link)

        self.hltv_link = link

        self.date_unix = pagina.find('div', attrs={'class': 'date'})['data-unix']

        self.date = datetime.utcfromtimestamp(int(self.date_unix) / 1000).strftime('%Y-%m-%d')  # convert to date

        self.team1 = TeamMatch(pagina.find_all('div', attrs={'class': 'teamName'})[0].text)
        self.team2 = TeamMatch(pagina.find_all('div', attrs={'class': 'teamName'})[1].text)

        event_root = pagina.find('div', attrs={'class': 'event text-ellipsis'})

        self.event = event_root.text
        self.event_link = 'https://www.hltv.org' + event_root.find('a')['href']

        try:
            self.team1.rank = pagina.find_all('div', attrs={'class': 'teamRanking'})[0].text.replace(
                'World rank: #', ''
            )

            self.team2.rank = pagina.find_all('div', attrs={'class': 'teamRanking'})[1].text.replace(
                'World rank: #', ''
            )
        except IndexError:
            self.team1.rank = None
            self.team2.rank = None

        if self.team1.rank == '\nUnranked\n' or self.team1.rank == '':
            self.team1.rank = None

        if self.team2.rank == '\nUnranked\n' or self.team2.rank == '':
            self.team2.rank = None

        maps = pagina.find('div', attrs={'class': 'g-grid maps'})
        bans_list = maps.find_all('div', attrs={'class': 'padding'})
        if len(bans_list) > 1:
            bans_list = bans_list[1]

        try:
            bans_list = [str(x).replace('<div>', '').replace('</div>', '') for x in bans_list.find_all('div')]

            active_maps = ['Ancient', 'Dust2', 'Mirage', 'Vertigo', 'Overpass', 'Nuke', 'Inferno']
            self.picks = PicksAndBans(bans_list, active_maps)

            self.maps_to_play = [action.map for action in self.picks.actions if action.type in ('picked', 'was left')]
        except AttributeError:
            self.maps_to_play = list()