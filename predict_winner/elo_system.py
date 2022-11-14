import warnings
import pandas as pd
warnings.simplefilter(action='ignore', category=FutureWarning)

inicial = {
    1: 1725,
    5: 1700,
    10: 1650,
    20: 1600,
    30: 1550,
    50: 1500,
    100: 1450,
    200: 1400,
    300: 1350,
    350: 1300
}


def calc_points(score, score_opponent, elo, elo_opponent):
    resultado = score > score_opponent
    dif = abs(score - score_opponent)

    expected_points = 1 / (1 + 10 ** ((elo_opponent - elo) / 400))
    return dif ** 0.333 * 16 * (int(resultado) - expected_points)


class Team:
    def __init__(self, rank):
        self.elo = 1300
        for i in inicial.keys():
            if int(rank) <= i:
                self.elo = inicial[i]
                break

        map_elo = {
            'main': float(self.elo),
            'ct': float(self.elo),
            't': float(self.elo),
        }

        self.map_elo = {
            'Mirage': map_elo.copy(),
            'Ancient': map_elo.copy(),
            'Dust2': map_elo.copy(),
            'Inferno': map_elo.copy(),
            'Nuke': map_elo.copy(),
            'Overpass': map_elo.copy(),
            'Vertigo': map_elo.copy()
        }

        self.partidas_disputadas = 0
        self.ultima_partida = None


class Game:
    def __init__(self, game_row):

        # NAMES
        self.team1_name = game_row['TEAM_NAME']
        self.team2_name = game_row['OPPONENT']
        self.map_name = game_row['MAP_NAME']

        # RANKS HLTV

        self.team1_rank = game_row['RANK']
        self.team2_rank = game_row['RANK_OPPONENT']

        # SCORES
        self.team1_score = game_row['SCORE']
        self.team2_score = game_row['SCORE_OPPONENT']

        self.team1_score_ct = game_row['SCORE_CT']
        self.team2_score_ct = game_row['SCORE_CT_OPPONENT']

        self.team2_score_t = game_row['SCORE_T_OPPONENT']
        self.team1_score_t = game_row['SCORE_T']

        self.importancia = game_row['top_20_rate_event']


class Elos:
    def __init__(self):
        self.teams = dict()

    def add_game(self, game):
        if game.team1_name not in self.teams.keys():
            self.teams.update({
                game.team1_name: Team(game.team1_rank)
            })

        if game.team2_name not in self.teams.keys():
            self.teams.update({
                game.team2_name: Team(game.team2_rank)
            })

    def update_elo(self, game):
        team1 = game.team1_name
        team2 = game.team2_name

        # print(team1 + f' {game.team1_score_ct} x {game.team2_score_t} ' + team2)

        self.teams[team1].partidas_disputadas += 1
        self.teams[team2].partidas_disputadas += 1

        points = calc_points(
            score=game.team1_score,
            score_opponent=game.team2_score,
            elo=self.teams[team1].elo,
            elo_opponent=self.teams[team2].elo
        )

        multiplicador = (game.importancia + 1) ** 0.4

        self.teams[team1].elo += points * multiplicador
        self.teams[team2].elo -= points * multiplicador

        for other_map in self.teams[team1].map_elo.keys():
            self.teams[team1].map_elo[other_map]['main'] += 0.1 * points
            self.teams[team2].map_elo[other_map]['main'] -= 0.1 * points

        points_map = 1.375*calc_points(
            score=game.team1_score,
            score_opponent=game.team2_score,
            elo=self.teams[team1].map_elo[game.map_name]['main'],
            elo_opponent=self.teams[team2].map_elo[game.map_name]['main']
        )

        self.teams[team1].map_elo[game.map_name]['main'] += points_map * multiplicador
        self.teams[team2].map_elo[game.map_name]['main'] -= points_map * multiplicador

        points_map_side = 1.375*calc_points(
            score=game.team1_score_ct,
            score_opponent=game.team2_score_t,
            elo=self.teams[team1].map_elo[game.map_name]['ct'],
            elo_opponent=self.teams[team2].map_elo[game.map_name]['t']
        )

        self.teams[team1].map_elo[game.map_name]['ct'] += points_map_side * multiplicador
        self.teams[team2].map_elo[game.map_name]['t'] -= points_map_side * multiplicador

        points_map_side = 1.375*calc_points(
            score=game.team1_score_t,
            score_opponent=game.team2_score_ct,
            elo=self.teams[team1].map_elo[game.map_name]['t'],
            elo_opponent=self.teams[team2].map_elo[game.map_name]['ct']
        )

        self.teams[team1].map_elo[game.map_name]['t'] += points_map_side * multiplicador
        self.teams[team2].map_elo[game.map_name]['ct'] -= points_map_side * multiplicador


