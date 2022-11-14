from config import con, MapPool
from sklearn.preprocessing import LabelEncoder, StandardScaler
import pandas as pd
from elo_system import run_data_in_elo_system
from datetime import datetime


target = 'win'


# target = [
#     'MAP_Ancient', 'MAP_Dust2', 'MAP_Inferno', 'MAP_Mirage', 'MAP_Nuke', 'MAP_Overpass', 'MAP_Vertigo'
# ]

columns_treino = [
    'MATCH_ID',
    'RANK', 'RANK_OPPONENT',
    # 'FAVORITO',
    # 'win_rate_map', 'win_rate_same_rank', 'round_win_rate_map',
    # 't_round_win_rate_map', 'ct_round_win_rate_map', 'jogos_map',
    # 'rounds_map', 'DECIDER', 'win_rate_top10', 'win_rate_top10_opponent', 'win_rate_top100_opponent',
    # 'win_rate_top20', 'win_rate_top20_opponent', 'win_rate_top50', 'win_rate_top50_opponent', 'win_rate_top100',
    # 'win_rate_map_opponent', 'win_rate_same_rank_opponent', 'round_win_rate_map_opponent',
    # 't_round_win_rate_map_opponent', 'ct_round_win_rate_map_opponent', 'jogos_map_opponent',
    # 'rounds_map_opponent', 'dias_sem_jogar', 'dias_sem_jogar_opponent',
    # 'avg_rating', 'avg_adr', 'avg_kast', 'avg_rating_opponent', 'avg_adr_opponent', 'avg_kast_opponent',
    'avg_rating_map',
    # 'avg_adr_map', 'avg_kast_map',
    'avg_rating_map_opponent',
    # 'avg_adr_map_opponent',
    # 'avg_kast_map_opponent',
    'elo', 'elo_opponent', 'elo_map', 'elo_map_opponent',
    'elo_map_ct', 'elo_map_t', 'elo_map_ct_opponent', 'elo_map_t_opponent'
    # 'top_20_rate_event',
    # 'round_win_rate_map_top30', 'round_win_rate_map_top30_opponent', 'exp_points', 'exp_points_map',
    # 'voltando_agora', 'voltando_agora_opponent',
]

columns_treino2 = columns_treino + ['MAP_NAME', 'TEAM_NAME', 'OPPONENT']


def read_data(filtrar_jogos=False):
    query = open('queries/SELECT_MAIN.sql', 'r').read()
    data = pd.read_sql(query, con)

    # data = pd.get_dummies(data, drop_first=False, columns=['MAP_NAME'])

    if filtrar_jogos:
        data = data[
            (data['jogos'] > 2)
          & (data['jogos_opponent'] > 2)
        ]

    data['voltando_agora'] = data['jogos'] <= 3
    data['voltando_agora_opponent'] = data['jogos_opponent'] <= 3

    data.fillna(0, inplace=True)
    data, team_elos = run_data_in_elo_system(data)

    data['exp_points'] = 1 / (1 + 10 ** ((data['elo_opponent'] - data['elo']) / 400))

    data['exp_points_map'] = 1 / (1 + 10 ** ((data['elo_map_opponent'] - data['elo_map']) / 400))

    # data[[
    #     'MATCH_ID', 'DATE_UNIX', 'GAME_NUM', 'MAP_NAME', 'elo', 'elo_opponent', 'elo_map', 'elo_map_opponent',
    #     'TEAM_NAME', 'OPPONENT'
    # ]].to_excel('elos.xlsx', sheet_name='Planilha1', index=False)

    return data, team_elos


def split_train_test(data, data_limite, columns_treino, target):
    X_train = data[data['DATE_UNIX'] <= data_limite].copy()

    X_test = data[data['DATE_UNIX'] > data_limite].copy()

    y_train = data[data['DATE_UNIX'] <= data_limite].copy()

    y_test = data[data['DATE_UNIX'] > data_limite].copy()

    X_train = X_train[columns_treino]
    X_test = X_test[columns_treino]

    y_train = y_train[target]
    y_test = y_test[target]

    return X_train, y_train, X_test, y_test


class Dataset:
    def __init__(self):
        self.full_dataset, self.current_elos = read_data()

        self.X_train, self.y_train, self.X_test, self.y_test = split_train_test(
            self.full_dataset,
            data_limite=1662789900000,
            columns_treino=columns_treino,
            target=target
        )

        le = LabelEncoder()
        le.fit(self.y_train)

        self.string_y_train = self.y_train
        self.y_train = le.transform(self.y_train)

        self.string_y_test = self.y_test
        self.y_test = le.transform(self.y_test)

        self.classes = le.classes_


class MatchToPredict:
    def __init__(self, team1, team2, event_name, data, team1rank, team2rank, dataset_full):
        self.games = list()

        for map in MapPool(data).available_maps:
            self.games.append({
                'MATCH_ID': -1,
                'HLTV_LINK': '',
                'GAME_NUM': 0,
                'DATE_UNIX': 1000*datetime.timestamp(datetime.strptime(datetime.strftime(data, '%Y-%m-%d'), '%Y-%m-%d')),
                'EVENT_NAME': event_name,
                'MAP_NAME': map,
                'TEAM_NAME': team1,
                'OPPONENT': team2,
                'win': -1,
                'RANK': team1rank,
                'RANK_OPPONENT': team2rank,
                'DECIDER': -1
            })

        self.dataset = pd.DataFrame()
        query_template = open('queries/GAME_FAKE.sql', 'r').read()
        for game in self.games:
            query = query_template
            for k, v in game.items():
                query = query.replace(f'{{{{{k}}}}}', str(v))

            row = pd.read_sql(query, con)
            self.dataset = pd.concat([self.dataset, row], ignore_index=True, axis=0)

        elos = dataset_full.current_elos

        for i in self.dataset.index.values.tolist():
            time = self.dataset.loc[i, 'TEAM_NAME']
            op = self.dataset.loc[i, 'OPPONENT']
            mapa = self.dataset.loc[i, 'MAP_NAME']

            self.dataset.loc[i, 'elo'] = elos[time].elo
            self.dataset.loc[i, 'elo_opponent'] = elos[op].elo
            self.dataset.loc[i, 'elo_map'] = elos[time].map_elo[mapa]['main']
            self.dataset.loc[i, 'elo_map_opponent'] = elos[op].map_elo[mapa]['main']
            self.dataset.loc[i, 'elo_map_ct'] = elos[time].map_elo[mapa]['ct']
            self.dataset.loc[i, 'elo_map_ct_opponent'] = elos[op].map_elo[mapa]['ct']
            self.dataset.loc[i, 'elo_map_t'] = elos[time].map_elo[mapa]['t']
            self.dataset.loc[i, 'elo_map_t_opponent'] = elos[op].map_elo[mapa]['t']

        self.dataset.fillna(0, inplace=True)

        x_train, y_train, self.X_test, y_test = split_train_test(
            self.dataset,
            data_limite=0,
            columns_treino=columns_treino2,
            target=target
        )


if __name__ == '__main__':
    print(MatchToPredict(
        team1='Furia',
        team2='Imperial',
        event_name='IEM Rio Major 2022',
        data='2022-10-11',
        team1rank=7,
        team2rank=25,
        dataset_full=Dataset()
    ).X_test)
