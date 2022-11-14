from config import con
from sklearn.preprocessing import LabelEncoder
import pandas as pd


target = 'MAP'


# target = [
#     'MAP_Ancient', 'MAP_Dust2', 'MAP_Inferno', 'MAP_Mirage', 'MAP_Nuke', 'MAP_Overpass', 'MAP_Vertigo'
# ]

columns_treino = [
    'PICK_ORDER', 'MAX_GAMES',
    'pick_rate_mirage', 'pick_rate_ancient', 'pick_rate_vertigo',
    'pick_rate_nuke', 'pick_rate_inferno', 'pick_rate_overpass',
    'pick_rate_dust2',
    'ban_rate_mirage', 'ban_rate_ancient', 'ban_rate_vertigo',
    'ban_rate_nuke', 'ban_rate_inferno', 'ban_rate_overpass',
    'ban_rate_dust2',
    'pick_rate_mirage_opponent',
    'pick_rate_ancient_opponent',
    'pick_rate_vertigo_opponent',
    'pick_rate_nuke_opponent',
    'pick_rate_inferno_opponent',
    'pick_rate_overpass_opponent',
    'pick_rate_dust2_opponent',
    'ban_rate_mirage_opponent',
    'ban_rate_ancient_opponent',
    'ban_rate_vertigo_opponent',
    'ban_rate_nuke_opponent',
    'ban_rate_inferno_opponent',
    'ban_rate_overpass_opponent',
    'ban_rate_dust2_opponent',
    'first_pick_rate_mirage', 'first_pick_rate_ancient', 'first_pick_rate_vertigo',
    'first_pick_rate_nuke', 'first_pick_rate_inferno', 'first_pick_rate_overpass',
    'first_pick_rate_dust2',
    'first_ban_rate_mirage', 'first_ban_rate_ancient', 'first_ban_rate_vertigo',
    'first_ban_rate_nuke', 'first_ban_rate_inferno', 'first_ban_rate_overpass',
    'first_ban_rate_dust2',
    'first_pick_rate_mirage_opponent',
    'first_pick_rate_ancient_opponent',
    'first_pick_rate_vertigo_opponent',
    'first_pick_rate_nuke_opponent',
    'first_pick_rate_inferno_opponent',
    'first_pick_rate_overpass_opponent',
    'first_pick_rate_dust2_opponent',
    'first_ban_rate_mirage_opponent',
    'first_ban_rate_ancient_opponent',
    'first_ban_rate_vertigo_opponent',
    'first_ban_rate_nuke_opponent',
    'first_ban_rate_inferno_opponent',
    'first_ban_rate_overpass_opponent',
    'first_ban_rate_dust2_opponent',
    'win_rate', 'win_rate_ancient', 'win_rate_mirage', 'win_rate_vertigo', 'win_rate_nuke', 'win_rate_inferno',
    'win_rate_overpass', 'win_rate_dust2', 'MATCH_ID', 'jogos', 'jogos_opponent', 'win_rate_opponent',
    'win_rate_ancient_opponent', 'win_rate_vertigo_opponent', 'win_rate_nuke_opponent', 'win_rate_mirage_opponent',
    'win_rate_inferno_opponent', 'win_rate_overpass_opponent', 'win_rate_dust2_opponent'
]


def read_data():
    query = open('queries/SELECT_PICKS.sql', 'r').read()
    data = pd.read_sql(query, con)

    print(len(data))
    data = data[
        (data['jogos'] > 5)
      & (data['jogos_opponent'] > 5)
    ]

    data = data[
        (data['MAX_GAMES'] == 3)
        ]

    print(len(data))

    # data = pd.get_dummies(data, drop_first=False, columns=['MAP'])

    values = {
        'win_rate_ancient': 0.3,
        'win_rate_mirage': 0.3,
        'win_rate_vertigo': 0.3,
        'win_rate_nuke': 0.3,
        'win_rate_inferno': 0.3,
        'win_rate_overpass': 0.3,
        'win_rate_dust2': 0.3,
        'win_rate_ancient_opponent': 0.3,
        'win_rate_vertigo_opponent': 0.3,
        'win_rate_nuke_opponent': 0.3,
        'win_rate_mirage_opponent': 0.3,
        'win_rate_inferno_opponent': 0.3,
        'win_rate_overpass_opponent': 0.3,
        'win_rate_dust2_opponent': 0.3
    }
    data.fillna(value=values, inplace=True)

    data.fillna(0, inplace=True)
    return data


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
        self.full_dataset = read_data()

        self.X_train, self.y_train, self.X_test, self.y_test = split_train_test(
            self.full_dataset,
            data_limite=1660561200000,
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
    def __init__(self, team1, team2, date_unix):
        self.pick_team1 = {
            'MATCH_ID': 99999,
            'PICK_ORDER': 3,
            'TYPE': 'picked',
            'AUTHOR': team1,
            'MAP': '?',
            'MAX_GAMES': 3,
            'DATE_UNIX': date_unix,
            'first_pick': 1,
            'opponent': team2
        }

        self.pick_team2 = {
            'MATCH_ID': 99999,
            'PICK_ORDER': 4,
            'TYPE': 'picked',
            'AUTHOR': team2,
            'MAP': '?',
            'MAX_GAMES': 3,
            'DATE_UNIX': date_unix,
            'first_pick': 1,
            'opponent': team1
        }

        query = open('queries/SELECT_PICKS.sql', 'r').read()
        part_to_change = open('queries/PART_TO_REPLACE.sql', 'r').read()

        query = query.replace(part_to_change, '')
        self.X_test = pd.read_sql(query, con)