def run_data_in_elo_system(df):

    elos_df = pd.DataFrame()
    rank = Elos()

    original_df = df.copy()

    df['elo'] = 1500.0
    df['elo_opponent'] = 1500.0
    df['elo_map'] = 1500.0
    df['elo_map_opponent'] = 1500.0

    df['elo_map_ct'] = 1500.0
    df['elo_map_t'] = 1500.0
    df['elo_map_ct_opponent'] = 1500.0
    df['elo_map_t_opponent'] = 1500.0

    df.drop_duplicates(subset=['MATCH_ID', 'GAME_NUM'], inplace=True)

    df.sort_values('DATE_UNIX', inplace=True, ascending=True, ignore_index=True)
    df.reset_index(inplace=True)

    for i in df.index.values.tolist():
        game = Game(df.iloc[i])

        rank.add_game(game)

        team1 = game.team1_name
        team2 = game.team2_name
        map_name = game.map_name

        elos_df = pd.concat([
            elos_df,
            pd.DataFrame({
                'MATCH_ID': [df.loc[i, 'MATCH_ID']],
                'GAME_NUM': [df.loc[i, 'GAME_NUM']],
                'TEAM_NAME': [team1],
                'elo': [rank.teams[team1].elo],
                'elo_opponent': [rank.teams[team2].elo],
                'elo_map': [rank.teams[team1].map_elo[map_name]['main']],
                'elo_map_opponent': [rank.teams[team2].map_elo[map_name]['main']],
                'elo_map_ct': [rank.teams[team1].map_elo[map_name]['ct']],
                'elo_map_ct_opponent': [rank.teams[team2].map_elo[map_name]['ct']],
                'elo_map_t': [rank.teams[team1].map_elo[map_name]['t']],
                'elo_map_t_opponent': [rank.teams[team2].map_elo[map_name]['t']]
            })
        ], ignore_index=True, axis=0)

        elos_df = pd.concat([
            elos_df,
            pd.DataFrame({
                'MATCH_ID': [df.loc[i, 'MATCH_ID']],
                'GAME_NUM': [df.loc[i, 'GAME_NUM']],
                'TEAM_NAME': [team2],
                'elo': [rank.teams[team2].elo],
                'elo_opponent': [rank.teams[team1].elo],
                'elo_map': [rank.teams[team2].map_elo[map_name]['main']],
                'elo_map_opponent': [rank.teams[team1].map_elo[map_name]['main']],
                'elo_map_ct': [rank.teams[team2].map_elo[map_name]['ct']],
                'elo_map_ct_opponent': [rank.teams[team1].map_elo[map_name]['ct']],
                'elo_map_t': [rank.teams[team2].map_elo[map_name]['t']],
                'elo_map_t_opponent': [rank.teams[team1].map_elo[map_name]['t']]
            })
        ], ignore_index=True, axis=0)

        rank.update_elo(game)

        # if team_name == 'Lyngby Vikings' or op_name == 'Lyngby Vikings':
        #     print(elo_op_pre, op_name)
        #     print(elo_team_pre, teams[team_name].elo)
        #     print(elo_map_team_pre, teams[team_name].map_elo[map_name], '\n')

    # colunas = list(rank.teams['Natus Vincere'].map_elo.keys()) + ['elo', 'team']

    x = pd.DataFrame()

    for k, v in rank.teams.items():
        row = dict()
        raw_row = v.map_elo
        for map_name in raw_row.keys():
            for n in ['ct', 't', 'main']:
                row.update({
                   map_name + f'_{n}': raw_row[map_name][n]
                })

        row.update({'team': k})
        row.update({'elo': v.elo})
        x = x.append(
            row, ignore_index=True
        )

    print(x.sort_values('elo', ascending=False).head(20))

    x.sort_values('elo', ascending=False).to_excel('elos.xlsx', sheet_name='Planilha1', index=False)

    original_df = original_df.merge(
        elos_df[['MATCH_ID', 'GAME_NUM', 'TEAM_NAME', 'elo', 'elo_opponent', 'elo_map', 'elo_map_opponent',
                 'elo_map_ct', 'elo_map_t', 'elo_map_ct_opponent', 'elo_map_t_opponent']],
        right_on=['MATCH_ID', 'GAME_NUM', 'TEAM_NAME'],
        left_on=['MATCH_ID', 'GAME_NUM', 'TEAM_NAME'],
        how='left'
    )

    return original_df, rank.teams


if __name__ == '__main__':
    from dataset_info import Dataset
    data = Dataset().full_dataset
    # data = run_data_in_elo_system(data)
